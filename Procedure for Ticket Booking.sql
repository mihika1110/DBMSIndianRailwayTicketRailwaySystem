DELIMITER $$

CREATE PROCEDURE Book_Ticket (
    IN in_Train_code VARCHAR(10),
    IN in_From_station VARCHAR(50),
    IN in_To_station VARCHAR(50),
    IN in_From_Km INT,
    IN in_To_Km INT,
    IN in_From_date DATE,
    IN in_To_date DATE,
    
    IN in_PAX_Name VARCHAR(100),
    IN in_PAX_age INT,
    IN in_PAX_sex ENUM('M', 'F', 'Other'),
    IN in_Seat_no VARCHAR(10),
    IN in_Fare DECIMAL(10,2),
    
    IN in_Pay_mode ENUM('Credit Card', 'Debit Card', 'UPI', 'Net Banking', 'Cash'),
    IN in_Inst_type ENUM('Online', 'Counter'),
    IN in_Inst_amt DECIMAL(10,2)
)
BEGIN
    DECLARE new_PNR VARCHAR(15);
    DECLARE new_SRL INT;
    DECLARE new_Passenger_id VARCHAR(20);
    DECLARE max_serial INT DEFAULT 0;

    -- Step 1: Generate next serial number for PNR (based on existing rows)
    SELECT 
        IFNULL(MAX(CAST(SUBSTRING(PNR_no, 10) AS UNSIGNED)), 1000) + 1 
    INTO 
        max_serial 
    FROM 
        Ticket_Reservation 
    WHERE 
        Train_code = in_Train_code;

    -- Step 2: Create PNR in format PNR<TrainCode><Serial>
    SET new_PNR = CONCAT('PNR', in_Train_code, LPAD(max_serial, 3, '0'));

    -- Step 3: Insert into Ticket_Reservation
    INSERT INTO Ticket_Reservation (
        PNR_no, Train_code, From_station, To_station, From_Km, To_Km, From_date, To_date
    ) VALUES (
        new_PNR, in_Train_code, in_From_station, in_To_station, in_From_Km, in_To_Km, in_From_date, in_To_date
    );

    -- Step 4: Insert into PAX_info (temp Passenger_id placeholder, fixed later)
    INSERT INTO PAX_info (
        PNR_no, PAX_Name, PAX_age, PAX_sex, Seat_no, Fare, Passenger_id
    ) VALUES (
        new_PNR, in_PAX_Name, in_PAX_age, in_PAX_sex, in_Seat_no, in_Fare, NULL
    );

    -- Step 5: Get SRL_no just inserted
    SET new_SRL = LAST_INSERT_ID();

    -- Step 6: Generate Passenger_id as PNR_P1 (since single passenger)
    SET new_Passenger_id = CONCAT(new_PNR, '_P1');

    -- Step 7: Update Passenger_id for this SRL
    UPDATE PAX_info
    SET Passenger_id = new_Passenger_id
    WHERE SRL_no = new_SRL;

    -- Step 8: Insert into Pay_info using the SRL
    INSERT INTO Pay_info (
        PNR_no, SRL_no, Pay_date, Pay_mode, Amount, Inst_type, Inst_amt
    ) VALUES (
        new_PNR, new_SRL, CURDATE(), in_Pay_mode, in_Fare, in_Inst_type, in_Inst_amt
    );

    -- Step 9: Update seat availability
    UPDATE Seat_availability
    SET No_of_seats = No_of_seats - 1
    WHERE Train_code = in_Train_code AND No_of_seats > 0;

    -- Final: Return PNR, Passenger_id, and SRL
    SELECT 
        new_PNR AS 'PNR_Number',
        new_Passenger_id AS 'Passenger_ID',
        new_SRL AS 'SRL_no';
END $$

DELIMITER ;
