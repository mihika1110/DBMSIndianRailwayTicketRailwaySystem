DELIMITER //

CREATE PROCEDURE ProcessUpgrades(
    IN p_train_code VARCHAR(10),
    IN p_class_code VARCHAR(15),
    IN p_travel_date DATE,
    OUT p_status_message VARCHAR(100)
)
BEGIN
    DECLARE v_cancelled_seat_no INT;
    DECLARE v_rac_pnr VARCHAR(15);
    DECLARE v_rac_passenger_id VARCHAR(15);
    DECLARE v_seat_prefix CHAR(1);
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_upgrades_count INT DEFAULT 0;
    DECLARE v_error_message VARCHAR(100);
    
    -- Cursor to get cancelled seats
    DECLARE cancelled_seats_cursor CURSOR FOR
        SELECT sa.Seat_No
        FROM Seat_availability sa
        WHERE sa.Train_code = p_train_code
        AND sa.Class_code = p_class_code
        AND sa.travel_date = p_travel_date
        AND sa.Seat_Status = 'Cancelled'
        ORDER BY sa.Seat_No;
    
    -- Cursor to get RAC passengers
    DECLARE rac_passengers_cursor CURSOR FOR
        SELECT p.PNR_no, p.Passenger_id
        FROM PAX_info p
        JOIN Ticket_Reservation t ON p.PNR_no = t.PNR_no
        WHERE t.Train_code = p_train_code
        AND p.Class_code = p_class_code
        AND p.Booking_status = 'RAC'
        AND t.From_date = p_travel_date
        ORDER BY p.PNR_no;
    
    -- Handler for when no more rows
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    
    -- Error handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        SET p_status_message = CONCAT('Error during upgrade process: ', v_error_message);
    END;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Validate input parameters
    IF p_train_code IS NULL OR p_class_code IS NULL OR p_travel_date IS NULL THEN
        SET p_status_message = 'Invalid input parameters';
        ROLLBACK;
        RETURN;
    END IF;
    
    -- Check if train exists
    IF NOT EXISTS (SELECT 1 FROM Train WHERE Train_code = p_train_code) THEN
        SET p_status_message = 'Invalid train code';
        ROLLBACK;
        RETURN;
    END IF;
    
    -- Check if class exists
    IF NOT EXISTS (SELECT 1 FROM Class WHERE Class_code = p_class_code) THEN
        SET p_status_message = 'Invalid class code';
        ROLLBACK;
        RETURN;
    END IF;
    
    -- Get seat prefix based on class
    SET v_seat_prefix = 
        CASE p_class_code
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
    
    -- Open cursors
    OPEN cancelled_seats_cursor;
    OPEN rac_passengers_cursor;
    
    -- Process upgrades
    upgrade_loop: LOOP
        -- Get next cancelled seat
        FETCH cancelled_seats_cursor INTO v_cancelled_seat_no;
        IF v_done THEN
            LEAVE upgrade_loop;
        END IF;
        
        -- Get next RAC passenger
        FETCH rac_passengers_cursor INTO v_rac_pnr, v_rac_passenger_id;
        IF v_done THEN
            LEAVE upgrade_loop;
        END IF;
        
        -- Update RAC passenger to confirmed
        UPDATE PAX_info
        SET 
            Booking_status = 'Confirmed',
            Seat_no = CONCAT(v_seat_prefix, v_cancelled_seat_no),
            Waitlist_position = NULL
        WHERE PNR_no = v_rac_pnr
        AND Passenger_id = v_rac_passenger_id;
        
        -- Update seat status
        UPDATE Seat_availability
        SET Seat_Status = 'Booked'
        WHERE Train_code = p_train_code
        AND Class_code = p_class_code
        AND Seat_No = v_cancelled_seat_no
        AND travel_date = p_travel_date;
        
        -- Increment upgrade count
        SET v_upgrades_count = v_upgrades_count + 1;
        
        -- Reset done flag for next iteration
        SET v_done = 0;
    END LOOP;
    
    -- Close cursors
    CLOSE cancelled_seats_cursor;
    CLOSE rac_passengers_cursor;
    
    -- Commit transaction
    COMMIT;
    
    -- Set status message
    IF v_upgrades_count > 0 THEN
        SET p_status_message = CONCAT('Successfully upgraded ', v_upgrades_count, ' RAC passengers to confirmed status');
    ELSE
        SET p_status_message = 'No upgrades processed - no matching cancelled seats or RAC passengers found';
    END IF;
    
    -- Return results
    SELECT v_upgrades_count AS Upgrades_Processed, p_status_message AS Status_Message;
END //

DELIMITER ; 