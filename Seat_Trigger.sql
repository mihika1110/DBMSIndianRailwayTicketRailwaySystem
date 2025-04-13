DELIMITER $$

CREATE TRIGGER update_seat_availability_after_insert
AFTER INSERT ON PAX_info
FOR EACH ROW
BEGIN
    DECLARE v_Train_code VARCHAR(10);

    -- Get the Train_code for the inserted PNR_no
    SELECT Train_code INTO v_Train_code
    FROM Ticket_Reservation
    WHERE PNR_no = NEW.PNR_no;

    -- Update Seat_availability table
    UPDATE Seat_availability
    SET No_of_seats = No_of_seats - 1
    WHERE Train_code = v_Train_code
      AND Class_code = NEW.Class_code;
END$$

DELIMITER ;
