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