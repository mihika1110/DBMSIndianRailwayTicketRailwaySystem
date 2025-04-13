CREATE TABLE IF NOT EXISTS Cancellation_Records (
    Cancellation_id INT PRIMARY KEY AUTO_INCREMENT,
    PNR_no VARCHAR(15),
    Passenger_id VARCHAR(15),
    Cancellation_time DATETIME,
    Original_fare DECIMAL(10,2),
    Refund_amount DECIMAL(10,2),
    Refund_percentage DECIMAL(5,2),
    FOREIGN KEY (PNR_no) REFERENCES Ticket_Reservation(PNR_no),
    FOREIGN KEY (Passenger_id) REFERENCES PAX_info(Passenger_id)
);

DELIMITER //

CREATE PROCEDURE ProcessCancellation(
    IN p_pnr_no VARCHAR(15),
    IN p_passenger_id VARCHAR(15),
    IN p_cancellation_time DATETIME,
    OUT p_refund_amount DECIMAL(10,2),
    OUT p_status_message VARCHAR(100)
)
BEGIN
    DECLARE v_booking_status VARCHAR(20);
    DECLARE v_train_code VARCHAR(10);
    DECLARE v_class_code VARCHAR(15);
    DECLARE v_seat_no VARCHAR(10);
    DECLARE v_fare DECIMAL(10,2);
    DECLARE v_departure_time DATETIME;
    DECLARE v_refund_percentage DECIMAL(5,2);
    DECLARE v_min_refund_time DATETIME;
    
    -- Get booking details
    SELECT 
        p.Booking_status,
        tr.Train_code,
        p.Class_code,
        p.Seat_no,
        p.Fare,
        CONCAT(tr.From_date, ' ', t.Start_time) AS Departure_time
    INTO 
        v_booking_status,
        v_train_code,
        v_class_code,
        v_seat_no,
        v_fare,
        v_departure_time
    FROM PAX_info p
    JOIN Ticket_Reservation tr ON p.PNR_no = tr.PNR_no
    JOIN Train t ON tr.Train_code = t.Train_code
    WHERE p.Passenger_id = p_passenger_id
    AND p.PNR_no = p_pnr_no;
    
    -- Check if booking exists
    IF v_booking_status IS NULL THEN
        SET p_status_message = 'Invalid PNR or Passenger ID';
        SET p_refund_amount = 0;
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Invalid PNR or Passenger ID';
    END IF;
    
    -- Check if already cancelled
    IF v_booking_status = 'Cancelled' THEN
        SET p_status_message = 'Ticket already cancelled';
        SET p_refund_amount = 0;
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Ticket already cancelled';
    END IF;
    
    -- Determine refund percentage based on cancellation time
    SELECT 
        Refundable_amt / v_fare,
        CONCAT(tr.From_date, ' ', rr.To_time)
    INTO 
        v_refund_percentage,
        v_min_refund_time
    FROM Refund_rule rr
    JOIN Ticket_Reservation tr ON rr.PNR_no = tr.PNR_no
    WHERE rr.PNR_no = p_pnr_no
    AND p_cancellation_time >= CONCAT(tr.From_date, ' ', rr.From_time)
    AND p_cancellation_time <= CONCAT(tr.From_date, ' ', rr.To_time)
    ORDER BY rr.To_time DESC
    LIMIT 1;
    
    -- If no matching refund rule found (cancelled too late)
    IF v_refund_percentage IS NULL THEN
        SET v_refund_percentage = 0;
        SET v_min_refund_time = NULL;
    END IF;
    
    -- Calculate refund amount
    SET p_refund_amount = ROUND(v_fare * v_refund_percentage, 2);
    
    -- Mark ticket as cancelled
    UPDATE PAX_info
    SET 
        Booking_status = 'Cancelled',
        Seat_no = NULL
    WHERE Passenger_id = p_passenger_id
    AND PNR_no = p_pnr_no;
    
    -- Free up the seat if it was confirmed
    IF v_booking_status = 'Confirmed' AND v_seat_no IS NOT NULL THEN
        -- Extract seat number (remove class prefix)
        SET @seat_num = SUBSTRING(v_seat_no, 2);
        
        UPDATE Seat_availability
        SET Seat_Status = 'Available'
        WHERE Train_code = v_train_code
        AND Class_code = v_class_code
        AND Seat_No = @seat_num;
    END IF;
    
    -- Record the cancellation and refund
    INSERT INTO Cancellation_Records (
        PNR_no,
        Passenger_id,
        Cancellation_time,
        Original_fare,
        Refund_amount,
        Refund_percentage
    ) VALUES (
        p_pnr_no,
        p_passenger_id,
        p_cancellation_time,
        v_fare,
        p_refund_amount,
        v_refund_percentage
    );
    
    -- Process upgrades if this was a confirmed cancellation
    IF v_booking_status = 'Confirmed' THEN
        CALL ProcessUpgrades(v_train_code, v_class_code);
    END IF;
    
    -- Set status message
    IF v_refund_percentage > 0 THEN
        SET p_status_message = CONCAT('Cancellation successful. Refund amount: ', p_refund_amount, 
                                    ' (', ROUND(v_refund_percentage*100, 0), '% of fare)');
    ELSE
        SET p_status_message = 'Cancellation successful. No refund applicable as per cancellation policy.';
    END IF;
    
    -- Return cancellation details
    SELECT 
        p_pnr_no AS PNR_Number,
        p_passenger_id AS Passenger_ID,
        v_booking_status AS Original_Status,
        'Cancelled' AS New_Status,
        v_fare AS Original_Fare,
        p_refund_amount AS Refund_Amount,
        ROUND(v_refund_percentage*100, 0) AS Refund_Percentage,
        p_status_message AS Status_Message;
END //

DELIMITER ;


DELIMITER //

CREATE PROCEDURE ProcessUpgrades()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_train_code VARCHAR(10);
    DECLARE v_class_code VARCHAR(15);
    DECLARE v_available_seats INT;
    DECLARE v_rac_count INT;
    DECLARE v_seat_no INT;
    DECLARE v_pnr_to_upgrade VARCHAR(15);
    DECLARE v_passenger_id VARCHAR(15);
    DECLARE v_seat_prefix CHAR(1);
    
    -- Cursor to find all train/class combinations with cancellations
    DECLARE cur_trains CURSOR FOR
        SELECT DISTINCT tr.Train_code, p.Class_code
        FROM PAX_info p
        JOIN Ticket_Reservation tr ON p.PNR_no = tr.PNR_no
        WHERE p.Booking_status = 'Cancelled'
        AND EXISTS (
            SELECT 1 FROM PAX_info 
            WHERE Train_code = tr.Train_code 
            AND Class_code = p.Class_code
            AND Booking_status IN ('RAC', 'Waitlist')
        );
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    OPEN cur_trains;
    
    train_loop: LOOP
        FETCH cur_trains INTO v_train_code, v_class_code;
        IF v_done THEN
            LEAVE train_loop;
        END IF;
        
        -- Check available seats for this train/class
        SELECT COUNT(*) INTO v_available_seats
        FROM Seat_availability
        WHERE Train_code = v_train_code
        AND Class_code = v_class_code
        AND Seat_Status = 'Available';
        
        -- Upgrade RAC to Confirmed if seats available
        upgrade_rac: WHILE v_available_seats > 0 DO
            -- Get the earliest RAC passenger
            SELECT p.PNR_no, p.Passenger_id INTO v_pnr_to_upgrade, v_passenger_id
            FROM PAX_info p
            JOIN Ticket_Reservation tr ON p.PNR_no = tr.PNR_no
            WHERE tr.Train_code = v_train_code
            AND p.Class_code = v_class_code
            AND p.Booking_status = 'RAC'
            ORDER BY p.SRL_no
            LIMIT 1;
            
            IF v_pnr_to_upgrade IS NULL THEN
                LEAVE upgrade_rac;
            END IF;
            
            -- Assign available seat
            SELECT Seat_No INTO v_seat_no
            FROM Seat_availability
            WHERE Train_code = v_train_code
            AND Class_code = v_class_code
            AND Seat_Status = 'Available'
            LIMIT 1;
            
            -- Get seat prefix
            SET v_seat_prefix = 
                CASE v_class_code
                    WHEN '1A' THEN 'A'
                    WHEN '2A' THEN 'B'
                    WHEN '3A' THEN 'C'
                    WHEN 'SL' THEN 'S'
                    WHEN 'CC' THEN 'D'
                    WHEN 'EC' THEN 'E'
                    WHEN '2S' THEN 'F'
                    WHEN 'FC' THEN 'G'
                    ELSE 'H'
                END;
            
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
            WHERE Train_code = v_train_code
            AND Class_code = v_class_code
            AND Seat_No = v_seat_no;
            
            -- Decrement available seats counter
            SET v_available_seats = v_available_seats - 1;
        END WHILE;
        
        -- Check current RAC count after upgrades
        SELECT COUNT(*) INTO v_rac_count
        FROM PAX_info p
        JOIN Ticket_Reservation tr ON p.PNR_no = tr.PNR_no
        WHERE tr.Train_code = v_train_code
        AND p.Class_code = v_class_code
        AND p.Booking_status = 'RAC';
        
        -- Configuration parameter
        SET @rac_limit = 10;
        
        -- Upgrade Waitlist to RAC if space available
        upgrade_waitlist: WHILE v_rac_count < @rac_limit DO
            -- Get the earliest Waitlist passenger
            SELECT p.PNR_no, p.Passenger_id INTO v_pnr_to_upgrade, v_passenger_id
            FROM PAX_info p
            JOIN Ticket_Reservation tr ON p.PNR_no = tr.PNR_no
            WHERE tr.Train_code = v_train_code
            AND p.Class_code = v_class_code
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
            WHERE tr.Train_code = v_train_code
            AND p.Class_code = v_class_code
            AND p.Booking_status = 'Waitlist'
            ORDER BY p.Waitlist_position
        ) AS sorted ON PAX_info.Passenger_id = sorted.Passenger_id
        SET PAX_info.Waitlist_position = sorted.new_position;
    END LOOP;
    
    CLOSE cur_trains;
    
    -- Clear cancelled tickets that have been processed
    UPDATE PAX_info
    SET Booking_status = 'Processed'
    WHERE Booking_status = 'Cancelled';
END //

DELIMITER ;



