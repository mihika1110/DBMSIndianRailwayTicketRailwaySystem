-- 1. First, verify we have data in the required tables
SELECT COUNT(*) AS ticket_count FROM Ticket_Reservation;
SELECT COUNT(*) AS fare_count FROM Train_fare;
SELECT COUNT(*) AS class_count FROM Class;

-- 2. Create temporary tables for Indian names with expanded options
CREATE TEMPORARY TABLE IF NOT EXISTS IndianFirstNames (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TEMPORARY TABLE IF NOT EXISTS IndianLastNames (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50)
);

-- 3. Insert 100 Indian first names
INSERT INTO IndianFirstNames (name) VALUES
('Aarav'),('Aanya'),('Advait'),('Aditi'),('Akshay'),('Ananya'),('Arjun'),('Avni'),('Dhruv'),('Diya'),
('Ishaan'),('Kavya'),('Reyansh'),('Saanvi'),('Vihaan'),('Anika'),('Atharv'),('Pari'),('Kabir'),('Myra'),
('Aadi'),('Kiara'),('Vivaan'),('Aarohi'),('Krish'),('Anaya'),('Ayaan'),('Amaira'),('Arnav'),('Ira'),
('Rudra'),('Ahana'),('Shaurya'),('Aadhya'),('Vivaan'),('Anvi'),('Aryan'),('Prisha'),('Yuvaan'),('Ishita'),
('Rohan'),('Mira'),('Advaith'),('Navya'),('Aarush'),('Pihu'),('Veer'),('Zara'),('Shivansh'),('Kyra'),
('Aarav'),('Aanya'),('Advait'),('Aditi'),('Akshay'),('Ananya'),('Arjun'),('Avni'),('Dhruv'),('Diya'),
('Ishaan'),('Kavya'),('Reyansh'),('Saanvi'),('Vihaan'),('Anika'),('Atharv'),('Pari'),('Kabir'),('Myra'),
('Aadi'),('Kiara'),('Vivaan'),('Aarohi'),('Krish'),('Anaya'),('Ayaan'),('Amaira'),('Arnav'),('Ira'),
('Rudra'),('Ahana'),('Shaurya'),('Aadhya'),('Vivaan'),('Anvi'),('Aryan'),('Prisha'),('Yuvaan'),('Ishita'),
('Rohan'),('Mira'),('Advaith'),('Navya'),('Aarush'),('Pihu'),('Veer'),('Zara'),('Shivansh'),('Kyra');

-- 4. Insert 100 Indian last names
INSERT INTO IndianLastNames (name) VALUES
('Patel'),('Sharma'),('Singh'),('Kumar'),('Gupta'),('Verma'),('Joshi'),('Malhotra'),('Reddy'),('Agarwal'),
('Mehta'),('Choudhary'),('Desai'),('Jain'),('Shah'),('Naidu'),('Rao'),('Iyer'),('Nair'),('Menon'),
('Pillai'),('Chauhan'),('Trivedi'),('Tiwari'),('Mishra'),('Dubey'),('Saxena'),('Bose'),('Banerjee'),('Chatterjee'),
('Das'),('Sen'),('Ghosh'),('Mukherjee'),('Dutta'),('Chakraborty'),('Ganguly'),('Roy'),('Sinha'),('Khanna'),
('Kapoor'),('Ahuja'),('Bajaj'),('Bhasin'),('Chawla'),('Dhawan'),('Gandhi'),('Grover'),('Khanna'),('Kohli'),
('Luthra'),('Malhotra'),('Mehrotra'),('Nagpal'),('Oberoi'),('Puri'),('Rastogi'),('Sarin'),('Talwar'),('Walia'),
('Arora'),('Bedi'),('Chadha'),('Dewan'),('Gill'),('Handa'),('Johar'),('Khatri'),('Lamba'),('Madan'),
('Nanda'),('Pandey'),('Rana'),('Sethi'),('Tandon'),('Uppal'),('Vohra'),('Yadav'),('Zutshi'),('Anand'),
('Bakshi'),('Chopra'),('Dhaliwal'),('Grewal'),('Hayer'),('Jolly'),('Kalla'),('Loomba'),('Mahajan'),('Narula'),
('Ojha'),('Prasad'),('Rattan'),('Sahni'),('Taneja'),('Virk'),('Wadhwa'),('Xalxo'),('Yogi'),('Zaidi');

-- 5. Set base fares
SET @base_fare_1A = 300.00;
SET @base_fare_2A = 200.00;
SET @base_fare_3A = 150.00;
SET @base_fare_SL = 100.00;
SET @default_base_fare = 120.00;

-- 6. Insert into PAX_info with a limit of 6000 entries
-- 6. Insert into PAX_info with proper passenger numbering
INSERT INTO PAX_info (PNR_no, PAX_Name, PAX_age, PAX_sex, Seat_no, Fare, Passenger_id)
WITH RECURSIVE PNR_Series AS (
    SELECT 
        PNR_no, 
        1 AS passenger_num,
        FLOOR(1 + RAND() * 4) AS max_passengers  -- Randomly assign 1-4 passengers per PNR
    FROM Ticket_Reservation
    WHERE EXISTS (
        SELECT 1 FROM Train_fare 
        WHERE Train_fare.Train_code = Ticket_Reservation.Train_code
    )
    UNION ALL
    SELECT 
        PNR_no, 
        passenger_num + 1,
        max_passengers
    FROM PNR_Series
    WHERE passenger_num < max_passengers
)
SELECT 
    ps.PNR_no,
    CONCAT(
        (SELECT name FROM IndianFirstNames ORDER BY RAND() LIMIT 1),
        ' ',
        (SELECT name FROM IndianLastNames ORDER BY RAND() LIMIT 1)
    ) AS PAX_Name,
    FLOOR(5 + RAND() * 70) AS PAX_age,
    IF(RAND() < 0.5, 'M', 'F') AS PAX_sex,
    CONCAT(
        IFNULL(
            (SELECT LEFT(Class_code, 1) FROM Class 
            JOIN Train_fare ON Class.Class_id = Train_fare.Class_id
            WHERE Train_fare.Train_code = tr.Train_code
            LIMIT 1),
            'A'
        ),
        FLOOR(1 + RAND() * 50)
    ) AS Seat_no,
    IFNULL(
        (SELECT Fare FROM Train_fare 
         WHERE Train_code = tr.Train_code 
         AND From_Km <= tr.From_Km AND To_Km >= tr.To_Km
         LIMIT 1),
        ROUND(1.5 * (tr.To_Km - tr.From_Km), 2) + @default_base_fare
    ) AS Fare,
    CONCAT(
        ps.PNR_no, 
        '_P', 
        ROW_NUMBER() OVER (PARTITION BY ps.PNR_no ORDER BY ps.passenger_num)
    ) AS Passenger_id
FROM PNR_Series ps
JOIN Ticket_Reservation tr ON ps.PNR_no = tr.PNR_no
LIMIT 6000;  -- Strict limit of 6000 entries

-- 7. Verify the inserted data
SELECT COUNT(*) AS pax_count FROM PAX_info;
SELECT * FROM PAX_info LIMIT 10;

-- 8. Clean up
DROP TEMPORARY TABLE IF EXISTS IndianFirstNames;
DROP TEMPORARY TABLE IF EXISTS IndianLastNames;