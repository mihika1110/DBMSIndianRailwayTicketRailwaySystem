DELIMITER //

-- First, drop the existing trigger
DROP TRIGGER IF EXISTS insert_seat_availability_from_pax;

-- Create the new trigger with correct seat counts
CREATE TRIGGER insert_seat_availability_from_pax
BEFORE INSERT ON PAX_info
FOR EACH ROW
BEGIN
    DECLARE seat_count INT;
    DECLARE i INT DEFAULT 1;
    DECLARE existing_seats INT;
    DECLARE journey_date DATE;
    DECLARE v_train_code VARCHAR(10);

    -- Get journey date and train code from Ticket_Reservation
    SELECT From_date, Train_code INTO journey_date, v_train_code
    FROM Ticket_Reservation
    WHERE PNR_no = NEW.PNR_no;

    -- Get seat count from Class table
    SELECT Seat_per_coach INTO seat_count
    FROM Class
    WHERE Class_code = NEW.Class_code;

    -- Check if availability already exists
    SELECT COUNT(*) INTO existing_seats
    FROM Seat_availability
    WHERE Train_code = v_train_code
      AND Class_code = NEW.Class_code
      AND travel_date = journey_date;

    -- If no seats exist for this train-class-date combination
    IF existing_seats = 0 THEN
        -- Delete any existing seats (in case they were created with wrong count)
        DELETE FROM Seat_availability
        WHERE Train_code = v_train_code
        AND Class_code = NEW.Class_code
        AND travel_date = journey_date;

        -- Insert correct number of seats
        WHILE i <= seat_count DO
            INSERT INTO Seat_availability (
                Train_code, Class_code, Seat_No, travel_date, Seat_Status
            ) VALUES (
                v_train_code,
                NEW.Class_code,
                i,
                journey_date,
                'Available'
            );
            SET i = i + 1;
        END WHILE;
        UPDATE Seat_availability SET Seat_Status='Booked' WHERE Train_Code=v_train_code
                                                            AND Class_code=NEW.Class_code
                                                            AND Seat_No=1
                                                            AND travel_date=journey_date
    END IF;
    
    -- Update seat status if booking is confirmed
    IF NEW.Booking_status = 'Confirmed' AND NEW.Seat_no IS NOT NULL THEN
        UPDATE Seat_availability 
        SET Seat_Status = 'Booked' 
        WHERE Train_Code = v_train_code
        AND Class_code = NEW.Class_code
        AND Seat_No = CAST(SUBSTRING(NEW.Seat_no, 2) AS UNSIGNED)
        AND travel_date = journey_date;
    END IF;
END;
//

DELIMITER ;