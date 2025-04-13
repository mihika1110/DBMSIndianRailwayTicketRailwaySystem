-- 1. First, verify we have data in the required tables
SELECT COUNT(*) AS ticket_count FROM Ticket_Reservation;
SELECT COUNT(*) AS fare_count FROM Train_fare;
SELECT COUNT(*) AS class_count FROM Class;

-- 2. Create temporary tables for Indian names (gender-specific only)
CREATE TEMPORARY TABLE IF NOT EXISTS IndianFirstNames (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    gender ENUM('M','F') NOT NULL
);

CREATE TEMPORARY TABLE IF NOT EXISTS IndianLastNames (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50)
);

-- 3. Insert 100 Indian male first names
INSERT INTO IndianFirstNames (name, gender) VALUES
('Aarav','M'),('Advait','M'),('Akshay','M'),('Arjun','M'),('Dhruv','M'),('Ishaan','M'),('Reyansh','M'),('Vihaan','M'),
('Atharv','M'),('Kabir','M'),('Aadi','M'),('Krish','M'),('Ayaan','M'),('Arnav','M'),('Rudra','M'),('Shaurya','M'),
('Aarush','M'),('Veer','M'),('Shivansh','M'),('Yuvaan','M'),('Advaith','M'),('Rohan','M'),('Vivaan','M'),('Krishna','M'),
('Mohammed','M'),('Aryan','M'),('Rayaan','M'),('Sai','M'),('Aditya','M'),('Ansh','M'),('Daksh','M'),('Harsh','M'),
('Kian','M'),('Laksh','M'),('Om','M'),('Pranav','M'),('Rudransh','M'),('Shaurya','M'),('Ved','M'),('Yash','M'),
('Abhinav','M'),('Chirag','M'),('Dev','M'),('Gautam','M'),('Jay','M'),('Kartik','M'),('Neel','M'),('Parth','M'),
('Rishi','M'),('Siddharth','M'),('Tanmay','M'),('Utkarsh','M'),('Viraj','M'),('Zayn','M'),('Aarav','M'),('Advait','M');

-- 4. Insert 100 Indian female first names
INSERT INTO IndianFirstNames (name, gender) VALUES
('Aanya','F'),('Aditi','F'),('Ananya','F'),('Avni','F'),('Diya','F'),('Kavya','F'),('Saanvi','F'),('Anika','F'),
('Pari','F'),('Myra','F'),('Kiara','F'),('Aarohi','F'),('Anaya','F'),('Amaira','F'),('Ira','F'),('Ahana','F'),
('Aadhya','F'),('Anvi','F'),('Prisha','F'),('Ishita','F'),('Mira','F'),('Navya','F'),('Pihu','F'),('Zara','F'),
('Kyra','F'),('Meera','F'),('Neha','F'),('Priya','F'),('Riya','F'),('Siya','F'),('Tara','F'),('Vanya','F'),
('Aalia','F'),('Bhavya','F'),('Disha','F'),('Esha','F'),('Gauri','F'),('Ishani','F'),('Jhanvi','F'),('Kashvi','F'),
('Lavanya','F'),('Mannat','F'),('Nitya','F'),('Ojasvi','F'),('Pragya','F'),('Radha','F'),('Sara','F'),('Trisha','F'),
('Anika','F'),('Avni','F'),('Diya','F'),('Kavya','F'),('Saanvi','F'),('Anika','F'),('Pari','F'),('Myra','F');

-- 5. Insert 100 Indian last names (no community info)
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

-- 5. Insert into PAX_info with proper fare calculation from Train_fare
INSERT INTO PAX_info (PNR_no, PAX_Name, PAX_age, Category, PAX_sex, Class_code, Seat_no, Fare, Passenger_id)
WITH RECURSIVE PNR_Series AS (
    SELECT 
        PNR_no, 
        1 AS passenger_num,
        FLOOR(1 + RAND() * 4) AS max_passengers
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
        (SELECT name FROM IndianFirstNames WHERE gender = IF(RAND() < 0.5, 'M', 'F') ORDER BY RAND() LIMIT 1),
        ' ',
        (SELECT name FROM IndianLastNames ORDER BY RAND() LIMIT 1)
    ) AS PAX_Name,
    FLOOR(5 + RAND() * 70) AS PAX_age,
    CASE 
        WHEN FLOOR(5 + RAND() * 70) < 18 THEN 
            CASE WHEN RAND() < 0.7 THEN 'student' ELSE 'general' END
        WHEN FLOOR(5 + RAND() * 70) >= 60 THEN 
            CASE WHEN RAND() < 0.8 THEN 'senior' ELSE 'general' END
        WHEN RAND() < 0.02 THEN 'disabled'
        ELSE 'general'
    END AS Category,
    IF(RAND() < 0.5, 'M', 'F') AS PAX_sex,
    class_data.Class_code,
    CONCAT(
        class_data.Seat_prefix,
        FLOOR(1 + RAND() * class_data.Seat_limit)
    ) AS Seat_no,
    (
        SELECT tf.Fare 
        FROM Train_fare tf
        JOIN Class c ON tf.Class_id = c.Class_id
        WHERE tf.Train_code = tr.Train_code
          AND c.Class_code = class_data.Class_code
          AND tf.From_Km <= tr.From_Km
          AND tf.To_Km >= tr.To_Km
          AND tf.Category = CASE 
              WHEN FLOOR(5 + RAND() * 70) < 18 THEN 
                  CASE WHEN RAND() < 0.7 THEN 'student' ELSE 'general' END
              WHEN FLOOR(5 + RAND() * 70) >= 60 THEN 
                  CASE WHEN RAND() < 0.8 THEN 'senior' ELSE 'general' END
              WHEN RAND() < 0.02 THEN 'disabled'
              ELSE 'general'
          END
        ORDER BY tf.To_Km - tf.From_Km ASC
        LIMIT 1
    ) AS Fare,
    CONCAT(
        ps.PNR_no, 
        '_P', 
        LPAD(ps.passenger_num, 2, '0')
    ) AS Passenger_id
FROM PNR_Series ps
JOIN Ticket_Reservation tr ON ps.PNR_no = tr.PNR_no
CROSS JOIN (
    SELECT 
        Class_code,
        CASE 
            WHEN Class_code = '1A' THEN 'A'
            WHEN Class_code = '2A' THEN 'B'
            WHEN Class_code = '3A' THEN 'C'
            WHEN Class_code = 'SL' THEN 'S'
            WHEN Class_code = 'CC' THEN 'D'
            WHEN Class_code = 'EC' THEN 'E'
            WHEN Class_code = '2S' THEN 'F'
            WHEN Class_code = 'FC' THEN 'G'
            ELSE 'H' -- GN
        END AS Seat_prefix,
        CASE 
            WHEN Class_code = '1A' THEN 18
            WHEN Class_code = '2A' THEN 46
            WHEN Class_code = '3A' THEN 64
            WHEN Class_code = 'SL' THEN 72
            WHEN Class_code = 'CC' THEN 78
            WHEN Class_code = 'EC' THEN 56
            WHEN Class_code = '2S' THEN 108
            WHEN Class_code = 'FC' THEN 22
            ELSE 90 -- GN
        END AS Seat_limit
    FROM (
        SELECT 
            CASE 
                WHEN RAND() < 0.1 THEN '1A'
                WHEN RAND() < 0.2 THEN '2A'
                WHEN RAND() < 0.5 THEN '3A'
                WHEN RAND() < 0.7 THEN 'SL'
                WHEN RAND() < 0.75 THEN 'CC'
                WHEN RAND() < 0.8 THEN 'EC'
                WHEN RAND() < 0.85 THEN '2S'
                WHEN RAND() < 0.95 THEN 'FC'
                ELSE 'GN'
            END AS Class_code
    ) AS random_class
) AS class_data
WHERE EXISTS (
    SELECT 1 FROM Train_fare 
    WHERE Train_code = tr.Train_code 
    AND From_Km <= tr.From_Km 
    AND To_Km >= tr.To_Km
)
ORDER BY ps.PNR_no, ps.passenger_num
LIMIT 6000;

-- 6. Verify the inserted data
SELECT COUNT(*) AS pax_count FROM PAX_info;
SELECT * FROM PAX_info LIMIT 10;

-- 7. Clean up
DROP TEMPORARY TABLE IF EXISTS IndianFirstNames;
DROP TEMPORARY TABLE IF EXISTS IndianLastNames;