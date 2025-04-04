-- 1. Zone 
CREATE TABLE Zone (
    Zone_id VARCHAR(10) PRIMARY KEY,
    Zone_name VARCHAR(50),
    Zone_code VARCHAR(10)
);
 
-- 2. Station 
CREATE TABLE Station (
    Station_id VARCHAR(10) PRIMARY KEY,
    Station_code VARCHAR(10),
    Station_name VARCHAR(100),
    Zone_id VARCHAR(10),
    FOREIGN KEY (Zone_id) REFERENCES Zone(Zone_id) ON DELETE CASCADE
);
 
-- 3. Train Details
CREATE TABLE Train (
    Train_code VARCHAR(10) PRIMARY KEY,
    Train_name VARCHAR(100),
    Start_time TIME,
    End_time TIME,
    Distance INT,
    Frequency VARCHAR(20)
);
 
-- 4. Ticket Reservation 
CREATE TABLE Ticket_Reservation (
    PNR_no VARCHAR(15) PRIMARY KEY,
    Train_code VARCHAR(10),
    From_station VARCHAR(50),
    To_station VARCHAR(50),
    From_Km INT,
    To_Km INT,
    From_date DATE,
    To_date DATE,
    FOREIGN KEY (Train_code) REFERENCES Train(Train_code) ON DELETE CASCADE
);
 
-- 5. Passenger Information (PAX_info) 
CREATE TABLE PAX_info (
    SRL_no INT PRIMARY KEY AUTO_INCREMENT,
    PNR_no VARCHAR(15),
    PAX_Name VARCHAR(100),
    PAX_age INT CHECK (PAX_age > 0),
    PAX_sex ENUM('M', 'F', 'Other'),
    Seat_no VARCHAR(10),
    Fare DECIMAL(10,2),
    Passenger_id VARCHAR(15) UNIQUE, -- Ensuring Passenger_id is unique for foreign key use
    FOREIGN KEY (PNR_no) REFERENCES Ticket_Reservation(PNR_no) ON DELETE CASCADE
);
 
-- 6. Payment Information 
CREATE TABLE Pay_info (
    Payment_id INT PRIMARY KEY AUTO_INCREMENT,
    PNR_no VARCHAR(15),
    SRL_no INT,
    Pay_date DATE,
    Pay_mode ENUM('Credit Card', 'Debit Card', 'UPI', 'Net Banking', 'Cash'),
    Amount DECIMAL(10,2),
    Inst_type ENUM('Online', 'Counter'),
    Inst_amt DECIMAL(10,2),
    FOREIGN KEY (PNR_no) REFERENCES Ticket_Reservation(PNR_no) ON DELETE CASCADE,
    FOREIGN KEY (SRL_no) REFERENCES PAX_info(SRL_no) ON DELETE CASCADE
);
 
-- 7. Refund Rule 
CREATE TABLE Refund_rule (
    Rule_id INT PRIMARY KEY AUTO_INCREMENT,
    PNR_no VARCHAR(15),
    Refundable_amt DECIMAL(10,2),
    From_time TIME,
    To_time TIME,
    FOREIGN KEY (PNR_no) REFERENCES Ticket_Reservation(PNR_no) ON DELETE CASCADE
);
 
-- 8. Login Credentials 
CREATE TABLE Login_credential (
    login_id VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255),
    Passenger_id VARCHAR(15),
    FOREIGN KEY (Passenger_id) REFERENCES PAX_info(Passenger_id) ON DELETE CASCADE
);
 
-- 9. Train Fare 
CREATE TABLE Train_fare (
    Train_fare_id INT PRIMARY KEY AUTO_INCREMENT,
    Train_code VARCHAR(10),
    Class_id VARCHAR(10),
    From_Km INT,
    To_Km INT,
    From_date DATE,
    To_date DATE,
    Fare DECIMAL(10,2),
    FOREIGN KEY (Train_code) REFERENCES Train(Train_code) ON DELETE CASCADE
);
 
-- 10. Class
CREATE TABLE Class (
    Class_id VARCHAR(10) PRIMARY KEY,
    Class_code VARCHAR(10),
    Class_name VARCHAR(50),
    Seat_per_coach INT
);
 
-- 11. Seat Availability 
CREATE TABLE Seat_availability (
    Details_id INT PRIMARY KEY AUTO_INCREMENT,
    Train_code VARCHAR(10),
    No_of_seats INT,
    FOREIGN KEY (Train_code) REFERENCES Train(Train_code) ON DELETE CASCADE
);
 
-- 12. Via Details 
CREATE TABLE Via_details (
    Details_id INT PRIMARY KEY AUTO_INCREMENT,
    Train_code VARCHAR(10),
    Via_station_code VARCHAR(10),
    Via_station_name VARCHAR(100),
    Km_from_origin INT,
    Reach_time TIME,
    FOREIGN KEY (Train_code) REFERENCES Train(Train_code) ON DELETE CASCADE
);