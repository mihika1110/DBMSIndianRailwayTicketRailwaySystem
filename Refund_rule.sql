INSERT INTO Refund_rule (PNR_no, Refundable_amt, Cancellation_time)
SELECT 
    tr.PNR_no,
    CASE 
        WHEN SUM(pi.Amount) >= 9000 THEN SUM(pi.Amount) * 0.80
        WHEN SUM(pi.Amount) >= 8000 THEN SUM(pi.Amount) * 0.75
        WHEN SUM(pi.Amount) >= 7000 THEN SUM(pi.Amount) * 0.70
        WHEN SUM(pi.Amount) >= 6000 THEN SUM(pi.Amount) * 0.65
        WHEN SUM(pi.Amount) >= 5000 THEN SUM(pi.Amount) * 0.60
        WHEN SUM(pi.Amount) >= 4000 THEN SUM(pi.Amount) * 0.55
        WHEN SUM(pi.Amount) >= 3000 THEN SUM(pi.Amount) * 0.50
        WHEN SUM(pi.Amount) >= 2000 THEN SUM(pi.Amount) * 0.45
        WHEN SUM(pi.Amount) >= 1000 THEN SUM(pi.Amount) * 0.40
        ELSE SUM(pi.Amount) * 0.35
    END AS Refundable_amt,
    DATE_SUB(CONCAT(tr.From_date, ' ', t.Start_time), INTERVAL 1 DAY) AS Cancellation_time
FROM Pay_info pi
JOIN Ticket_Reservation tr ON pi.PNR_no = tr.PNR_no
JOIN Train t ON tr.Train_code = t.Train_code
GROUP BY tr.PNR_no, tr.From_date, t.Start_time
HAVING SUM(pi.Amount) > 0;