drop PROCEDURE ProcessUpgrades;
DROP PROCEDURE IF EXISTS ProcessCancellation;

DELIMITER //

CREATE PROCEDURE ProcessCancellation(
    IN p_pnr_no VARCHAR(15),
    IN p_cancellation_time DATETIME,
    OUT p_refund_amount DECIMAL(10,2)
)
BEGIN
    DECLARE v_train_code VARCHAR(10);
    DECLARE v_departure_date DATE;
    DECLARE v_rac_limit INT;
    DECLARE v_passenger_count INT;
    DECLARE v_cancelled_count INT DEFAULT 0;
    DECLARE v_original_fare DECIMAL(10,2);
    DECLARE v_status_message VARCHAR(100);
    DECLARE done INT DEFAULT FALSE;
    DECLARE class_code VARCHAR(15);
    
    -- Cursor for handling multiple classes
    DECLARE cur CURSOR FOR 
        SELECT DISTINCT Class_code FROM PAX_info WHERE PNR_no = p_pnr_no;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Get basic booking details
    SELECT 
        tr.Train_code,
        tr.From_date,
        c.RAC_limit,
        COUNT(p.Passenger_id),
        SUM(p.Fare),
        t.Start_time
    INTO 
        v_train_code,
        v_departure_date,
        v_rac_limit,
        v_passenger_count,
        v_original_fare,
        @start_time
    FROM Ticket_Reservation tr
    JOIN Train t ON tr.Train_code = t.Train_code
    JOIN PAX_info p ON tr.PNR_no = p.PNR_no
    JOIN Class c ON p.Class_code = c.Class_code
    WHERE tr.PNR_no = p_pnr_no
    GROUP BY tr.Train_code, tr.From_date, c.RAC_limit, t.Start_time;
    
    -- Check if PNR exists
    IF v_train_code IS NULL THEN
        SET v_status_message = 'Invalid PNR';
        SET p_refund_amount = 0;
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Invalid PNR';
    END IF;
    
    -- Get refund amount based on cancellation time relative to journey
    SET p_refund_amount = CASE
        WHEN TIMESTAMPDIFF(HOUR, p_cancellation_time, CONCAT(v_departure_date, ' ', @start_time)) >= 48 THEN v_original_fare * 0.80
        WHEN TIMESTAMPDIFF(HOUR, p_cancellation_time, CONCAT(v_departure_date, ' ', @start_time)) >= 24 THEN v_original_fare * 0.50
        WHEN TIMESTAMPDIFF(HOUR, p_cancellation_time, CONCAT(v_departure_date, ' ', @start_time)) >= 12 THEN v_original_fare * 0.25
        ELSE 0
    END;
    
    -- Mark all tickets as cancelled and free seats
    UPDATE PAX_info p
    SET 
        p.Booking_status = 'Cancelled',
        p.Seat_no = NULL,
        p.Waitlist_position = NULL
    WHERE p.PNR_no = p_pnr_no
    AND p.Booking_status != 'Cancelled';
    
    -- Get count of cancelled tickets
    SELECT ROW_COUNT() INTO v_cancelled_count;
    
    -- Free up confirmed seats
    UPDATE Seat_availability sa
    JOIN PAX_info p ON sa.Seat_No = SUBSTRING(p.Seat_no, 2)
    SET sa.Seat_Status = 'Available'
    WHERE sa.Train_code = v_train_code
    AND sa.Class_code IN (SELECT Class_code FROM PAX_info WHERE PNR_no = p_pnr_no)
    AND p.PNR_no = p_pnr_no
    AND p.Booking_status = 'Cancelled'
    AND p.Seat_no IS NOT NULL
    AND sa.travel_date = v_departure_date;
    
    -- Record cancellation (one record per PNR)
    INSERT INTO Cancellation_Records (
        PNR_no,
        Cancellation_time,
        Original_fare,
        Refund_amount
    ) VALUES (
        p_pnr_no,
        p_cancellation_time,
        v_original_fare,
        p_refund_amount
    );
    
    -- Process upgrades if any confirmed seats were cancelled
    IF EXISTS (
        SELECT 1 FROM PAX_info 
        WHERE PNR_no = p_pnr_no 
        AND Booking_status = 'Cancelled'
        AND Seat_no IS NOT NULL
    ) THEN
        -- Call upgrade for each affected class
        OPEN cur;
        read_loop: LOOP
            FETCH cur INTO class_code;
            IF done THEN
                LEAVE read_loop;
            END IF;
            CALL ProcessUpgrades(v_train_code, class_code, v_rac_limit);
        END LOOP;
        CLOSE cur;
    END IF;
    
    -- Return cancellation summary
    SELECT 
        p_pnr_no AS PNR_Number,
        v_cancelled_count AS Tickets_Cancelled,
        v_original_fare AS Original_Fare,
        p_refund_amount AS Refund_Amount,
        CONCAT(v_cancelled_count, ' ticket(s) cancelled. Refund amount: ', p_refund_amount) AS Status_Message;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE ProcessUpgrades(
    IN p_train_code VARCHAR(10),
    IN p_class_code VARCHAR(15),
    IN p_rac_limit INT
)
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_available_seats INT;
    DECLARE v_rac_count INT;
    DECLARE v_seat_no INT;
    DECLARE v_pnr_to_upgrade VARCHAR(15);
    DECLARE v_passenger_id VARCHAR(15);
    DECLARE v_seat_prefix CHAR(1);
    DECLARE v_waitlist_count INT;
    
    -- Check available seats for this train/class
    SELECT COUNT(*) INTO v_available_seats
    FROM Seat_availability
    WHERE Train_code = p_train_code
    AND Class_code = p_class_code
    AND Seat_Status = 'Available';
    
    -- Upgrade RAC to Confirmed if seats available
    upgrade_rac: WHILE v_available_seats > 0 DO
        -- Get the earliest RAC passenger
        SELECT p.PNR_no, p.Passenger_id INTO v_pnr_to_upgrade, v_passenger_id
        FROM PAX_info p
        JOIN Ticket_Reservation tr ON p.PNR_no = tr.PNR_no
        WHERE tr.Train_code = p_train_code
        AND p.Class_code = p_class_code
        AND p.Booking_status = 'RAC'
        ORDER BY p.SRL_no
        LIMIT 1;
        
        IF v_pnr_to_upgrade IS NULL THEN
            LEAVE upgrade_rac;
        END IF;
        
        -- Assign available seat
        SELECT Seat_No INTO v_seat_no
        FROM Seat_availability
        WHERE Train_code = p_train_code
        AND Class_code = p_class_code
        AND Seat_Status = 'Available'
        AND Seat_No NOT LIKE '%-%'
        LIMIT 1;
        
        -- Get seat prefix based on class
        SELECT 
            CASE Class_code
                WHEN '1A' THEN 'A'
                WHEN '2A' THEN 'B'
                WHEN '3A' THEN 'C'
                WHEN 'SL' THEN 'S'
                WHEN 'CC' THEN 'D'
                WHEN 'EC' THEN 'E'
                WHEN '2S' THEN 'F'
                WHEN 'FC' THEN 'G'
                ELSE 'H'
            END INTO v_seat_prefix
        FROM Class
        WHERE Class_code = p_class_code;
        
        -- Update passenger record
        UPDATE PAX_info
        SET 
            Booking_status = 'Confirmed',
            Seat_no = CONCAT(v_seat_prefix, v_seat_no),
            Waitlist_position = NULL
        WHERE Passenger_id = v_passenger_id
        AND PNR_no = v_pnr_to_upgrade;
        
        -- Mark seat as booked
        UPDATE Seat_availability
        SET Seat_Status = 'Booked'
        WHERE Train_code = p_train_code
        AND Class_code = p_class_code
        AND Seat_No = v_seat_no;
        
        -- Decrement available seats counter
        SET v_available_seats = v_available_seats - 1;
    END WHILE;
    
    -- Check current RAC count after upgrades
    SELECT COUNT(*) INTO v_rac_count
    FROM PAX_info p
    JOIN Ticket_Reservation tr ON p.PNR_no = tr.PNR_no
    WHERE tr.Train_code = p_train_code
    AND p.Class_code = p_class_code
    AND p.Booking_status = 'RAC';
    
    -- Upgrade Waitlist to RAC if space available
    upgrade_waitlist: WHILE v_rac_count < p_rac_limit DO
        -- Get the earliest Waitlist passenger
        SELECT p.PNR_no, p.Passenger_id INTO v_pnr_to_upgrade, v_passenger_id
        FROM PAX_info p
        JOIN Ticket_Reservation tr ON p.PNR_no = tr.PNR_no
        WHERE tr.Train_code = p_train_code
        AND p.Class_code = p_class_code
        AND p.Booking_status = 'Waitlist'
        ORDER BY p.Waitlist_position
        LIMIT 1;
        
        IF v_pnr_to_upgrade IS NULL THEN
            LEAVE upgrade_waitlist;
        END IF;
        
        -- Update passenger record to RAC
        UPDATE PAX_info
        SET 
            Booking_status = 'RAC',
            Waitlist_position = NULL
        WHERE Passenger_id = v_passenger_id
        AND PNR_no = v_pnr_to_upgrade;
        
        -- Increment RAC count
        SET v_rac_count = v_rac_count + 1;
    END WHILE;
    
    -- Re-number remaining waitlist positions
    SET @row_number = 0;
    UPDATE PAX_info
    JOIN (
        SELECT p.Passenger_id, @row_number := @row_number + 1 AS new_position
        FROM PAX_info p
        JOIN Ticket_Reservation tr ON p.PNR_no = tr.PNR_no
        WHERE tr.Train_code = p_train_code
        AND p.Class_code = p_class_code
        AND p.Booking_status = 'Waitlist'
        ORDER BY p.Waitlist_position
    ) AS sorted ON PAX_info.Passenger_id = sorted.Passenger_id
    SET PAX_info.Waitlist_position = sorted.new_position
    WHERE PAX_info.Booking_status = 'Waitlist';
END //

DELIMITER ;