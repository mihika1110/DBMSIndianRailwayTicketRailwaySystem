DELIMITER //

CREATE TRIGGER insert_seat_availability_from_pax
BEFORE INSERT ON PAX_info
FOR EACH ROW
BEGIN
    DECLARE seat_count INT DEFAULT 72;
    DECLARE i INT DEFAULT 1;
    DECLARE existing_seats INT;
    DECLARE journey_date DATE;

    -- Get journey date from Ticket_Reservation
    SELECT From_date INTO journey_date
    FROM Ticket_Reservation
    WHERE PNR_no = NEW.PNR_no;

    -- Check if availability already exists
    SELECT COUNT(*) INTO existing_seats
    FROM Seat_availability
    WHERE Train_code = (SELECT Train_code FROM Ticket_Reservation WHERE PNR_no = NEW.PNR_no)
      AND Class_code = NEW.Class_code
      AND travel_date = journey_date;

    -- Insert seat records if not present
    IF existing_seats = 0 THEN
        WHILE i <= seat_count DO
            INSERT INTO Seat_availability (
                Train_code, Class_code, Seat_No, travel_date, Seat_Status
            ) VALUES (
                (SELECT Train_code FROM Ticket_Reservation WHERE PNR_no = NEW.PNR_no),
                NEW.Class_code,
                i,
                journey_date,
                'Available'
            );
            SET i = i + 1;
        END WHILE;
    END IF;
    UPDATE Seat_availability SET Seat_Status='Booked' WHERE Train_Code=(SELECT Train_code FROM Ticket_Reservation WHERE PNR_no = NEW.PNR_no) 
                                                            AND Class_code=NEW.Class_code
                                                            AND Seat_No=1
                                                            AND travel_date=journey_date;
END;
//

DELIMITER ;


