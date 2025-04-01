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