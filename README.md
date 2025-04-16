# DBMS Project Setup Instructions

## Prerequisites
- MySQL Server installed on your system
- MySQL Command Line Client or MySQL Workbench

## Initial Setup

## ✅ Step 1: Start MySQL Server
Depending on your operating system, use one of the following methods:

**Windows:**
```
net start mysql
```
Or use the MySQL service in Windows Services.

**macOS:**
```
sudo /usr/local/mysql/support-files/mysql.server start
```
Or use System Preferences → MySQL → Start MySQL Server.

**Linux:**
```
sudo systemctl start mysql
```
Or
```
sudo service mysql start
```

## ✅ Step 2: Log into MySQL
Open your terminal or command prompt and log into MySQL:

```
mysql -u username -p
```
Replace 'username' with your MySQL username (often 'root'). You will be prompted to enter your password.

## ✅ Step 3: Create a New Database
Once logged in, create a new database for the project:

```sql
CREATE DATABASE dbms_project;
```

## ✅ Step 4: Select the Database
```sql
USE dbms_project;
```

## ✅ Step 5: Confirm Database Selection
You can verify that you're using the correct database with:

```sql
SELECT DATABASE();
```

---

# 📚 Database Schema Implementation

Execute the following SQL commands to create the database schema:

---

## 🏗️ Creating Tables

---

### 1. 🗺️ Zone Table
```sql
CREATE TABLE Zone (
    Zone_id VARCHAR(10) PRIMARY KEY,
    Zone_name VARCHAR(50),
    Zone_code VARCHAR(10)
);
```

---

### 2. 🚉 Station Table
```sql
CREATE TABLE Station (
    Station_id VARCHAR(10) PRIMARY KEY,
    Station_code VARCHAR(10),
    Station_name VARCHAR(100),
    Zone_id VARCHAR(10),
    FOREIGN KEY (Zone_id) REFERENCES Zone(Zone_id) ON DELETE CASCADE
);
```

---

### 3. 🚆 Train Details Table
```sql
CREATE TABLE Train (
    Train_code VARCHAR(10) PRIMARY KEY,
    Train_name VARCHAR(100),
    Start_time TIME,
    End_time TIME,
    Distance INT,
    Frequency VARCHAR(20)
);
```

```sql
-- Add Waitlist limit to Train table
ALTER TABLE Train
ADD COLUMN Waitlist_limit INT DEFAULT 100;
```

---

### 4. 🎫 Ticket Reservation Table
```sql
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
```

---

### 5. 👤 Passenger Information (PAX_info) Table
```sql
CREATE TABLE PAX_info (
    SRL_no INT PRIMARY KEY AUTO_INCREMENT,
    PNR_no VARCHAR(15),
    PAX_Name VARCHAR(100),
    PAX_age INT CHECK (PAX_age > 0),
    Category VARCHAR(20),
    PAX_sex ENUM('M', 'F', 'Other'),
    Class_code VARCHAR(15),
    Seat_no VARCHAR(10),
    Fare DECIMAL(10,2),
    Booking_status ENUM('Confirmed', 'RAC', 'Waitlist', 'Cancelled') DEFAULT 'Confirmed',
    Waitlist_position INT NULL,
    Passenger_id VARCHAR(15) UNIQUE, -- Ensuring Passenger_id is unique for foreign key use
    FOREIGN KEY (PNR_no) REFERENCES Ticket_Reservation(PNR_no) ON DELETE CASCADE
);
```

---

### 6. 💳 Payment Information Table
```sql
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
```

---

### 7. 🔐 Login Credentials Table
```sql
CREATE TABLE Login_credential (
    login_id VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255),
    Passenger_id VARCHAR(15),
    FOREIGN KEY (Passenger_id) REFERENCES PAX_info(Passenger_id) ON DELETE CASCADE
);
```

---

### 8. 💰 Train Fare Table
```sql
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
```

---

### 9. 🪑 Class Table
```sql
CREATE TABLE Class (
    Class_id VARCHAR(10) PRIMARY KEY,
    Class_code VARCHAR(10),
    Class_name VARCHAR(50),
    Seat_per_coach INT
);
```

```sql
-- Add RAC limit to Class table
ALTER TABLE Class
ADD COLUMN RAC_limit INT DEFAULT 10;
```

---

### 10. 📅 Seat Availability Table
```sql
CREATE TABLE Seat_availability (
    Details_id INT PRIMARY KEY AUTO_INCREMENT,
    Train_code VARCHAR(10),
    Class_code VARCHAR(10),
    Seat_No INT,
    travel_date DATE NOT NULL,
    Seat_Status ENUM('Available', 'Unavailable', 'Booked', 'RAC'),
    FOREIGN KEY (Train_code) REFERENCES Train(Train_code) ON DELETE CASCADE
);
```

---

### 11. 🛤️ Via Details Table
```sql
CREATE TABLE Via_details (
    Details_id INT PRIMARY KEY AUTO_INCREMENT,
    Train_code VARCHAR(10),
    Via_station_code VARCHAR(10),
    Via_station_name VARCHAR(100),
    Km_from_origin INT,
    Reach_time TIME,
    FOREIGN KEY (Train_code) REFERENCES Train(Train_code) ON DELETE CASCADE
);
```

---

### 12. ❌ Cancellation Records Table
```sql
CREATE TABLE IF NOT EXISTS Cancellation_Records (
    Cancellation_id INT PRIMARY KEY AUTO_INCREMENT,
    PNR_no VARCHAR(15),
    Cancellation_time DATETIME,
    Original_fare DECIMAL(10,2),
    Refund_amount DECIMAL(10,2),
    FOREIGN KEY (PNR_no) REFERENCES Ticket_Reservation(PNR_no)
);
```

---


## ✅ Step 6: Inserting Data into Tables

#### Insert data into `Zone` table

```sql
INSERT INTO Zone (Zone_id, Zone_name, Zone_code) VALUES
('Z001', 'Northern Railway', 'NR'),
('Z002', 'Southern Railway', 'SR'),
('Z003', 'Eastern Railway', 'ER'),
('Z004', 'Western Railway', 'WR'),
('Z005', 'Central Railway', 'CR'),
('Z006', 'North Eastern Railway', 'NER'),
('Z007', 'South Eastern Railway', 'SER'),
('Z008', 'North Western Railway', 'NWR'),
('Z009', 'South Western Railway', 'SWR');
```

#### Insert data into `Station` table

```sql
INSERT INTO Station (Station_id, Station_code, Station_name, Zone_id) VALUES
('S001', 'NDLS', 'New Delhi', 'Z001'),
('S002', 'DLI', 'Delhi', 'Z001'),
('S003', 'LDH', 'Ludhiana', 'Z001'),
('S004', 'UMB', 'Ambala Cantt', 'Z001'),
('S005', 'CDG', 'Chandigarh', 'Z001'),
('S006', 'JUC', 'Jammu Tawi', 'Z001'),
('S007', 'ASR', 'Amritsar', 'Z001'),
('S008', 'PTA', 'Patiala', 'Z001'),
('S009', 'BTI', 'Bathinda', 'Z001'),
('S010', 'PTK', 'Pathankot', 'Z001'),
('S011', 'SGNR', 'Sri Ganganagar', 'Z001'),
('S012', 'MAS', 'Chennai Central', 'Z002'),
('S013', 'CBE', 'Coimbatore', 'Z002'),
('S014', 'MDU', 'Madurai', 'Z002'),
('S015', 'TVC', 'Thiruvananthapuram', 'Z002'),
('S016', 'ERS', 'Ernakulam', 'Z002'),
('S017', 'SA', 'Salem', 'Z002'),
('S018', 'TPJ', 'Tiruchchirappalli', 'Z002'),
('S019', 'NCJ', 'Kanchipuram', 'Z002'),
('S020', 'KTYM', 'Kottayam', 'Z002'),
('S021', 'CLT', 'Kozhikode', 'Z002'),
('S022', 'HWH', 'Howrah', 'Z003'),
('S023', 'SDAH', 'Sealdah', 'Z003'),
('S024', 'KOAA', 'Kolkata', 'Z003'),
('S025', 'ASN', 'Asansol', 'Z003'),
('S026', 'DHN', 'Dhanbad', 'Z003'),
('S027', 'MLDT', 'Malda Town', 'Z003'),
('S028', 'ADRA', 'Adra', 'Z003'),
('S029', 'DURG', 'Durgapur', 'Z003'),
('S030', 'BWN', 'Barddhaman', 'Z003'),
('S031', 'RNC', 'Ranchi', 'Z003'),
('S032', 'BCT', 'Mumbai Central', 'Z004'),
('S033', 'ADI', 'Ahmedabad', 'Z004'),
('S034', 'INDB', 'Indore', 'Z004'),
('S035', 'UJN', 'Ujjain', 'Z004'),
('S036', 'RTM', 'Ratlam', 'Z004'),
('S037', 'BRC', 'Vadodara', 'Z004'),
('S038', 'ST', 'Surat', 'Z004'),
('S039', 'RJT', 'Rajkot', 'Z004'),
('S040', 'BVC', 'Bhavnagar', 'Z004'),
('S041', 'JP', 'Jaipur', 'Z004'),
('S042', 'CSTM', 'Mumbai CSM Terminus', 'Z005'),
('S043', 'NGP', 'Nagpur', 'Z005'),
('S044', 'BSL', 'Bhusaval', 'Z005'),
('S045', 'PUNE', 'Pune', 'Z005'),
('S046', 'SUR', 'Solapur', 'Z005'),
('S047', 'AK', 'Akola', 'Z005'),
('S048', 'MMR', 'Manmad', 'Z005'),
('S049', 'NSK', 'Nasik Road', 'Z005'),
('S050', 'KYN', 'Kalyan Junction', 'Z005'),
('S051', 'DR', 'Dadar', 'Z005'),
('S052', 'GKP', 'Gorakhpur', 'Z006'),
('S053', 'LJN', 'Lucknow Junction', 'Z006'),
('S054', 'CNB', 'Kanpur Central', 'Z006'),
('S055', 'ALD', 'Prayagraj', 'Z006'),
('S056', 'BSB', 'Varanasi', 'Z006'),
('S057', 'MUV', 'Manduadih', 'Z006'),
('S058', 'FD', 'Faizabad', 'Z006'),
('S059', 'BE', 'Bareilly', 'Z006'),
('S060', 'MB', 'Moradabad', 'Z006'),
('S061', 'SCC', 'Saharanpur', 'Z006'),
('S062', 'KGP', 'Kharagpur', 'Z007'),
('S063', 'BBS', 'Bhubaneswar', 'Z007'),
('S064', 'SBP', 'Sambalpur', 'Z007'),
('S065', 'CTC', 'Cuttack', 'Z007'),
('S066', 'PURI', 'Puri', 'Z007'),
('S067', 'BLS', 'Balasore', 'Z007'),
('S068', 'JSG', 'Jharsuguda', 'Z007'),
('S069', 'TATA', 'Tatanagar', 'Z007'),
('S070', 'ROU', 'Rourkela', 'Z007'),
('S071', 'SRC', 'Shalimar', 'Z007'),
('S072', 'BIKN', 'Bikaner', 'Z008'),
('S073', 'JU', 'Jodhpur', 'Z008'),
('S074', 'KOTA', 'Kota', 'Z008'),
('S075', 'BKN', 'Bikaner', 'Z008'),
('S076', 'AII', 'Ajmer', 'Z008'),
('S077', 'UDZ', 'Udaipur', 'Z008'),
('S078', 'JLN', 'Jaisalmer', 'Z008'),
('S079', 'BNR', 'Beawar', 'Z008'),
('S080', 'COR', 'Churu', 'Z008'),
('S081', 'SOG', 'Sikar', 'Z008'),
('S082', 'SBC', 'Bengaluru City', 'Z009'),
('S083', 'MYS', 'Mysuru', 'Z009'),
('S084', 'UBL', 'Hubballi', 'Z009'),
('S085', 'BJP', 'Bijapur', 'Z009'),
('S086', 'BGM', 'Belagavi', 'Z009'),
('S087', 'BAY', 'Ballari', 'Z009'),
('S088', 'DVG', 'Davangere', 'Z009'),
('S089', 'YPR', 'Yesvantpur', 'Z009'),
('S090', 'SMET', 'Shivamogga', 'Z009'),
('S091', 'HAS', 'Hassan', 'Z009'),
('S092', 'GHY', 'Guwahati', 'Z003'),
('S093', 'NDLS2', 'New Delhi Extension', 'Z001'),
('S094', 'VSKP', 'Visakhapatnam', 'Z007'),
('S095', 'SC', 'Secunderabad', 'Z002'),
('S096', 'HYD', 'Hyderabad', 'Z005'),
('S097', 'JAT', 'Jammu Tawi Extension', 'Z001'),
('S098', 'BTW', 'Bhatapara', 'Z006'),
('S099', 'CDG2', 'Chandigarh Extension', 'Z001'),
('S100', 'NDLS3', 'Delhi Cantt', 'Z001');
```

#### Insert data into `Class` table

```sql
INSERT INTO Class (Class_id, Class_code, Class_name, Seat_per_coach) VALUES
('C001', '1A', 'First AC', 18),
('C002', '2A', 'Second AC', 46),
('C003', '3A', 'Third AC', 64),
('C004', 'SL', 'Sleeper Class', 72),
('C005', 'CC', 'Chair Car', 78),
('C006', 'EC', 'Executive Chair Car', 56),
('C007', '2S', 'Second Sitting', 108),
('C008', 'GN', 'General', 90),
('C009', 'FC', 'First Class', 22),
('C010', 'EOG', 'End On Generation Car', 0);
```



#### Insert data into `Train` table
```sql
INSERT INTO Train (Train_code, Train_name, Start_time, End_time, Distance, Frequency) VALUES
('12301', 'Rajdhani Express', '16:55:00', '10:00:00', 1447, 'Daily'),
('12302', 'Howrah Rajdhani', '16:10:00', '09:55:00', 1450, 'Daily'),
('12303', 'Poorva Express', '20:40:00', '16:35:00', 1464, 'Daily'),
('12304', 'Poorva Express', '17:45:00', '13:25:00', 1464, 'Daily'),
('12305', 'Howrah Rajdhani', '14:05:00', '12:55:00', 1445, 'Daily'),
('12306', 'Howrah Rajdhani', '19:55:00', '18:40:00', 1445, 'Daily'),
('12307', 'Howrah Jodhpur SF', '23:55:00', '11:45:00', 1802, 'Tue,Fri'),
('12308', 'Jodhpur Howrah SF', '17:30:00', '05:20:00', 1802, 'Thu,Sun'),
('12309', 'Rajdhani Express', '17:00:00', '09:45:00', 1415, 'Daily'),
('12310', 'Rajdhani Express', '16:50:00', '09:50:00', 1415, 'Daily'),
('12311', 'Kalka Mail', '23:05:00', '07:40:00', 1713, 'Daily'),
('12312', 'Kalka Mail', '23:55:00', '07:40:00', 1713, 'Daily'),
('12313', 'Sealdah Rajdhani', '16:30:00', '10:50:00', 1458, 'Daily'),
('12314', 'New Delhi Rajdhani', '16:05:00', '09:30:00', 1458, 'Daily'),
('12315', 'Ananya Express', '20:00:00', '17:50:00', 1652, 'Daily'),
('12316', 'Ananya Express', '17:35:00', '15:30:00', 1652, 'Daily'),
('12317', 'Akal Takht Express', '05:15:00', '23:45:00', 1940, 'Daily'),
('12318', 'Akal Takht Express', '09:30:00', '03:55:00', 1940, 'Daily'),
('12319', 'Kolkata Rajdhani', '16:35:00', '10:00:00', 1367, 'Daily'),
('12320', 'New Delhi Rajdhani', '16:55:00', '10:10:00', 1367, 'Daily'),
('12321', 'Mumbai Howrah Mail', '21:55:00', '07:25:00', 1968, 'Daily'),
('12322', 'Mumbai Mail', '18:20:00', '04:00:00', 1968, 'Daily'),
('12323', 'Koaa Ahmedabad SF', '15:05:00', '05:55:00', 1952, 'Daily'),
('12324', 'Ahmedabad Koaa SF', '12:40:00', '04:30:00', 1952, 'Daily'),
('12325', 'Koaa Nagercoil SF', '09:15:00', '01:10:00', 2079, 'Thu'),
('12326', 'Nagercoil Koaa SF', '10:10:00', '04:05:00', 2079, 'Sat'),
('12327', 'Upasana Express', '17:45:00', '13:00:00', 1609, 'Daily'),
('12328', 'Upasana Express', '16:40:00', '12:10:00', 1609, 'Daily'),
('12329', 'West Bengal Sampark', '12:45:00', '16:25:00', 1456, 'Daily'),
('12330', 'West Bengal Sampark', '14:25:00', '18:20:00', 1456, 'Daily'),
('12331', 'Himgiri Express', '13:50:00', '15:40:00', 1713, 'Daily'),
('12332', 'Himgiri Express', '22:05:00', '01:00:00', 1713, 'Daily'),
('12333', 'Vibhuti Express', '06:15:00', '14:50:00', 632, 'Daily'),
('12334', 'Vibhuti Express', '14:25:00', '22:50:00', 632, 'Daily'),
('12335', 'Bharatpur Express', '05:55:00', '15:40:00', 1010, 'Daily'),
('12336', 'Bharatpur Express', '05:35:00', '15:45:00', 1010, 'Daily'),
('12337', 'Shantiniketan Exp', '09:45:00', '16:10:00', 187, 'Daily'),
('12338', 'Shantiniketan Exp', '12:50:00', '18:45:00', 187, 'Daily'),
('12339', 'Koaa Shaktipunj Exp', '19:55:00', '19:55:00', 1127, 'Daily'),
('12340', 'Shaktipunj Express', '07:30:00', '06:05:00', 1127, 'Daily'),
('12341', 'Agra Cantt Express', '13:19:00', '03:00:00', 1307, 'Daily'),
('12342', 'Agra Cantt Express', '20:50:00', '08:00:00', 1307, 'Daily'),
('12343', 'Darjeeling Mail', '22:05:00', '08:00:00', 555, 'Daily'),
('12344', 'Darjeeling Mail', '20:00:00', '03:45:00', 555, 'Daily'),
('12345', 'Saraighat Express', '13:45:00', '06:00:00', 1046, 'Daily'),
('12346', 'Saraighat Express', '11:45:00', '03:30:00', 1046, 'Daily'),
('12347', 'Rourkela Express', '18:55:00', '06:25:00', 789, 'Daily'),
('12348', 'Rourkela Express', '20:20:00', '06:05:00', 789, 'Daily'),
('12349', 'Koaa Gaya Express', '22:00:00', '07:30:00', 454, 'Daily'),
('12350', 'Gaya Koaa Express', '20:30:00', '05:55:00', 454, 'Daily'),
('12351', 'Danapur Express', '18:20:00', '10:15:00', 1089, 'Daily'),
('12352', 'Danapur Express', '17:40:00', '09:20:00', 1089, 'Daily'),
('12353', 'Howrah Lalkuan Exp', '23:55:00', '04:00:00', 1212, 'Mon,Thu'),
('12354', 'Lalkuan HWH Express', '22:05:00', '05:20:00', 1212, 'Wed,Sat'),
('12355', 'Archana Express', '15:25:00', '05:50:00', 1020, 'Daily'),
('12356', 'Archana Express', '18:45:00', '10:35:00', 1020, 'Daily'),
('12357', 'Durgiana Express', '06:30:00', '14:15:00', 496, 'Daily'),
('12358', 'Durgiana Express', '17:35:00', '00:40:00', 496, 'Daily'),
('12359', 'Kolkata Express', '17:25:00', '09:05:00', 815, 'Daily'),
('12360', 'Patna Kolkata Exp', '20:10:00', '12:05:00', 815, 'Daily'),
('12361', 'Asansol Express', '23:10:00', '06:05:00', 302, 'Daily'),
('12362', 'Asansol Express', '22:25:00', '05:25:00', 302, 'Daily'),
('12363', 'Jamalpur Express', '21:10:00', '07:25:00', 479, 'Daily'),
('12364', 'Jamalpur Express', '21:50:00', '07:25:00', 479, 'Daily'),
('12365', 'Ranchi Shatabdi', '06:10:00', '13:55:00', 419, 'Daily'),
('12366', 'Ranchi Shatabdi', '15:45:00', '22:30:00', 419, 'Daily'),
('12367', 'Vikramshila Express', '16:25:00', '07:25:00', 700, 'Daily'),
('12368', 'Vikramshila Express', '17:40:00', '06:15:00', 700, 'Daily'),
('12369', 'Kumbha Express', '15:25:00', '04:00:00', 795, 'Daily'),
('12370', 'Kumbha Express', '20:00:00', '07:30:00', 795, 'Daily'),
('12371', 'Howrah Jaipur Exp', '23:50:00', '05:45:00', 855, 'Daily'),
('12372', 'Jaipur Howrah Exp', '22:15:00', '04:10:00', 855, 'Daily'),
('12373', 'Sealdah Rajdhani', '16:55:00', '10:40:00', 1529, 'Daily'),
('12374', 'Sealdah Rajdhani', '16:10:00', '10:00:00', 1529, 'Daily'),
('12375', 'Asansol Sealdah Exp', '05:00:00', '09:20:00', 222, 'Daily'),
('12376', 'Asansol Sealdah Exp', '20:25:00', '00:55:00', 222, 'Daily'),
('12377', 'Padatik Express', '23:20:00', '08:05:00', 542, 'Daily'),
('12378', 'Padatik Express', '23:25:00', '09:00:00', 542, 'Daily'),
('12379', 'Sealdah Amritsar Exp', '19:30:00', '17:45:00', 1485, 'Tue,Fri'),
('12380', 'Amritsar Exp', '11:30:00', '09:35:00', 1485, 'Thu,Sun'),
('12381', 'Poorva Express', '09:45:00', '04:55:00', 1147, 'Daily'),
('12382', 'Poorva Express', '20:15:00', '15:30:00', 1147, 'Daily'),
('12383', 'Sealdah Asansol Exp', '17:42:00', '22:05:00', 222, 'Daily'),
('12384', 'Asansol Sealdah Exp', '06:15:00', '10:35:00', 222, 'Daily'),
('12385', 'Howrah Dhanbad Black Diamond Ex', '22:25:00', '04:45:00', 269, 'Daily'),
('12386', 'Dhanbad Howrah Black Diamond Ex', '19:30:00', '01:30:00', 269, 'Daily'),
('12387', 'Howrah Dhanbad Special', '15:25:00', '22:00:00', 269, 'Thu,Sun'),
('12388', 'Dhanbad Howrah Special', '05:30:00', '11:55:00', 269, 'Fri,Mon'),
('12389', 'Gaya Express', '06:20:00', '19:05:00', 683, 'Daily'),
('12390', 'Gaya Express', '11:20:00', '00:45:00', 683, 'Daily'),
('12391', 'Shramjeevi Express', '21:35:00', '08:30:00', 803, 'Daily'),
('12392', 'Shramjeevi Express', '18:40:00', '05:10:00', 803, 'Daily'),
('12393', 'Sampoorna Kranti Ex', '13:05:00', '03:45:00', 1002, 'Daily'),
('12394', 'Sampoorna Kranti Ex', '14:00:00', '05:25:00', 1002, 'Daily'),
('12395', 'Ziyarat Express', '09:20:00', '22:35:00', 821, 'Daily'),
('12396', 'Ziyarat Express', '04:45:00', '18:10:00', 821, 'Daily'),
('12397', 'Mahabodhi Express', '20:10:00', '18:10:00', 1324, 'Daily'),
('12398', 'Mahabodhi Express', '23:25:00', '21:20:00', 1324, 'Daily'),
('12399', 'Magadh Express', '19:20:00', '07:10:00', 1002, 'Daily'),
('12400', 'Magadh Express', '19:35:00', '06:30:00', 1002, 'Daily');
```


##### Insert data into  `Via_details` table
```sql
INSERT INTO Via_details (Train_code, Via_station_code, Via_station_name, Km_from_origin, Reach_time) VALUES
('12301', 'NDLS', 'New Delhi', 0, '16:55:00'),
('12301', 'CNB', 'Kanpur Central', 440, '21:28:00'),
('12301', 'ALD', 'Prayagraj', 633, '23:25:00'),
('12301', 'MGS', 'Mughal Sarai', 801, '01:05:00'),
('12301', 'GAYA', 'Gaya Junction', 997, '03:18:00'),
('12301', 'DHN', 'Dhanbad', 1193, '05:14:00'),
('12301', 'ASN', 'Asansol', 1276, '06:12:00'),
('12301', 'DURG', 'Durgapur', 1306, '06:46:00'),
('12301', 'BWN', 'Barddhaman', 1358, '07:39:00'),
('12301', 'HWH', 'Howrah', 1447, '10:00:00'),
('12302', 'HWH', 'Howrah', 0, '16:10:00'),
('12302', 'BWN', 'Barddhaman', 95, '17:01:00'),
('12302', 'DURG', 'Durgapur', 160, '17:34:00'),
('12302', 'ASN', 'Asansol', 200, '18:02:00'),
('12302', 'DHN', 'Dhanbad', 270, '18:45:00'),
('12302', 'GAYA', 'Gaya Junction', 450, '20:14:00'),
('12302', 'MGS', 'Mughal Sarai', 646, '22:08:00'),
('12302', 'ALD', 'Prayagraj', 814, '23:53:00'),
('12302', 'CNB', 'Kanpur Central', 1010, '01:58:00'),
('12302', 'NDLS', 'New Delhi', 1450, '09:55:00'),
('12303', 'HWH', 'Howrah', 0, '20:40:00'),
('12303', 'BWN', 'Barddhaman', 95, '21:56:00'),
('12303', 'ASN', 'Asansol', 200, '23:22:00'),
('12303', 'DHN', 'Dhanbad', 270, '00:23:00'),
('12303', 'GAYA', 'Gaya Junction', 450, '02:25:00'),
('12303', 'DDU', 'Deen Dayal Upadhyaya', 686, '04:50:00'),
('12303', 'BSB', 'Varanasi', 797, '06:15:00'),
('12303', 'LJN', 'Lucknow', 984, '09:40:00'),
('12303', 'CNB', 'Kanpur Central', 1100, '12:05:00'),
('12303', 'NDLS', 'New Delhi', 1464, '16:35:00'),
('12304', 'NDLS', 'New Delhi', 0, '17:45:00'),
('12304', 'CNB', 'Kanpur Central', 440, '22:05:00'), 
('12304', 'LJN', 'Lucknow', 556, '00:30:00'),
('12304', 'BSB', 'Varanasi', 743, '05:08:00'),
('12304', 'DDU', 'Deen Dayal Upadhyaya', 854, '06:33:00'),
('12304', 'GAYA', 'Gaya Junction', 1014, '08:58:00'),
('12304', 'DHN', 'Dhanbad', 1194, '11:00:00'),
('12304', 'ASN', 'Asansol', 1264, '11:58:00'),
('12304', 'BWN', 'Barddhaman', 1369, '12:56:00'),
('12304', 'HWH', 'Howrah', 1464, '13:25:00'),
('12305', 'HWH', 'Howrah', 0, '14:05:00'),
('12305', 'BWN', 'Barddhaman', 95, '15:03:00'),
('12305', 'ASN', 'Asansol', 200, '16:02:00'),
('12305', 'DHN', 'Dhanbad', 270, '16:56:00'),
('12305', 'GAYA', 'Gaya Junction', 450, '19:00:00'),
('12305', 'MGS', 'Mughal Sarai', 646, '21:18:00'),
('12305', 'ALD', 'Prayagraj', 814, '23:23:00'),
('12305', 'CNB', 'Kanpur Central', 1010, '01:58:00'),
('12305', 'NDLS', 'New Delhi', 1445, '12:55:00'),
('12306', 'NDLS', 'New Delhi', 0, '19:55:00'),
('12306', 'CNB', 'Kanpur Central', 440, '00:33:00'),
('12306', 'ALD', 'Prayagraj', 633, '02:43:00'),
('12306', 'MGS', 'Mughal Sarai', 801, '04:08:00'),
('12306', 'GAYA', 'Gaya Junction', 997, '06:32:00'),
('12306', 'DHN', 'Dhanbad', 1193, '09:22:00'),
('12306', 'ASN', 'Asansol', 1276, '10:33:00'),
('12306', 'BWN', 'Barddhaman', 1358, '11:52:00'),
('12306', 'HWH', 'Howrah', 1445, '18:40:00'),
('12307', 'HWH', 'Howrah', 0, '23:55:00'),
('12307', 'ASN', 'Asansol', 200, '02:33:00'),
('12307', 'GAYA', 'Gaya Junction', 450, '05:35:00'),
('12307', 'DDU', 'Deen Dayal Upadhyaya', 686, '08:22:00'),
('12307', 'BSB', 'Varanasi', 797, '10:05:00'),
('12307', 'LJN', 'Lucknow', 984, '14:25:00'),
('12307', 'MB', 'Moradabad', 1323, '19:38:00'),
('12307', 'INDB', 'Indore', 1582, '05:23:00'),
('12307', 'JP', 'Jaipur', 1705, '09:10:00'),
('12307', 'JU', 'Jodhpur', 1802, '11:45:00'),
('12308', 'JU', 'Jodhpur', 0, '17:30:00'),
('12308', 'JP', 'Jaipur', 97, '20:05:00'),
('12308', 'INDB', 'Indore', 220, '23:52:00'),
('12308', 'MB', 'Moradabad', 479, '09:37:00'),
('12308', 'LJN', 'Lucknow', 818, '14:50:00'),
('12308', 'BSB', 'Varanasi', 1005, '18:30:00'),
('12308', 'DDU', 'Deen Dayal Upadhyaya', 1116, '20:13:00'),
('12308', 'GAYA', 'Gaya Junction', 1352, '23:00:00'),
('12308', 'ASN', 'Asansol', 1602, '01:52:00'),
('12308', 'HWH', 'Howrah', 1802, '05:20:00'),
('12309', 'NDLS', 'New Delhi', 0, '17:00:00'),
('12309', 'CNB', 'Kanpur Central', 440, '21:33:00'),
('12309', 'ALD', 'Prayagraj', 633, '23:30:00'),
('12309', 'MGS', 'Mughal Sarai', 801, '01:10:00'),
('12309', 'GAYA', 'Gaya Junction', 997, '03:23:00'),
('12309', 'DHN', 'Dhanbad', 1193, '05:19:00'),
('12309', 'ASN', 'Asansol', 1276, '06:17:00'),
('12309', 'BWN', 'Barddhaman', 1358, '07:45:00'),
('12309', 'SDAH', 'Sealdah', 1415, '09:45:00'),
('12310', 'SDAH', 'Sealdah', 0, '16:50:00'),
('12310', 'BWN', 'Barddhaman', 57, '17:45:00'),
('12310', 'ASN', 'Asansol', 139, '18:13:00'),
('12310', 'DHN', 'Dhanbad', 222, '18:56:00'),
('12310', 'GAYA', 'Gaya Junction', 418, '20:25:00'),
('12310', 'MGS', 'Mughal Sarai', 614, '22:20:00'),
('12310', 'ALD', 'Prayagraj', 782, '00:05:00'),
('12310', 'CNB', 'Kanpur Central', 975, '02:10:00'),
('12310', 'NDLS', 'New Delhi', 1415, '09:50:00'),
('12311', 'HWH', 'Howrah', 0, '23:05:00'),
('12311', 'BWN', 'Barddhaman', 95, '00:15:00'),
('12311', 'ASN', 'Asansol', 200, '01:40:00'),
('12311', 'DHN', 'Dhanbad', 270, '02:35:00'),
('12311', 'GAYA', 'Gaya Junction', 450, '04:30:00'),
('12311', 'DDU', 'Deen Dayal Upadhyaya', 686, '07:05:00'),
('12311', 'BSB', 'Varanasi', 797, '08:50:00'),
('12311', 'LJN', 'Lucknow', 984, '12:15:00'),
('12311', 'MB', 'Moradabad', 1323, '17:35:00'),
('12311', 'CDG', 'Chandigarh', 1570, '23:30:00'),
('12311', 'KLK', 'Kalka', 1713, '07:40:00'),
('12312', 'KLK', 'Kalka', 0, '23:55:00'),
('12312', 'CDG', 'Chandigarh', 143, '01:05:00'),
('12312', 'MB', 'Moradabad', 390, '07:25:00'),
('12312', 'LJN', 'Lucknow', 729, '12:45:00'),
('12312', 'BSB', 'Varanasi', 916, '16:10:00'),
('12312', 'DDU', 'Deen Dayal Upadhyaya', 1027, '17:45:00'),
('12312', 'GAYA', 'Gaya Junction', 1263, '20:35:00'),
('12312', 'DHN', 'Dhanbad', 1443, '22:40:00'),
('12312', 'ASN', 'Asansol', 1513, '23:38:00'),
('12312', 'BWN', 'Barddhaman', 1618, '00:50:00'),
('12312', 'HWH', 'Howrah', 1713, '07:40:00'),
('12313', 'SDAH', 'Sealdah', 0, '16:30:00'),
('12313', 'BWN', 'Barddhaman', 57, '17:25:00'),
('12313', 'ASN', 'Asansol', 139, '18:04:00'),
('12313', 'DHN', 'Dhanbad', 222, '18:47:00'),
('12313', 'GAYA', 'Gaya Junction', 418, '20:16:00'),
('12313', 'MGS', 'Mughal Sarai', 614, '22:11:00'),
('12313', 'ALD', 'Prayagraj', 782, '23:56:00'),
('12313', 'CNB', 'Kanpur Central', 975, '02:01:00'),
('12313', 'NDLS', 'New Delhi', 1458, '10:50:00'),
('12314', 'NDLS', 'New Delhi', 0, '16:05:00'),
('12314', 'CNB', 'Kanpur Central', 440, '20:38:00'),
('12314', 'ALD', 'Prayagraj', 633, '22:35:00'),
('12314', 'MGS', 'Mughal Sarai', 801, '00:15:00'),
('12314', 'GAYA', 'Gaya Junction', 997, '02:28:00'),
('12314', 'DHN', 'Dhanbad', 1193, '04:24:00'),
('12314', 'ASN', 'Asansol', 1276, '05:22:00'),
('12314', 'BWN', 'Barddhaman', 1358, '06:50:00'),
('12314', 'SDAH', 'Sealdah', 1458, '09:30:00'),
('12315', 'HWH', 'Howrah', 0, '20:00:00'),
('12315', 'BWN', 'Barddhaman', 95, '21:15:00'),
('12315', 'ASN', 'Asansol', 200, '22:40:00'),
('12315', 'DHN', 'Dhanbad', 270, '23:40:00'),
('12315', 'GAYA', 'Gaya Junction', 450, '01:40:00'),
('12315', 'DDU', 'Deen Dayal Upadhyaya', 686, '04:15:00'),
('12315', 'BSB', 'Varanasi', 797, '05:55:00'),
('12315', 'GKP', 'Gorakhpur', 1027, '09:35:00'),
('12315', 'ASR', 'Amritsar', 1652, '17:50:00'),
('12316', 'ASR', 'Amritsar', 0, '17:35:00'),
('12316', 'GKP', 'Gorakhpur', 625, '01:50:00'),
('12316', 'BSB', 'Varanasi', 855, '05:30:00'),
('12316', 'DDU', 'Deen Dayal Upadhyaya', 966, '07:05:00'),
('12316', 'GAYA', 'Gaya Junction', 1202, '09:55:00'),
('12316', 'DHN', 'Dhanbad', 1382, '12:00:00'),
('12316', 'ASN', 'Asansol', 1452, '12:58:00'),
('12316', 'BWN', 'Barddhaman', 1557, '14:10:00'),
('12316', 'HWH', 'Howrah', 1652, '15:30:00'),
('12317', 'ASN', 'Asansol', 0, '05:15:00'),
('12317', 'DHN', 'Dhanbad', 70, '06:10:00'),
('12317', 'GAYA', 'Gaya Junction', 250, '08:15:00'),
('12317', 'MGS', 'Mughal Sarai', 446, '10:55:00'),
('12317', 'BSB', 'Varanasi', 557, '12:30:00'),
('12317', 'LJN', 'Lucknow', 744, '16:15:00'),
('12317', 'MB', 'Moradabad', 1083, '20:40:00'),
('12317', 'CDG', 'Chandigarh', 1330, '01:10:00'),
('12317', 'ASR', 'Amritsar', 1940, '23:45:00'),
('12318', 'ASR', 'Amritsar', 0, '09:30:00'),
('12318', 'CDG', 'Chandigarh', 610, '13:05:00'),
('12318', 'MB', 'Moradabad', 857, '17:35:00'),
('12318', 'LJN', 'Lucknow', 1196, '21:50:00'),
('12318', 'BSB', 'Varanasi', 1383, '01:25:00'),
('12318', 'MGS', 'Mughal Sarai', 1494, '03:00:00'),
('12318', 'GAYA', 'Gaya Junction', 1690, '05:35:00'),
('12318', 'DHN', 'Dhanbad', 1870, '07:40:00'),
('12318', 'ASN', 'Asansol', 1940, '08:38:00'),
('12319', 'KOAA', 'Kolkata', 0, '16:35:00'),
('12319', 'BWN', 'Barddhaman', 107, '17:38:00'),
('12319', 'ASN', 'Asansol', 203, '18:43:00'),
('12319', 'DHN', 'Dhanbad', 267, '19:32:00'),
('12319', 'GAYA', 'Gaya Junction', 459, '21:15:00'),
('12319', 'MGS', 'Mughal Sarai', 645, '23:10:00'),
('12319', 'ALD', 'Prayagraj', 792, '00:50:00'),
('12319', 'CNB', 'Kanpur Central', 994, '03:00:00'),
('12319', 'NDLS', 'New Delhi', 1367, '10:00:00'),
('12320', 'NDLS', 'New Delhi', 0, '16:55:00'),
('12320', 'CNB', 'Kanpur Central', 440, '21:28:00'),
('12320', 'ALD', 'Prayagraj', 642, '23:25:00'),
('12320', 'MGS', 'Mughal Sarai', 787, '01:05:00'),
('12320', 'GAYA', 'Gaya Junction', 973, '03:18:00'),
('12320', 'DHN', 'Dhanbad', 1165, '05:10:00'),
('12320', 'ASN', 'Asansol', 1229, '06:00:00'),
('12320', 'BWN', 'Barddhaman', 1325, '07:05:00'),
('12320', 'KOAA', 'Kolkata', 1367, '10:10:00'),
('12321', 'CSMT', 'Mumbai CSMT', 0, '21:55:00'),
('12321', 'NGP', 'Nagpur', 837, '08:35:00'),
('12321', 'BPL', 'Bhopal', 1188, '14:40:00'),
('12321', 'BSB', 'Varanasi', 1659, '23:55:00'),
('12321', 'MGS', 'Mughal Sarai', 1770, '01:30:00'),
('12321', 'GAYA', 'Gaya Junction', 1966, '04:05:00'),
('12321', 'DHN', 'Dhanbad', 2146, '06:10:00'),
('12321', 'ASN', 'Asansol', 2216, '07:08:00'),
('12321', 'HWH', 'Howrah', 2411, '09:25:00'),
('12322', 'HWH', 'Howrah', 0, '18:20:00'),
('12322', 'ASN', 'Asansol', 195, '20:50:00'),
('12322', 'DHN', 'Dhanbad', 265, '21:45:00'),
('12322', 'GAYA', 'Gaya Junction', 445, '23:45:00'),
('12322', 'MGS', 'Mughal Sarai', 641, '02:15:00'),
('12322', 'BSB', 'Varanasi', 752, '03:50:00'),
('12322', 'BPL', 'Bhopal', 1223, '13:05:00'),
('12322', 'NGP', 'Nagpur', 1574, '19:10:00'),
('12322', 'CSMT', 'Mumbai CSMT', 2411, '04:00:00'),
('12323', 'KOAA', 'Kolkata', 0, '15:05:00'),
('12323', 'BWN', 'Barddhaman', 107, '16:10:00'),
('12323', 'ASN', 'Asansol', 203, '17:15:00'),
('12323', 'DHN', 'Dhanbad', 273, '18:05:00'),
('12323', 'GAYA', 'Gaya Junction', 450, '20:05:00'),
('12323', 'MGS', 'Mughal Sarai', 646, '22:05:00'),
('12323', 'BSB', 'Varanasi', 757, '23:40:00'),
('12323', 'CNB', 'Kanpur Central', 1037, '03:05:00'),
('12323', 'NDLS', 'New Delhi', 1477, '07:45:00'),
('12323', 'JP', 'Jaipur', 1732, '12:15:00'),
('12323', 'ADI', 'Ahmedabad', 1952, '18:55:00'),
('12324', 'ADI', 'Ahmedabad', 0, '12:40:00'),
('12324', 'JP', 'Jaipur', 220, '19:20:00'),
('12324', 'NDLS', 'New Delhi', 475, '23:50:00'),
('12324', 'CNB', 'Kanpur Central', 915, '04:30:00'),
('12324', 'BSB', 'Varanasi', 1195, '08:00:00'),
('12324', 'MGS', 'Mughal Sarai', 1306, '09:35:00'),
('12324', 'GAYA', 'Gaya Junction', 1502, '11:35:00'),
('12324', 'DHN', 'Dhanbad', 1679, '13:35:00'),
('12324', 'ASN', 'Asansol', 1749, '14:33:00'),
('12324', 'BWN', 'Barddhaman', 1845, '15:35:00'),
('12324', 'KOAA', 'Kolkata', 1952, '17:30:00'),
('12325', 'KOAA', 'Kolkata', 0, '09:15:00'),
('12325', 'BWN', 'Barddhaman', 107, '10:18:00'),
('12325', 'ASN', 'Asansol', 203, '11:23:00'),
('12325', 'DHN', 'Dhanbad', 273, '12:12:00'),
('12325', 'GAYA', 'Gaya Junction', 464, '13:55:00'),
('12325', 'MGS', 'Mughal Sarai', 650, '15:50:00'),
('12325', 'BSB', 'Varanasi', 761, '17:25:00'),
('12325', 'LJN', 'Lucknow', 948, '20:50:00'),
('12325', 'NDLS', 'New Delhi', 1436, '04:10:00'),
('12325', 'MAS', 'Chennai Central', 1782, '20:55:00'),
('12325', 'NCJ', 'Nagercoil Junction', 2079, '01:10:00'),
('12326', 'NCJ', 'Nagercoil Junction', 0, '10:10:00'),
('12326', 'MAS', 'Chennai Central', 297, '14:25:00'),
('12326', 'NDLS', 'New Delhi', 643, '07:10:00'),
('12326', 'LJN', 'Lucknow', 1131, '14:40:00'),
('12326', 'BSB', 'Varanasi', 1318, '18:15:00'),
('12326', 'MGS', 'Mughal Sarai', 1429, '19:45:00'),
('12326', 'GAYA', 'Gaya Junction', 1615, '21:45:00'),
('12326', 'DHN', 'Dhanbad', 1806, '23:40:00'),
('12326', 'ASN', 'Asansol', 1876, '00:38:00'),
('12326', 'BWN', 'Barddhaman', 1972, '01:40:00'),
('12326', 'KOAA', 'Kolkata', 2079, '04:05:00'),
('12327', 'SDAH', 'Sealdah', 0, '17:45:00'),
('12327', 'BWN', 'Barddhaman', 107, '18:48:00'),
('12327', 'ASN', 'Asansol', 203, '19:53:00'),
('12327', 'DHN', 'Dhanbad', 273, '20:42:00'),
('12327', 'GAYA', 'Gaya Junction', 464, '22:25:00'),
('12327', 'MGS', 'Mughal Sarai', 650, '00:20:00'),
('12327', 'BSB', 'Varanasi', 761, '01:55:00'),
('12327', 'GKP', 'Gorakhpur', 991, '05:35:00'),
('12327', 'RXL', 'Raxaul Junction', 1609, '13:00:00'),
('12328', 'RXL', 'Raxaul Junction', 0, '16:40:00'),
('12328', 'GKP', 'Gorakhpur', 618, '00:05:00'),
('12328', 'BSB', 'Varanasi', 848, '03:40:00'),
('12328', 'MGS', 'Mughal Sarai', 959, '05:15:00'),
('12328', 'GAYA', 'Gaya Junction', 1145, '07:15:00'),
('12328', 'DHN', 'Dhanbad', 1336, '09:10:00'),
('12328', 'ASN', 'Asansol', 1406, '10:08:00'),
('12328', 'BWN', 'Barddhaman', 1502, '11:10:00'),
('12328', 'SDAH', 'Sealdah', 1609, '12:10:00'),
('12329', 'SDAH', 'Sealdah', 0, '12:45:00'),
('12329', 'BWN', 'Barddhaman', 107, '13:48:00'),
('12329', 'ASN', 'Asansol', 203, '14:53:00'),
('12329', 'DHN', 'Dhanbad', 273, '15:42:00'),
('12329', 'GAYA', 'Gaya Junction', 464, '17:25:00'),
('12329', 'MGS', 'Mughal Sarai', 650, '19:20:00'),
('12329', 'ALD', 'Prayagraj', 818, '21:05:00'),
('12329', 'CNB', 'Kanpur Central', 1014, '23:15:00'),
('12329', 'NDLS', 'New Delhi', 1456, '16:25:00'),
('12330', 'NDLS', 'New Delhi', 0, '14:25:00'),
('12330', 'CNB', 'Kanpur Central', 440, '18:58:00'),
('12330', 'ALD', 'Prayagraj', 642, '20:55:00'),
('12330', 'MGS', 'Mughal Sarai', 806, '22:35:00'),
('12330', 'GAYA', 'Gaya Junction', 992, '00:35:00'),
('12330', 'DHN', 'Dhanbad', 1183, '02:32:00'),
('12330', 'ASN', 'Asansol', 1253, '03:30:00'),
('12330', 'BWN', 'Barddhaman', 1349, '04:32:00'),
('12330', 'SDAH', 'Sealdah', 1456, '18:20:00'),
('12331', 'HWH', 'Howrah', 0, '13:50:00'),
('12331', 'BWN', 'Barddhaman', 95, '15:00:00'),
('12331', 'ASN', 'Asansol', 200, '16:25:00'),
('12331', 'DHN', 'Dhanbad', 270, '17:25:00'),
('12331', 'GAYA', 'Gaya Junction', 450, '19:25:00'),
('12331', 'DDU', 'Deen Dayal Upadhyaya', 686, '22:00:00'),
('12331', 'BSB', 'Varanasi', 797, '23:45:00'),
('12331', 'LJN', 'Lucknow', 984, '03:10:00'),
('12331', 'MB', 'Moradabad', 1323, '08:30:00'),
('12331', 'JUC', 'Jammu', 1713, '15:40:00'),
('12332', 'JUC', 'Jammu', 0, '22:05:00'),
('12332', 'MB', 'Moradabad', 390, '05:05:00'),
('12332', 'LJN', 'Lucknow', 729, '10:25:00'),
('12332', 'BSB', 'Varanasi', 916, '13:50:00'),
('12332', 'DDU', 'Deen Dayal Upadhyaya', 1027, '15:25:00'),
('12332', 'GAYA', 'Gaya Junction', 1263, '18:15:00'),
('12332', 'DHN', 'Dhanbad', 1443, '20:20:00'),
('12332', 'ASN', 'Asansol', 1513, '21:18:00'),
('12332', 'BWN', 'Barddhaman', 1618, '22:30:00'),
('12332', 'HWH', 'Howrah', 1713, '01:00:00'),
('12333', 'HWH', 'Howrah', 0, '06:15:00'),
('12333', 'BWN', 'Barddhaman', 95, '07:25:00'),
('12333', 'ASN', 'Asansol', 200, '08:50:00'),
('12333', 'CRJ', 'Chittaranjan', 237, '09:14:00'),
('12333', 'DHN', 'Dhanbad', 270, '09:40:00'),
('12333', 'GAYA', 'Gaya Junction', 450, '11:40:00'),
('12333', 'ALD', 'Prayagraj', 632, '14:50:00'),
('12334', 'ALD', 'Prayagraj', 0, '14:25:00'),
('12334', 'GAYA', 'Gaya Junction', 182, '17:35:00'),
('12334', 'DHN', 'Dhanbad', 362, '19:40:00'),
('12334', 'CRJ', 'Chittaranjan', 395, '20:06:00'),
('12334', 'ASN', 'Asansol', 432, '20:30:00'),
('12334', 'BWN', 'Barddhaman', 537, '21:40:00'),
('12334', 'HWH', 'Howrah', 632, '22:50:00'),
('12335', 'HWH', 'Howrah', 0, '05:55:00'),
('12335', 'BWN', 'Barddhaman', 95, '07:05:00'),
('12335', 'ASN', 'Asansol', 200, '08:30:00'),
('12335', 'DHN', 'Dhanbad', 270, '09:30:00'),
('12335', 'GAYA', 'Gaya Junction', 450, '11:30:00'),
('12335', 'MGS', 'Mughal Sarai', 646, '13:35:00'),
('12335', 'CNB', 'Kanpur Central', 1010, '15:40:00'),
('12336', 'CNB', 'Kanpur Central', 0, '05:35:00'),
('12336', 'MGS', 'Mughal Sarai', 364, '07:40:00'),
('12336', 'GAYA', 'Gaya Junction', 560, '09:45:00'),
('12336', 'DHN', 'Dhanbad', 740, '11:50:00'),
('12336', 'ASN', 'Asansol', 810, '12:48:00'),
('12336', 'BWN', 'Barddhaman', 915, '13:50:00'),
('12336', 'HWH', 'Howrah', 1010, '15:45:00'),
('12337', 'HWH', 'Howrah', 0, '09:45:00'),
('12337', 'BWN', 'Barddhaman', 95, '10:55:00'),
('12337', 'BKSC', 'Bokaro Steel City', 187, '16:10:00'),
('12338', 'BKSC', 'Bokaro Steel City', 0, '12:50:00'),
('12338', 'BWN', 'Barddhaman', 92, '17:35:00'),
('12338', 'HWH', 'Howrah', 187, '18:45:00'),
('12339', 'HWH', 'Howrah', 0, '19:55:00'),
('12339', 'BWN', 'Barddhaman', 95, '21:05:00'),
('12339', 'ASN', 'Asansol', 200, '22:30:00'),
('12339', 'DHN', 'Dhanbad', 270, '23:30:00'),
('12339', 'GAYA', 'Gaya Junction', 450, '01:30:00'),
('12339', 'DDU', 'Deen Dayal Upadhyaya', 686, '04:05:00'),
('12339', 'STN', 'Satna', 1127, '19:55:00'),
('12340', 'STN', 'Satna', 0, '07:30:00'),
('12340', 'DDU', 'Deen Dayal Upadhyaya', 441, '13:20:00'),
('12340', 'GAYA', 'Gaya Junction', 677, '16:10:00'),
('12340', 'DHN', 'Dhanbad', 857, '18:15:00'),
('12340', 'ASN', 'Asansol', 927, '19:13:00'),
('12340', 'BWN', 'Barddhaman', 1032, '20:15:00'),
('12340', 'HWH', 'Howrah', 1127, '21:40:00'),
('12341', 'HWH', 'Howrah', 0, '13:19:00'),
('12341', 'BWN', 'Barddhaman', 95, '14:29:00'),
('12341', 'ASN', 'Asansol', 200, '15:54:00'),
('12341', 'DHN', 'Dhanbad', 270, '16:54:00'),
('12341', 'GAYA', 'Gaya Junction', 450, '18:54:00'),
('12341', 'DDU', 'Deen Dayal Upadhyaya', 686, '21:29:00'),
('12341', 'CNB', 'Kanpur Central', 1010, '01:04:00'),
('12341', 'AGC', 'Agra Cantt', 1307, '03:05:00'),
('12342', 'AGC', 'Agra Cantt', 0, '20:50:00'),
('12342', 'CNB', 'Kanpur Central', 297, '22:55:00'),
('12342', 'DDU', 'Deen Dayal Upadhyaya', 621, '02:30:00'),
('12342', 'GAYA', 'Gaya Junction', 857, '05:05:00'),
('12342', 'DHN', 'Dhanbad', 1037, '07:05:00'),
('12342', 'ASN', 'Asansol', 1107, '08:03:00'),
('12342', 'BWN', 'Barddhaman', 1212, '09:05:00'),
('12342', 'HWH', 'Howrah', 1307, '10:15:00'),
('12343', 'HWH', 'Howrah', 0, '22:05:00'),
('12343', 'BWN', 'Barddhaman', 95, '23:10:00'),
('12343', 'ASN', 'Asansol', 200, '00:30:00'),
('12343', 'NJP', 'New Jalpaiguri', 555, '08:00:00'),
('12344', 'NJP', 'New Jalpaiguri', 0, '20:00:00'),
('12344', 'ASN', 'Asansol', 355, '03:25:00'),
('12344', 'BWN', 'Barddhaman', 460, '04:25:00'),
('12344', 'HWH', 'Howrah', 555, '05:35:00'),
('12345', 'HWH', 'Howrah', 0, '13:45:00'),
('12345', 'BWN', 'Barddhaman', 95, '14:55:00'),
('12345', 'ASN', 'Asansol', 200, '16:20:00'),
('12345', 'DHN', 'Dhanbad', 270, '17:20:00'),
('12345', 'GAYA', 'Gaya Junction', 450, '19:20:00'),
('12345', 'PNBE', 'Patna Junction', 600, '21:15:00'),
('12345', 'MFP', 'Muzaffarpur', 800, '23:30:00'),
('12345', 'GLPT', 'Goalpara Town', 1046, '06:00:00'),
('12346', 'GLPT', 'Goalpara Town', 0, '11:45:00'),
('12346', 'MFP', 'Muzaffarpur', 246, '14:30:00'),
('12346', 'PNBE', 'Patna Junction', 446, '17:15:00'),
('12346', 'GAYA', 'Gaya Junction', 596, '19:10:00'),
('12346', 'DHN', 'Dhanbad', 776, '21:15:00'),
('12346', 'ASN', 'Asansol', 846, '22:13:00'),
('12346', 'BWN', 'Barddhaman', 951, '23:15:00'),
('12346', 'HWH', 'Howrah', 1046, '03:30:00'),
('12347', 'HWH', 'Howrah', 0, '18:55:00'),
('12347', 'BWN', 'Barddhaman', 95, '20:05:00'),
('12347', 'ASN', 'Asansol', 200, '21:30:00'),
('12347', 'RNC', 'Ranchi', 500, '02:30:00'),
('12347', 'ROU', 'Rourkela', 789, '06:25:00'),
('12348', 'ROU', 'Rourkela', 0, '20:20:00'),
('12348', 'RNC', 'Ranchi', 289, '00:15:00'),
('12348', 'ASN', 'Asansol', 589, '05:15:00'),
('12348', 'BWN', 'Barddhaman', 694, '06:17:00'),
('12348', 'HWH', 'Howrah', 789, '06:05:00'),
('12349', 'KOAA', 'Kolkata', 0, '22:00:00'),
('12349', 'BWN', 'Barddhaman', 107, '23:05:00'),
('12349', 'ASN', 'Asansol', 203, '00:10:00'),
('12349', 'GAYA', 'Gaya Junction', 454, '07:30:00'),
('12350', 'GAYA', 'Gaya Junction', 0, '20:30:00'),
('12350', 'ASN', 'Asansol', 251, '02:55:00'),
('12350', 'BWN', 'Barddhaman', 357, '04:00:00'),
('12350', 'KOAA', 'Kolkata', 454, '05:55:00'),
('12351', 'HWH', 'Howrah', 0, '18:20:00'),
('12351', 'BWN', 'Barddhaman', 95, '19:30:00'),
('12351', 'ASN', 'Asansol', 200, '20:55:00'),
('12351', 'DHN', 'Dhanbad', 270, '21:55:00'),
('12351', 'GAYA', 'Gaya Junction', 450, '23:55:00'),
('12351', 'PNBE', 'Patna Junction', 600, '01:50:00'),
('12351', 'DNR', 'Danapur', 1089, '10:15:00'),
('12352', 'DNR', 'Danapur', 0, '17:40:00'),
('12352', 'PNBE', 'Patna Junction', 489, '18:30:00'),
('12352', 'GAYA', 'Gaya Junction', 639, '20:25:00'),
('12352', 'DHN', 'Dhanbad', 819, '22:30:00'),
('12352', 'ASN', 'Asansol', 889, '23:28:00'),
('12352', 'BWN', 'Barddhaman', 994, '00:30:00'),
('12352', 'HWH', 'Howrah', 1089, '09:20:00'),
('12353', 'HWH', 'Howrah', 0, '23:55:00'),
('12353', 'BWN', 'Barddhaman', 95, '01:05:00'),
('12353', 'ASN', 'Asansol', 200, '02:30:00'),
('12353', 'DHN', 'Dhanbad', 270, '03:30:00'),
('12353', 'GAYA', 'Gaya Junction', 450, '05:30:00'),
('12353', 'DDU', 'Deen Dayal Upadhyaya', 686, '08:05:00'),
('12353', 'LKU', 'Lalkuan', 1212, '04:00:00'),
('12354', 'LKU', 'Lalkuan', 0, '22:05:00'),
('12354', 'DDU', 'Deen Dayal Upadhyaya', 526, '02:30:00'),
('12354', 'GAYA', 'Gaya Junction', 762, '05:15:00'),
('12354', 'DHN', 'Dhanbad', 942, '07:20:00'),
('12354', 'ASN', 'Asansol', 1012, '08:18:00'),
('12354', 'BWN', 'Barddhaman', 1117, '09:20:00'),
('12354', 'HWH', 'Howrah', 1212, '05:20:00'),
('12355', 'HWH', 'Howrah', 0, '15:25:00'),
('12355', 'BWN', 'Barddhaman', 95, '16:35:00'),
('12355', 'ASN', 'Asansol', 200, '18:00:00'),
('12355', 'DHN', 'Dhanbad', 270, '19:00:00'),
('12355', 'GAYA', 'Gaya Junction', 450, '21:00:00'),
('12355', 'DDU', 'Deen Dayal Upadhyaya', 686, '23:35:00'),
('12355', 'JMP', 'Jamalpur', 1020, '05:50:00'),
('12356', 'JMP', 'Jamalpur', 0, '18:45:00'),
('12356', 'DDU', 'Deen Dayal Upadhyaya', 334, '22:30:00'),
('12356', 'GAYA', 'Gaya Junction', 570, '01:15:00'),
('12356', 'DHN', 'Dhanbad', 750, '03:20:00'),
('12356', 'ASN', 'Asansol', 820, '04:18:00'),
('12356', 'BWN', 'Barddhaman', 925, '05:20:00'),
('12356', 'HWH', 'Howrah', 1020, '10:35:00'),
('12357', 'HWH', 'Howrah', 0, '06:30:00'),
('12357', 'BWN', 'Barddhaman', 95, '07:40:00'),
('12357', 'ASN', 'Asansol', 200, '09:05:00'),
('12357', 'DHN', 'Dhanbad', 270, '10:05:00'),
('12357', 'GAYA', 'Gaya Junction', 450, '12:05:00'),
('12357', 'DURG', 'Durg', 496, '14:15:00'),
('12358', 'DURG', 'Durg', 0, '17:35:00'),
('12358', 'GAYA', 'Gaya Junction', 46, '19:45:00'),
('12358', 'DHN', 'Dhanbad', 226, '21:50:00'),
('12358', 'ASN', 'Asansol', 296, '22:48:00'),
('12358', 'BWN', 'Barddhaman', 401, '23:50:00'),
('12358', 'HWH', 'Howrah', 496, '00:40:00'),
('12359', 'HWH', 'Howrah', 0, '17:25:00'),
('12359', 'BWN', 'Barddhaman', 95, '18:35:00'),
('12359', 'ASN', 'Asansol', 200, '20:00:00'),
('12359', 'PNBE', 'Patna Junction', 815, '09:05:00'),
('12360', 'PNBE', 'Patna Junction', 0, '20:10:00'),
('12360', 'ASN', 'Asansol', 615, '06:05:00'),
('12360', 'BWN', 'Barddhaman', 720, '07:07:00'),
('12360', 'HWH', 'Howrah', 815, '12:05:00'),
('12361', 'HWH', 'Howrah', 0, '23:10:00'),
('12361', 'BWN', 'Barddhaman', 95, '00:20:00'),
('12361', 'ASN', 'Asansol', 302, '06:05:00'),
('12362', 'ASN', 'Asansol', 0, '22:25:00'),
('12362', 'BWN', 'Barddhaman', 107, '23:30:00'),
('12362', 'HWH', 'Howrah', 302, '05:25:00'),
('12363', 'HWH', 'Howrah', 0, '21:10:00'),
('12363', 'BWN', 'Barddhaman', 95, '22:20:00'),
('12363', 'ASN', 'Asansol', 200, '23:45:00'),
('12363', 'JMP', 'Jamalpur', 479, '07:25:00'),
('12364', 'JMP', 'Jamalpur', 0, '21:50:00'),
('12364', 'ASN', 'Asansol', 279, '04:05:00'),
('12364', 'BWN', 'Barddhaman', 384, '05:07:00'),
('12364', 'HWH', 'Howrah', 479, '07:25:00'),
('12365', 'HWH', 'Howrah', 0, '06:10:00'),
('12365', 'BWN', 'Barddhaman', 95, '07:20:00'),
('12365', 'ASN', 'Asansol', 200, '08:45:00'),
('12365', 'RNC', 'Ranchi', 419, '13:55:00'),
('12366', 'RNC', 'Ranchi', 0, '15:45:00'),
('12366', 'ASN', 'Asansol', 219, '20:30:00'),
('12366', 'BWN', 'Barddhaman', 324, '21:32:00'),
('12366', 'HWH', 'Howrah', 419, '22:30:00'),
('12367', 'HWH', 'Howrah', 0, '16:25:00'),
('12367', 'BWN', 'Barddhaman', 95, '17:35:00'),
('12367', 'ASN', 'Asansol', 200, '19:00:00'),
('12367', 'DHN', 'Dhanbad', 270, '20:00:00'),
('12367', 'GAYA', 'Gaya Junction', 450, '22:00:00'),
('12367', 'BGP', 'Bhagalpur', 700, '07:25:00'),
('12368', 'BGP', 'Bhagalpur', 0, '17:40:00'),
('12368', 'GAYA', 'Gaya Junction', 250, '21:15:00'),
('12368', 'DHN', 'Dhanbad', 430, '23:20:00'),
('12368', 'ASN', 'Asansol', 500, '00:18:00'),
('12368', 'BWN', 'Barddhaman', 605, '01:20:00'),
('12368', 'HWH', 'Howrah', 700, '06:15:00'),
('12369', 'HWH', 'Howrah', 0, '15:25:00'),
('12369', 'BWN', 'Barddhaman', 95, '16:35:00'),
('12369', 'ASN', 'Asansol', 200, '18:00:00'),
('12369', 'DHN', 'Dhanbad', 270, '19:00:00'),
('12369', 'GAYA', 'Gaya Junction', 450, '21:00:00'),
('12369', 'PRYJ', 'Prayagraj', 795, '04:00:00'),
('12370', 'PRYJ', 'Prayagraj', 0, '20:00:00'),
('12370', 'GAYA', 'Gaya Junction', 345, '23:45:00'),
('12370', 'DHN', 'Dhanbad', 525, '01:50:00'),
('12370', 'ASN', 'Asansol', 595, '02:48:00'),
('12370', 'BWN', 'Barddhaman', 700, '03:50:00'),
('12370', 'HWH', 'Howrah', 795, '07:30:00'),
('12371', 'HWH', 'Howrah', 0, '23:50:00'),
('12371', 'BWN', 'Barddhaman', 95, '01:00:00'),
('12371', 'ASN', 'Asansol', 200, '02:25:00'),
('12371', 'DHN', 'Dhanbad', 270, '03:25:00'),
('12371', 'GAYA', 'Gaya Junction', 450, '05:25:00'),
('12371', 'DDU', 'Deen Dayal Upadhyaya', 686, '08:00:00'),
('12371', 'JP', 'Jaipur', 855, '05:45:00'),
('12372', 'JP', 'Jaipur', 0, '22:15:00'),
('12372', 'DDU', 'Deen Dayal Upadhyaya', 169, '02:30:00'),
('12372', 'GAYA', 'Gaya Junction', 405, '05:15:00'),
('12372', 'DHN', 'Dhanbad', 585, '07:20:00'),
('12372', 'ASN', 'Asansol', 655, '08:18:00'),
('12372', 'BWN', 'Barddhaman', 760, '09:20:00'),
('12372', 'HWH', 'Howrah', 855, '04:10:00'),
('12373', 'SDAH', 'Sealdah', 0, '16:55:00'),
('12373', 'BWN', 'Barddhaman', 107, '17:58:00'),
('12373', 'ASN', 'Asansol', 203, '19:03:00'),
('12373', 'DHN', 'Dhanbad', 273, '19:52:00'),
('12373', 'GAYA', 'Gaya Junction', 464, '21:35:00'),
('12373', 'MGS', 'Mughal Sarai', 650, '23:30:00'),
('12373', 'ALD', 'Prayagraj', 818, '01:15:00'),
('12373', 'CNB', 'Kanpur Central', 1014, '03:25:00'),
('12373', 'NDLS', 'New Delhi', 1529, '10:40:00'),
('12374', 'NDLS', 'New Delhi', 0, '16:10:00'),
('12374', 'CNB', 'Kanpur Central', 440, '20:43:00'),
('12374', 'ALD', 'Prayagraj', 642, '22:40:00'),
('12374', 'MGS', 'Mughal Sarai', 806, '00:20:00'),
('12374', 'GAYA', 'Gaya Junction', 992, '02:20:00'),
('12374', 'DHN', 'Dhanbad', 1183, '04:25:00'),
('12374', 'ASN', 'Asansol', 1253, '05:23:00'),
('12374', 'BWN', 'Barddhaman', 1349, '06:25:00'),
('12374', 'SDAH', 'Sealdah', 1529, '10:00:00'),
('12375', 'ASN', 'Asansol', 0, '05:00:00'),
('12375', 'BWN', 'Barddhaman', 105, '06:02:00'),
('12375', 'SDAH', 'Sealdah', 222, '09:20:00'),
('12376', 'SDAH', 'Sealdah', 0, '20:25:00'),
('12376', 'BWN', 'Barddhaman', 117, '21:28:00'),
('12376', 'ASN', 'Asansol', 222, '00:55:00'),
('12377', 'SDAH', 'Sealdah', 0, '23:20:00'),
('12377', 'BWN', 'Barddhaman', 107, '00:23:00'),
('12377', 'ASN', 'Asansol', 203, '01:28:00'),
('12377', 'DHN', 'Dhanbad', 273, '02:18:00'),
('12377', 'GAYA', 'Gaya Junction', 464, '04:00:00'),
('12377', 'PRYJ', 'Prayagraj', 542, '08:05:00'),
('12378', 'PRYJ', 'Prayagraj', 0, '23:25:00'),
('12378', 'GAYA', 'Gaya Junction', 78, '02:30:00'),
('12378', 'DHN', 'Dhanbad', 258, '04:35:00'),
('12378', 'ASN', 'Asansol', 328, '05:33:00'),
('12378', 'BWN', 'Barddhaman', 433, '06:35:00'),
('12378', 'SDAH', 'Sealdah', 542, '09:00:00'),
('12379', 'SDAH', 'Sealdah', 0, '19:30:00'),
('12379', 'BWN', 'Barddhaman', 107, '20:33:00'),
('12379', 'ASN', 'Asansol', 203, '21:38:00'),
('12379', 'DHN', 'Dhanbad', 273, '22:27:00'),
('12379', 'GAYA', 'Gaya Junction', 464, '00:10:00'),
('12379', 'DDU', 'Deen Dayal Upadhyaya', 650, '02:45:00'),
('12379', 'CNB', 'Kanpur Central', 1014, '06:10:00'),
('12379', 'NDLS', 'New Delhi', 1454, '12:25:00'),
('12379', 'ASR', 'Amritsar', 1485, '17:45:00'),
('12380', 'ASR', 'Amritsar', 0, '11:30:00'),
('12380', 'NDLS', 'New Delhi', 31, '15:45:00'),
('12380', 'CNB', 'Kanpur Central', 471, '20:18:00'),
('12380', 'DDU', 'Deen Dayal Upadhyaya', 835, '23:43:00'),
('12380', 'GAYA', 'Gaya Junction', 1021, '02:18:00'),
('12380', 'DHN', 'Dhanbad', 1212, '04:23:00'),
('12380', 'ASN', 'Asansol', 1282, '05:21:00'),
('12380', 'BWN', 'Barddhaman', 1387, '06:23:00'),
('12380', 'SDAH', 'Sealdah', 1485, '09:35:00'),
('12381', 'HWH', 'Howrah', 0, '09:45:00'),
('12381', 'BWN', 'Barddhaman', 95, '10:55:00'),
('12381', 'ASN', 'Asansol', 200, '12:20:00'),
('12381', 'DHN', 'Dhanbad', 270, '13:20:00'),
('12381', 'GAYA', 'Gaya Junction', 450, '15:20:00'),
('12381', 'DDU', 'Deen Dayal Upadhyaya', 686, '17:55:00'),
('12381', 'CNB', 'Kanpur Central', 1147, '04:55:00'),
('12382', 'CNB', 'Kanpur Central', 0, '20:15:00'),
('12382', 'DDU', 'Deen Dayal Upadhyaya', 461, '23:40:00'),
('12382', 'GAYA', 'Gaya Junction', 697, '02:25:00'),
('12382', 'DHN', 'Dhanbad', 877, '04:30:00'),
('12382', 'ASN', 'Asansol', 947, '05:28:00'),
('12382', 'BWN', 'Barddhaman', 1052, '06:30:00'),
('12382', 'HWH', 'Howrah', 1147, '15:30:00'),
('12383', 'SDAH', 'Sealdah', 0, '17:42:00'),
('12383', 'BWN', 'Barddhaman', 107, '18:45:00'),
('12383', 'ASN', 'Asansol', 222, '22:05:00'),
('12384', 'ASN', 'Asansol', 0, '06:15:00'),
('12384', 'BWN', 'Barddhaman', 117, '07:18:00'),
('12384', 'SDAH', 'Sealdah', 222, '10:35:00'),
('12385', 'HWH', 'Howrah', 0, '22:25:00'),
('12385', 'BWN', 'Barddhaman', 95, '23:30:00'),
('12385', 'ASN', 'Asansol', 200, '00:55:00'),
('12385', 'DHN', 'Dhanbad', 269, '04:45:00'),
('12386', 'DHN', 'Dhanbad', 0, '19:30:00'),
('12386', 'ASN', 'Asansol', 69, '20:25:00'),
('12386', 'BWN', 'Barddhaman', 174, '21:27:00'),
('12386', 'HWH', 'Howrah', 269, '01:30:00'),
('12387', 'HWH', 'Howrah', 0, '15:25:00'),
('12387', 'BWN', 'Barddhaman', 95, '16:35:00'),
('12387', 'ASN', 'Asansol', 200, '18:00:00'),
('12387', 'DHN', 'Dhanbad', 269, '22:00:00'),
('12388', 'DHN', 'Dhanbad', 0, '05:30:00'),
('12388', 'ASN', 'Asansol', 69, '06:25:00'),
('12388', 'BWN', 'Barddhaman', 174, '07:27:00'),
('12388', 'HWH', 'Howrah', 269, '11:55:00'),
('12389', 'HWH', 'Howrah', 0, '06:20:00'),
('12389', 'BWN', 'Barddhaman', 95, '07:30:00'),
('12389', 'ASN', 'Asansol', 200, '08:55:00'),
('12389', 'DHN', 'Dhanbad', 270, '09:55:00'),
('12389', 'GAYA', 'Gaya Junction', 683, '19:05:00'),
('12390', 'GAYA', 'Gaya Junction', 0, '11:20:00'),
('12390', 'DHN', 'Dhanbad', 180, '13:25:00'),
('12390', 'ASN', 'Asansol', 250, '14:23:00'),
('12390', 'BWN', 'Barddhaman', 355, '15:25:00'),
('12390', 'HWH', 'Howrah', 683, '00:45:00'),
('12391', 'HWH', 'Howrah', 0, '21:35:00'),
('12391', 'BWN', 'Barddhaman', 95, '22:45:00'),
('12391', 'ASN', 'Asansol', 200, '00:10:00'),
('12391', 'DHN', 'Dhanbad', 270, '01:10:00'),
('12391', 'GAYA', 'Gaya Junction', 450, '03:10:00'),
('12391', 'PNBE', 'Patna Junction', 803, '08:30:00'),
('12392', 'PNBE', 'Patna Junction', 0, '18:40:00'),
('12392', 'GAYA', 'Gaya Junction', 153, '20:45:00'),
('12392', 'DHN', 'Dhanbad', 333, '22:50:00'),
('12392', 'ASN', 'Asansol', 403, '23:48:00'),
('12392', 'BWN', 'Barddhaman', 508, '00:50:00'),
('12392', 'HWH', 'Howrah', 803, '05:10:00'),
('12393', 'HWH', 'Howrah', 0, '13:05:00'),
('12393', 'BWN', 'Barddhaman', 95, '14:15:00'),
('12393', 'ASN', 'Asansol', 200, '15:40:00'),
('12393', 'DHN', 'Dhanbad', 270, '16:40:00'),
('12393', 'GAYA', 'Gaya Junction', 450, '18:40:00'),
('12393', 'DDU', 'Deen Dayal Upadhyaya', 686, '21:15:00'),
('12393', 'CNB', 'Kanpur Central', 1002, '03:45:00'),
('12394', 'CNB', 'Kanpur Central', 0, '14:00:00'),
('12394', 'DDU', 'Deen Dayal Upadhyaya', 316, '17:25:00'),
('12394', 'GAYA', 'Gaya Junction', 552, '20:10:00'),
('12394', 'DHN', 'Dhanbad', 732, '22:15:00'),
('12394', 'ASN', 'Asansol', 802, '23:13:00'),
('12394', 'BWN', 'Barddhaman', 907, '00:15:00'),
('12394', 'HWH', 'Howrah', 1002, '05:25:00'),
('12395', 'HWH', 'Howrah', 0, '09:20:00'),
('12395', 'BWN', 'Barddhaman', 95, '10:30:00'),
('12395', 'ASN', 'Asansol', 200, '11:55:00'),
('12395', 'DHN', 'Dhanbad', 270, '12:55:00'),
('12395', 'GAYA', 'Gaya Junction', 450, '14:55:00'),
('12395', 'DDU', 'Deen Dayal Upadhyaya', 686, '17:30:00'),
('12395', 'BSB', 'Varanasi', 821, '22:35:00'),
('12396', 'BSB', 'Varanasi', 0, '04:45:00'),
('12396', 'DDU', 'Deen Dayal Upadhyaya', 111, '06:20:00'),
('12396', 'GAYA', 'Gaya Junction', 347, '09:10:00'),
('12396', 'DHN', 'Dhanbad', 527, '11:15:00'),
('12396', 'ASN', 'Asansol', 597, '12:13:00'),
('12396', 'BWN', 'Barddhaman', 702, '13:15:00'),
('12396', 'HWH', 'Howrah', 821, '18:10:00'),
('12397', 'HWH', 'Howrah', 0, '20:10:00'),
('12397', 'BWN', 'Barddhaman', 95, '21:20:00'),
('12397', 'ASN', 'Asansol', 200, '22:45:00'),
('12397', 'DHN', 'Dhanbad', 270, '23:45:00'),
('12397', 'GAYA', 'Gaya Junction', 450, '01:45:00'),
('12397', 'DDU', 'Deen Dayal Upadhyaya', 686, '04:20:00'),
('12397', 'BSB', 'Varanasi', 797, '06:05:00'),
('12397', 'LJN', 'Lucknow', 984, '10:30:00'),
('12397', 'GKP', 'Gorakhpur', 1324, '18:10:00'),
('12398', 'GKP', 'Gorakhpur', 0, '23:25:00'),
('12398', 'LJN', 'Lucknow', 340, '04:50:00'),
('12398', 'BSB', 'Varanasi', 527, '08:25:00'),
('12398', 'DDU', 'Deen Dayal Upadhyaya', 638, '10:00:00'),
('12398', 'GAYA', 'Gaya Junction', 874, '12:45:00'),
('12398', 'DHN', 'Dhanbad', 1054, '14:50:00'),
('12398', 'ASN', 'Asansol', 1124, '15:48:00'),
('12398', 'BWN', 'Barddhaman', 1229, '16:50:00'),
('12398', 'HWH', 'Howrah', 1324, '21:20:00'),
('12399', 'HWH', 'Howrah', 0, '19:20:00'),
('12399', 'BWN', 'Barddhaman', 95, '20:30:00'),
('12399', 'ASN', 'Asansol', 200, '21:55:00'),
('12399', 'DHN', 'Dhanbad', 270, '22:55:00'),
('12399', 'GAYA', 'Gaya Junction', 450, '00:55:00'),
('12399', 'DDU', 'Deen Dayal Upadhyaya', 686, '03:30:00'),
('12399', 'CNB', 'Kanpur Central', 1002, '07:10:00'),
('12400', 'CNB', 'Kanpur Central', 0, '19:35:00'),
('12400', 'DDU', 'Deen Dayal Upadhyaya', 316, '22:50:00'),
('12400', 'GAYA', 'Gaya Junction', 552, '01:35:00'),
('12400', 'DHN', 'Dhanbad', 732, '03:40:00'),
('12400', 'ASN', 'Asansol', 802, '04:38:00'),
('12400', 'BWN', 'Barddhaman', 907, '05:40:00'),
('12400', 'HWH', 'Howrah', 1002, '06:30:00');
```


---

## ✅ Step 7: Inserting Fare Data into `Train_fare` Table

After inserting data into the necessary tables, execute the following SQL command to insert fare data into the `Train_fare` table based on the defined fare rates for each class.

```sql
-- First, let's create some base fare rates for each class
-- These are example rates - in a real system you'd use official fare charts
SET @first_ac_rate = 5.00;
SET @second_ac_rate = 3.50;
SET @third_ac_rate = 2.50;
SET @sleeper_rate = 1.80;
SET @chair_car_rate = 2.00;
SET @exec_chair_rate = 3.00;
SET @second_sitting_rate = 1.20;
SET @general_rate = 0.80;
SET @first_class_rate = 4.50;
SET @eog_rate = 0.00;

SET @from_date = CURDATE();
SET @to_date = DATE_ADD(@from_date, INTERVAL 1 YEAR);

INSERT INTO Train_fare (Train_code, Class_id, From_Km, To_Km, From_date, To_date, Fare)
SELECT 
    vd1.Train_code,
    c.Class_id,
    vd1.Km_from_origin AS From_Km,
    vd2.Km_from_origin AS To_Km,
    @from_date AS From_date,
    @to_date AS To_date,
    CASE 
        WHEN c.Class_code = '1A' THEN (vd2.Km_from_origin - vd1.Km_from_origin) * @first_ac_rate
        WHEN c.Class_code = '2A' THEN (vd2.Km_from_origin - vd1.Km_from_origin) * @second_ac_rate
        WHEN c.Class_code = '3A' THEN (vd2.Km_from_origin - vd1.Km_from_origin) * @third_ac_rate
        WHEN c.Class_code = 'SL' THEN (vd2.Km_from_origin - vd1.Km_from_origin) * @sleeper_rate
        WHEN c.Class_code = 'CC' THEN (vd2.Km_from_origin - vd1.Km_from_origin) * @chair_car_rate
        WHEN c.Class_code = 'EC' THEN (vd2.Km_from_origin - vd1.Km_from_origin) * @exec_chair_rate
        WHEN c.Class_code = '2S' THEN (vd2.Km_from_origin - vd1.Km_from_origin) * @second_sitting_rate
        WHEN c.Class_code = 'GN' THEN (vd2.Km_from_origin - vd1.Km_from_origin) * @general_rate
        WHEN c.Class_code = 'FC' THEN (vd2.Km_from_origin - vd1.Km_from_origin) * @first_class_rate
        WHEN c.Class_code = 'EOG' THEN 0
        ELSE (vd2.Km_from_origin - vd1.Km_from_origin) * 1.50 
    END AS Fare
FROM 
    Via_details vd1
JOIN 
    Via_details vd2 ON vd1.Train_code = vd2.Train_code
JOIN 
    Class c
WHERE 
    vd2.Km_from_origin > vd1.Km_from_origin
    AND NOT EXISTS (
        SELECT 1 FROM Via_details vd3 
        WHERE vd3.Train_code = vd1.Train_code 
        AND vd3.Km_from_origin > vd1.Km_from_origin 
        AND vd3.Km_from_origin < vd2.Km_from_origin
    )
    AND c.Class_id != 'C010' 
ORDER BY 
    vd1.Train_code, vd1.Km_from_origin, vd2.Km_from_origin, c.Class_id;
```

---

## ✅ Step 8: Creating Trigger for Seat Availability Management

Execute the following SQL commands to create a trigger that manages seat availability in the `Seat_availability` table whenever a new passenger is added to the `PAX_info` table.

```sql
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
                                                            AND travel_date=journey_date;
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
```


## ✅ Step 9: Populating Payment Information Table

Execute the following SQL script to populate the `Pay_info table` with one payment record per PNR, summing all passenger fares. This script includes randomization for payment modes and types, ensuring a realistic distribution of payment methods.
```sql
-- Script to populate Pay_info table with one payment per PNR (summing all passenger fares)
INSERT INTO Pay_info (PNR_no, SRL_no, Pay_date, Pay_mode, Amount, Inst_type, Inst_amt)
WITH payment_data AS (
    SELECT 
        p.PNR_no,
        MIN(p.SRL_no) AS SRL_no, -- Use the first passenger's SRL_no as reference
        tr.From_date AS Pay_date,
        -- Random payment mode with weighted probabilities
        CASE 
            WHEN RAND() < 0.4 THEN 'UPI'        -- 40% probability
            WHEN RAND() < 0.7 THEN 'Credit Card' -- 30% probability (70-40)
            WHEN RAND() < 0.85 THEN 'Debit Card' -- 15% probability (85-70)
            WHEN RAND() < 0.95 THEN 'Net Banking' -- 10% probability (95-85)
            ELSE 'Cash'                          -- 5% probability
        END AS Pay_mode,
        SUM(p.Fare) AS Total_amount, -- Sum of all fares for this PNR
        -- Random payment type (85% online, 15% counter)
        IF(RAND() < 0.85, 'Online', 'Counter') AS Inst_type
    FROM PAX_info p
    JOIN Ticket_Reservation tr ON p.PNR_no = tr.PNR_no
    GROUP BY p.PNR_no, tr.From_date
)
SELECT 
    PNR_no,
    SRL_no,
    Pay_date,
    Pay_mode,
    -- Use exact sum of fares (no random variation)
    ROUND(Total_amount, 2) AS Amount,
    Inst_type,
    -- For counter payments, add a small convenience fee (0 for online)
    CASE 
        WHEN Inst_type = 'Counter' THEN ROUND(10 + RAND() * 20, 2) 
        ELSE 0 
    END AS Inst_amt
FROM payment_data;

-- Verification queries
-- Count of payments created
SELECT COUNT(*) AS total_payments FROM Pay_info;

-- Sample payment records
SELECT * FROM Pay_info ORDER BY RAND() LIMIT 10;

-- Verify payment amounts match sum of passenger fares
SELECT 
    p.PNR_no,
    COUNT(*) AS passenger_count,
    SUM(p.Fare) AS total_passenger_fares,
    py.Amount AS payment_amount,
    (SUM(p.Fare) - py.Amount) AS difference
FROM PAX_info p
JOIN Pay_info py ON p.PNR_no = py.PNR_no
GROUP BY p.PNR_no, py.Amount
HAVING difference != 0
LIMIT 20;
```

## ✅ Step 10: Generating Login Credentials for Passengers

Execute the following SQL script to create a stored procedure that generates unique login credentials for each passenger in the `PAX_info` table. This procedure ensures that each login ID is unique and generates a secure password for each passenger.
```sql
DELIMITER //
CREATE PROCEDURE GenerateCompleteLoginCredentials()
BEGIN
    -- Declare all variables first
    DECLARE passenger_id_var VARCHAR(15);
    DECLARE pax_name_var VARCHAR(100);
    DECLARE pax_age_var INT;
    DECLARE first_name_var VARCHAR(100);
    DECLARE last_part_var VARCHAR(100);
    DECLARE login_id_var VARCHAR(200);
    DECLARE password_var VARCHAR(255);
    DECLARE total_count INT DEFAULT 0;
    DECLARE processed_count INT DEFAULT 0;
    DECLARE done INT DEFAULT FALSE;
    
    -- Declare cursor and handlers after all variables
    DECLARE cur CURSOR FOR SELECT Passenger_id, PAX_Name, PAX_age FROM PAX_info;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Get total count for verification
    SELECT COUNT(*) INTO total_count FROM PAX_info;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO passenger_id_var, pax_name_var, pax_age_var;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET processed_count = processed_count + 1;
        
        -- Extract first name (everything before first space)
        SET first_name_var = SUBSTRING_INDEX(pax_name_var, ' ', 1);
        
        -- Handle cases where there might not be a last name
        IF LOCATE(' ', pax_name_var) = 0 THEN
            SET last_part_var = '';
        ELSE
            SET last_part_var = SUBSTRING(pax_name_var, LOCATE(' ', pax_name_var) + 1);
        END IF;
        
        -- Generate login ID: firstname_lastname (lowercase with underscore)
        -- Handle special characters and multiple spaces
        SET login_id_var = LOWER(
            CONCAT(
                REGEXP_REPLACE(first_name_var, '[^a-zA-Z0-9]', ''),
                '_',
                REGEXP_REPLACE(REPLACE(last_part_var, ' ', '_'), '[^a-zA-Z0-9_]', '')
            )
        );
        
        -- Ensure login_id is unique by appending passenger_id if needed
        SET @counter = 0;
        WHILE EXISTS (SELECT 1 FROM Login_credential WHERE login_id = login_id_var AND (@counter > 0 OR Passenger_id != passenger_id_var)) DO
            SET @counter = @counter + 1;
            SET login_id_var = CONCAT(
                LOWER(
                    CONCAT(
                        REGEXP_REPLACE(first_name_var, '[^a-zA-Z0-9]', ''),
                        '_',
                        REGEXP_REPLACE(REPLACE(last_part_var, ' ', '_'), '[^a-zA-Z0-9_]', '')
                    )
                ),
                @counter
            );
        END WHILE;
        
        -- Generate password: firstname + age + random characters (total 10-20 chars)
        SET @base = CONCAT(REGEXP_REPLACE(first_name_var, '[^a-zA-Z0-9]', ''), pax_age_var);
        SET @needed_length = 10 + FLOOR(RAND() * 11); -- Random length between 10-20
        SET @random_part = '';
        
        -- Generate random characters if needed
        IF LENGTH(@base) < @needed_length THEN
            SET @chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
            WHILE LENGTH(@base) + LENGTH(@random_part) < @needed_length DO
                SET @random_part = CONCAT(@random_part, 
                    SUBSTRING(@chars, FLOOR(1 + RAND() * LENGTH(@chars)), 1));
            END WHILE;
        END IF;
        
        SET password_var = CONCAT(@base, @random_part);
        
        -- Insert into Login_credential table
        INSERT INTO Login_credential (login_id, password, Passenger_id)
        VALUES (login_id_var, SHA2(password_var, 256), passenger_id_var)
        ON DUPLICATE KEY UPDATE 
            login_id = VALUES(login_id),
            password = VALUES(password);
        
    END LOOP;
    
    CLOSE cur;
    
    -- Verification output
    SELECT CONCAT('Processed ', processed_count, ' of ', total_count, ' records') AS verification;
END //
DELIMITER ;

-- First, truncate the table to ensure clean insert
TRUNCATE TABLE Login_credential;

-- Execute the procedure
CALL GenerateCompleteLoginCredentials();

-- Verify counts match
SELECT 
    (SELECT COUNT(*) FROM PAX_info) AS pax_count,
    (SELECT COUNT(*) FROM Login_credential) AS login_count,
    IF((SELECT COUNT(*) FROM PAX_info) = (SELECT COUNT(*) FROM Login_credential), 
       'Counts match!', 
       CONCAT('Discrepancy: ', 
              (SELECT COUNT(*) FROM PAX_info) - (SELECT COUNT(*) FROM Login_credential), 
              ' records missing')) AS verification;

-- Drop the procedure if you don't need it anymore
DROP PROCEDURE IF EXISTS GenerateCompleteLoginCredentials;
```
## ✅ Step 11: Booking a Train Ticket - Procedure Execution

To execute the booking procedure for reserving a train ticket, use the BookTicket procedure. This procedure is designed to handle the entire booking flow, from validating station details to confirming the booking, calculating fares, assigning seats, and processing payments.

```sql
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
    DECLARE v_available_seats INT DEFAULT 0;
    DECLARE v_rac_seats INT DEFAULT 0;
    DECLARE v_current_waitlist INT DEFAULT 0;
    DECLARE v_booking_status ENUM('Confirmed', 'RAC', 'Waitlist','Cancelled') DEFAULT 'Confirmed';
    DECLARE v_waitlist_position INT DEFAULT 0;
    DECLARE v_km_rate DECIMAL(10,2);
    DECLARE v_distance INT;
    DECLARE v_seat_exists INT DEFAULT 0;
    DECLARE v_seats_per_coach INT;
    
    -- Configuration parameters
    DECLARE v_rac_limit INT DEFAULT 10; -- Number of RAC seats per train/class
    DECLARE v_waitlist_limit INT DEFAULT 100; -- Maximum waitlist positions
    
    -- Get number of seats per coach from Class table
    SELECT Seat_per_coach INTO v_seats_per_coach
    FROM Class
    WHERE Class_code = p_class_code;
    
    -- Validate from and to stations
    IF p_from_station = p_to_station THEN
        SET p_status_message = 'From and To stations cannot be the same';
        SET p_booking_status = 'Cancelled';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'From and To stations cannot be identical';
    END IF;
    
    -- Generate PNR number (format: PNR + random 8 digits)
    SET v_pnr_no = CONCAT('PNR', LPAD(FLOOR(RAND() * 100000000), 8, '0'));
    
    -- Get distance information with proper validation
    SELECT vd1.Km_from_origin, vd2.Km_from_origin 
    INTO v_from_km, v_to_km
    FROM Via_details vd1
    JOIN Via_details vd2 ON vd1.Train_code = vd2.Train_code
    WHERE vd1.Train_code = p_train_code
    AND vd1.Via_station_code = p_from_station
    AND vd2.Via_station_code = p_to_station
    AND vd2.Km_from_origin > vd1.Km_from_origin
    LIMIT 1;
    
    -- Validate distance information
    IF v_from_km IS NULL OR v_to_km IS NULL THEN
        SET p_status_message = 'Invalid station codes or route information';
        SET p_booking_status = 'Cancelled';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Could not determine route distance';
    END IF;
    
    -- Calculate distance
    SET v_distance = v_to_km - v_from_km;
    
    -- Validate calculated distance
    IF v_distance <= 0 THEN
        SET p_status_message = 'Invalid route distance calculated';
        SET p_booking_status = 'Cancelled';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid route distance';
    END IF;
    
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
    
    -- Create ticket reservation with validated distance values
    INSERT INTO Ticket_Reservation (
        PNR_no, Train_code, From_station, To_station, 
        From_Km, To_Km, From_date, To_date
    ) VALUES (
        v_pnr_no, p_train_code, p_from_station, p_to_station,
        v_from_km, v_to_km, p_from_date, p_from_date
    );
    
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
    
    -- Check if seats exist for this train/class/date
    SELECT COUNT(*) INTO v_seat_exists
    FROM Seat_availability
    WHERE Train_code = p_train_code
    AND Class_code = p_class_code
    AND travel_date = p_from_date;
    
    -- If no seats exist, create them
    IF v_seat_exists = 0 THEN
        -- Create a temporary table to generate seat numbers
        CREATE TEMPORARY TABLE IF NOT EXISTS temp_seat_numbers (seat_num INT);
        
        -- Insert seat numbers from 1 to v_seats_per_coach
        SET @counter = 1;
        WHILE @counter <= v_seats_per_coach DO
            INSERT INTO temp_seat_numbers VALUES (@counter);
            SET @counter = @counter + 1;
        END WHILE;
        
        -- Insert new seats for the coach
        INSERT INTO Seat_availability (Train_code, Class_code, Seat_No, Seat_Status, travel_date)
        SELECT p_train_code, p_class_code, 
               seat_num as Seat_No,
               'Available' as Seat_Status,
               p_from_date as travel_date
        FROM temp_seat_numbers;
        
        -- Drop the temporary table
        DROP TEMPORARY TABLE IF EXISTS temp_seat_numbers;
        
        -- Set available seats to the number of seats just created
        SET v_available_seats = v_seats_per_coach;
    ELSE
        -- Check available seats
        SELECT COUNT(*) INTO v_available_seats
        FROM Seat_availability
        WHERE Train_code = p_train_code
        AND Class_code = p_class_code
        AND Seat_Status = 'Available'
        AND travel_date = p_from_date;
    END IF;
    
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
        AND travel_date = p_from_date
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
        AND Seat_No = v_seat_no
        AND travel_date = p_from_date;
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
```
---
## ✅ Step 12: Upgrading RAC Passengers When Seats Get Cancelled

After handling bookings and waitlists, this step ensures that any seats that were canceled are automatically allocated to RAC passengers, upgrading them to Confirmed status in a fair and efficient way!

```sql
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
```
---

### 📌 Conclusion

This Railway Ticket Reservation System project aims to simulate the core functionalities of a real-world railway booking system. Through comprehensive database design, implementation, and integration of advanced SQL features like triggers, procedures, and views, the system demonstrates efficient handling of bookings, cancellations, fare calculations, and seat availability management.

By modeling realistic scenarios such as PNR tracking, RAC/waitlist handling, dynamic seat allocation, and concession management, the application highlights the importance of relational databases in large-scale systems like Indian Railways.

### 📁 Final Deliverables Recap

- ✅ **ER Diagram** and **Relational Schema**
- ✅ **Normalized Database Structure** implemented in MySQL
- ✅ **SQL Files** (schema, insert, query, procedure, function, and trigger scripts)
- ✅ **Sample Data** loaded for demonstration
- ✅ **Custom Queries** including PNR status, seat availability, revenue calculation, etc.
- ✅ **README.txt** with setup instructions and overview
- ✅ **Video Demonstration** showcasing schema, features, and query executions


### ▶️ How to Run

1. **Install MySQL Server.**
2. Run the schema and data population SQL files in the correct order.
3. Use the provided queries to explore system features.

---

## 🛠 Future Enhancements

- Add real-time seat availability sync.
- Implement user-friendly front-end (web or app).
- Integrate payment gateway support.
- Include support for waitlist and RAC logic.
- Enable admin panel for train and schedule management.

---

## 🙌 Acknowledgements

Special thanks to mentors, contributors, and documentation sources that helped build this system.

---

## 📬 Contact

For any queries or feedback, feel free to reach out:

- **PRAGYA MAHAJAN**
- **MIHIKA**
- **PRIYANSHI AGRAWAL**


---

