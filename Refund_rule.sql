-- Populate Refund_rule table with refund rules based on payment amount from Pay_info
INSERT INTO Refund_rule (PNR_no, Refundable_amt, From_time, To_time)
SELECT 
    p.PNR_no,
    CASE 
        WHEN SUM(p.Amount) >= 9000 THEN SUM(p.Amount) * 0.80
        WHEN SUM(p.Amount) >= 8000 THEN SUM(p.Amount) * 0.75
        WHEN SUM(p.Amount) >= 7000 THEN SUM(p.Amount) * 0.70
        WHEN SUM(p.Amount) >= 6000 THEN SUM(p.Amount) * 0.65
        WHEN SUM(p.Amount) >= 5000 THEN SUM(p.Amount) * 0.60
        WHEN SUM(p.Amount) >= 4000 THEN SUM(p.Amount) * 0.55
        WHEN SUM(p.Amount) >= 3000 THEN SUM(p.Amount) * 0.50
        WHEN SUM(p.Amount) >= 2000 THEN SUM(p.Amount) * 0.45
        WHEN SUM(p.Amount) >= 1000 THEN SUM(p.Amount) * 0.40
        ELSE SUM(p.Amount) * 0.35
    END AS Refundable_amt,
    -- Set reasonable time windows for refund eligibility (e.g., 8 AM to 8 PM)
    '08:00:00' AS From_time,
    '20:00:00' AS To_time
FROM Pay_info p
JOIN Ticket_Reservation tr ON p.PNR_no = tr.PNR_no
GROUP BY p.PNR_no
HAVING SUM(p.Amount) > 0;  -- Only include PNRs with actual payments