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