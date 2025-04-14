DELIMITER //

CREATE PROCEDURE BookTicket(
    IN p_train_code VARCHAR(10),
    IN p_from_station VARCHAR(50),
    IN p_to_station VARCHAR(50),
    IN p_from_date DATE,
    IN p_passenger_name VARCHAR(100),
    IN p_passenger_age INT,
    IN p_passenger_gender ENUM('M', 'F', 'Other'),
    IN p_passenger_category VARCHAR(20),
    IN p_class_code VARCHAR(15),
    IN p_payment_mode ENUM('Credit Card', 'Debit Card', 'UPI', 'Net Banking', 'Cash'),
    IN p_inst_type ENUM('Online', 'Counter'),
    OUT p_status_message VARCHAR(100),
    OUT p_booking_status ENUM('Confirmed', 'RAC', 'Waitlist', 'Cancelled'),
    OUT p_waitlist_position INT
)
BEGIN
    DECLARE v_pnr_no VARCHAR(15);
    DECLARE v_from_km INT;
    DECLARE v_to_km INT;
    DECLARE v_total_fare DECIMAL(10,2) DEFAULT 0;
    DECLARE v_seat_no INT;
    DECLARE v_passenger_id VARCHAR(15);
    DECLARE v_fare DECIMAL(10,2);
    DECLARE v_payment_id INT;
    DECLARE v_srl_no INT;
    DECLARE v_seat_prefix CHAR(1);
    DECLARE v_available_seats INT;
    DECLARE v_rac_seats INT;
    DECLARE v_current_waitlist INT;
    DECLARE v_booking_status ENUM('Confirmed', 'RAC', 'Waitlist','Cancelled') DEFAULT 'Confirmed';
    DECLARE v_waitlist_position INT DEFAULT 0;
    DECLARE v_km_rate DECIMAL(10,2);
    DECLARE v_distance INT;
    
    -- Configuration parameters
    DECLARE v_rac_limit INT DEFAULT 10; -- Number of RAC seats per train/class
    DECLARE v_waitlist_limit INT DEFAULT 100; -- Maximum waitlist positions
    
    -- Validate from and to stations
    IF p_from_station = p_to_station THEN
        SET p_status_message = 'From and To stations cannot be the same';
        SET p_booking_status = 'Cancelled';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'From and To stations cannot be identical';
    END IF;
    
    -- Generate PNR number (format: PNR + random 8 digits)
    SET v_pnr_no = CONCAT('PNR', LPAD(FLOOR(RAND() * 100000000), 8, '0'));
    
    -- Get distance information
    SELECT vd1.Km_from_origin, vd2.Km_from_origin 
    INTO v_from_km, v_to_km
    FROM Via_details vd1
    JOIN Via_details vd2 ON vd1.Train_code = vd2.Train_code
    WHERE vd1.Train_code = p_train_code
    AND vd1.Via_station_code = p_from_station
    AND vd2.Via_station_code = p_to_station
    AND vd2.Km_from_origin > vd1.Km_from_origin
    LIMIT 1;
    
    -- Calculate distance
    SET v_distance = v_to_km - v_from_km;
    
    -- IMPROVED FARE CALCULATION
    -- Try exact match first
    SELECT Fare INTO v_fare
    FROM Train_fare
    WHERE Train_code = p_train_code
    AND Class_id = (SELECT Class_id FROM Class WHERE Class_code = p_class_code)
    AND From_Km <= v_from_km
    AND To_Km >= v_to_km
    ORDER BY (To_Km - From_Km) ASC  -- Prefer more specific ranges
    LIMIT 1;
    
    -- If no exact match, find closest fare
    IF v_fare IS NULL THEN
        SELECT Fare INTO v_fare
        FROM Train_fare
        WHERE Train_code = p_train_code
        AND Class_id = (SELECT Class_id FROM Class WHERE Class_code = p_class_code)
        ORDER BY ABS(From_Km - v_from_km) + ABS(To_Km - v_to_km) ASC
        LIMIT 1;
    END IF;
    
    -- If still no fare, calculate from km rate
    IF v_fare IS NULL THEN
        SELECT Km_rate INTO v_km_rate
        FROM Class 
        WHERE Class_code = p_class_code;
        
        IF v_km_rate IS NOT NULL AND v_distance > 0 THEN
            SET v_fare = v_distance * v_km_rate;
            SET p_status_message = CONCAT(IFNULL(p_status_message, ''), 
                                       ' Used calculated fare based on distance.');
        END IF;
    END IF;
    
    -- Final fallback if no fare could be determined
    IF v_fare IS NULL THEN
        SET v_fare = 1000.00; -- Default fare
        SET p_status_message = CONCAT(IFNULL(p_status_message, ''), 
                                   ' No fare found. Used default fare.');
    END IF;
    
    -- Validate fare
    IF v_fare <= 0 THEN
        SET v_fare = 1000.00;
        SET p_status_message = CONCAT(IFNULL(p_status_message, ''), 
                                   ' Invalid fare. Used default.');
    END IF;
    
    -- Apply concessions
    SET v_fare = v_fare * 
        CASE p_passenger_category
            WHEN 'student' THEN 0.75
            WHEN 'senior' THEN 0.60
            WHEN 'disabled' THEN 0.50
            WHEN 'child' THEN 0.50
            ELSE 1.00
        END;
    
    -- Create ticket reservation
    INSERT INTO Ticket_Reservation (
        PNR_no, Train_code, From_station, To_station, 
        From_Km, To_Km, From_date, To_date
    ) VALUES (
        v_pnr_no, p_train_code, p_from_station, p_to_station,
        v_from_km, v_to_km, p_from_date, p_from_date
    );
    
    -- Check available seats
    SELECT COUNT(*) INTO v_available_seats
    FROM Seat_availability
    WHERE Train_code = p_train_code
    AND Class_code = p_class_code
    AND Seat_Status = 'Available';
    
    -- Check current RAC count
    SELECT COUNT(*) INTO v_rac_seats
    FROM PAX_info p
    JOIN Ticket_Reservation t ON p.PNR_no = t.PNR_no
    WHERE t.Train_code = p_train_code
    AND p.Class_code = p_class_code
    AND p.Booking_status = 'RAC';

    -- Check current waitlist count
    SELECT COUNT(*) INTO v_current_waitlist
    FROM PAX_info p
    JOIN Ticket_Reservation t ON p.PNR_no = t.PNR_no
    WHERE t.Train_code = p_train_code
    AND p.Class_code = p_class_code
    AND p.Booking_status = 'Waitlist';
    
    -- Determine booking status
    IF v_available_seats > 0 THEN
        -- Assign available seat
        SELECT Seat_No INTO v_seat_no
        FROM Seat_availability
        WHERE Train_code = p_train_code
        AND Class_code = p_class_code
        AND Seat_Status = 'Available'
        LIMIT 1;
        
        SET v_booking_status = 'Confirmed';
    ELSEIF v_rac_seats < v_rac_limit THEN
        -- Assign RAC status
        SET v_seat_no = NULL;
        SET v_booking_status = 'RAC';
    ELSEIF v_current_waitlist < v_waitlist_limit THEN
        -- Assign waitlist status
        SET v_seat_no = NULL;
        SET v_booking_status = 'Waitlist';
        SET v_waitlist_position = v_current_waitlist + 1;
    ELSE
        -- No more bookings accepted
        SET p_status_message = 'No seats available. Waitlist is full.';
        SET p_booking_status = 'Waitlist';
        SET p_waitlist_position = 0;
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'No seats available. Waitlist is full.';
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
    
    -- Generate passenger ID
    SET v_passenger_id = CONCAT(v_pnr_no, '_P01');
    
    -- Add passenger with booking status
    INSERT INTO PAX_info (
        PNR_no, PAX_Name, PAX_age, Category, PAX_sex, 
        Class_code, Seat_no, Fare, Passenger_id,
        Booking_status, Waitlist_position
    ) VALUES (
        v_pnr_no,
        p_passenger_name,
        p_passenger_age,
        p_passenger_category,
        p_passenger_gender,
        p_class_code,
        CASE WHEN v_seat_no IS NOT NULL THEN CONCAT(v_seat_prefix, v_seat_no) ELSE NULL END,
        v_fare,
        v_passenger_id,
        v_booking_status,
        CASE WHEN v_booking_status = 'Waitlist' THEN v_waitlist_position ELSE NULL END
    );
    
    -- Get the serial number of the passenger
    SET v_srl_no = LAST_INSERT_ID();
    
    -- Update seat status if confirmed
    IF v_booking_status = 'Confirmed' THEN
        UPDATE Seat_availability
        SET Seat_Status = 'Booked'
        WHERE Train_code = p_train_code
        AND Class_code = p_class_code
        AND Seat_No = v_seat_no;
    END IF;
    
    -- Process payment
    INSERT INTO Pay_info (
        PNR_no, SRL_no, Pay_date, Pay_mode, 
        Amount, Inst_type, Inst_amt
    ) VALUES (
        v_pnr_no,
        v_srl_no,
        CURDATE(),
        p_payment_mode,
        v_fare,
        p_inst_type,
        CASE WHEN p_inst_type = 'Counter' THEN ROUND(10 + RAND() * 20, 2) ELSE 0 END
    );
    
    -- Set payment ID
    SET v_payment_id = LAST_INSERT_ID();
    
    -- Create refund rule
    INSERT INTO Refund_rule (
        PNR_no, Refundable_amt, From_time, To_time
    ) VALUES (
        v_pnr_no,
        CASE 
            WHEN v_booking_status = 'Confirmed' THEN v_fare * 0.8
            WHEN v_booking_status = 'RAC' THEN v_fare * 0.9
            ELSE v_fare -- Full refund for waitlisted tickets
        END,
        '00:00:00',
        (SELECT SUBTIME(Start_time, '48:00:00') FROM Train WHERE Train_code = p_train_code)
    );
    
    -- Set output parameters
    SET p_status_message = CONCAT('Booking ', v_booking_status, 
                                 CASE WHEN v_booking_status = 'Waitlist' 
                                      THEN CONCAT('. Position: ', v_waitlist_position) 
                                      ELSE '' END);
    SET p_booking_status = v_booking_status;
    SET p_waitlist_position = CASE WHEN v_booking_status = 'Waitlist' THEN v_waitlist_position ELSE 0 END;
    
    -- Return booking information
    SELECT 
        v_pnr_no AS PNR_Number,
        p_train_code AS Train_Code,
        (SELECT Train_name FROM Train WHERE Train_code = p_train_code) AS Train_Name,
        p_from_station AS From_Station,
        p_to_station AS To_Station,
        p_from_date AS Journey_Date,
        v_fare AS Total_Fare,
        1 AS Passenger_Count,
        v_payment_id AS Payment_ID,
        v_passenger_id AS Passenger_ID,
        CASE WHEN v_seat_no IS NOT NULL THEN CONCAT(v_seat_prefix, v_seat_no) ELSE NULL END AS Seat_Number,
        v_booking_status AS Booking_Status,
        CASE WHEN v_booking_status = 'Waitlist' THEN v_waitlist_position ELSE NULL END AS Waitlist_Position,
        p_status_message AS Status_Message;
END //

DELIMITER ;