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
    IN p_inst_type ENUM('Online', 'Counter')
)
BEGIN
    DECLARE v_pnr_no VARCHAR(15);
    DECLARE v_from_km INT;
    DECLARE v_to_km INT;
    DECLARE v_total_fare DECIMAL(10,2) DEFAULT 0;
    DECLARE v_seat_available INT;
    DECLARE v_passenger_id VARCHAR(15);
    DECLARE v_seat_no VARCHAR(10);
    DECLARE v_fare DECIMAL(10,2);
    DECLARE v_payment_id INT;
    DECLARE v_srl_no INT;
    
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
    
    -- Create ticket reservation
    INSERT INTO Ticket_Reservation (
        PNR_no, Train_code, From_station, To_station, 
        From_Km, To_Km, From_date, To_date
    ) VALUES (
        v_pnr_no, p_train_code, p_from_station, p_to_station,
        v_from_km, v_to_km, p_from_date, p_from_date
    );
    
    -- Check seat availability
    SELECT No_of_seats INTO v_seat_available
    FROM Seat_availability
    WHERE Train_code = p_train_code
    AND Class_code = p_class_code;
    
    IF v_seat_available <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'No seats available in selected class';
    END IF;
    
    -- Generate seat number (format: Class prefix + random number)
    SET v_seat_no = CONCAT(
        (SELECT 
            CASE 
                WHEN p_class_code = '1A' THEN 'A'
                WHEN p_class_code = '2A' THEN 'B'
                WHEN p_class_code = '3A' THEN 'C'
                WHEN p_class_code = 'SL' THEN 'S'
                WHEN p_class_code = 'CC' THEN 'D'
                WHEN p_class_code = 'EC' THEN 'E'
                WHEN p_class_code = '2S' THEN 'F'
                WHEN p_class_code = 'FC' THEN 'G'
                ELSE 'H'
            END),
        FLOOR(1 + RAND() * 100)
    );
    
    -- Calculate fare
    SELECT Fare INTO v_fare
    FROM Train_fare
    WHERE Train_code = p_train_code
    AND Class_id = (SELECT Class_id FROM Class WHERE Class_code = p_class_code)
    AND From_Km <= v_from_km
    AND To_Km >= v_to_km
    LIMIT 1;
    
    -- Apply concessions
    SET v_fare = v_fare * 
        CASE p_passenger_category
            WHEN 'student' THEN 0.75
            WHEN 'senior' THEN 0.60
            WHEN 'disabled' THEN 0.50
            WHEN 'child' THEN 0.50
            ELSE 1.00
        END;
    
    -- Generate passenger ID
    SET v_passenger_id = CONCAT(v_pnr_no, '_P01');
    
    -- Add passenger
    INSERT INTO PAX_info (
        PNR_no, PAX_Name, PAX_age, Category, PAX_sex, 
        Class_code, Seat_no, Fare, Passenger_id
    ) VALUES (
        v_pnr_no,
        p_passenger_name,
        p_passenger_age,
        p_passenger_category,
        p_passenger_gender,
        p_class_code,
        v_seat_no,
        v_fare,
        v_passenger_id
    );
    
    -- Get the serial number of the passenger
    SET v_srl_no = LAST_INSERT_ID();
    
    -- Update seat availability
    UPDATE Seat_availability
    SET No_of_seats = No_of_seats - 1
    WHERE Train_code = p_train_code
    AND Class_code = p_class_code;
    
    -- Set total fare
    SET v_total_fare = v_fare;
    
    -- Process payment
    INSERT INTO Pay_info (
        PNR_no, SRL_no, Pay_date, Pay_mode, 
        Amount, Inst_type, Inst_amt
    ) VALUES (
        v_pnr_no,
        v_srl_no,
        CURDATE(),
        p_payment_mode,
        v_total_fare,
        p_inst_type,
        v_total_fare
    );
    
    -- Set payment ID
    SET v_payment_id = LAST_INSERT_ID();
    
    -- Create refund rule (example: refund 80% if cancelled more than 48 hours before departure)
    INSERT INTO Refund_rule (
        PNR_no, Refundable_amt, From_time, To_time
    ) VALUES (
        v_pnr_no,
        v_total_fare * 0.8,
        '00:00:00',
        (SELECT SUBTIME(Start_time, '48:00:00') FROM Train WHERE Train_code = p_train_code)
    );
    
    -- Return booking information
    SELECT 
        v_pnr_no AS PNR_Number,
        p_train_code AS Train_Code,
        (SELECT Train_name FROM Train WHERE Train_code = p_train_code) AS Train_Name,
        p_from_station AS From_Station,
        p_to_station AS To_Station,
        p_from_date AS Journey_Date,
        v_total_fare AS Total_Fare,
        1 AS Passenger_Count,
        v_payment_id AS Payment_ID,
        v_passenger_id AS Passenger_ID,
        v_seat_no AS Seat_Number;
END //

DELIMITER ;