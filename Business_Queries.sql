-- CREATE DATABASE UPI_Fraud_DB; 
-- use UPI_Fraud_DB; if Your using Mysql  / in this project im using PostgreSQL 
 
-- ============================================================ 
-- FILE    : business_queries.sql 
-- PROJECT : UPI Transaction Fraud & Risk Analytics 
-- ============================================================ 
 
-- Lets check  
SELECT * FROM users; 
 
SELECT * FROM merchants; 
 
SELECT * FROM transactions; 
 
SELECT * FROM payment_failures; 
 
SELECT * FROM fraud_labels; 
 
-- ──────────────────────────────────────────────────────────── 
-- Q1: Overall KPI Summary 
-- Business: What is the complete fraud picture in one view? 
-- Display: total_transactions, total_fraud_txns, 
--          fraud_rate_pct, total_fraud_amount, avg_fraud_amount 
-- ──────────────────────────────────────────────────────────── 
 
SELECT 
    COUNT(*) AS total_transactions, 
    SUM(f.is_fraud) AS total_fraud_txns, 
    ROUND(AVG(f.is_fraud::numeric) * 100, 2) AS fraud_rate_pct, 
    ROUND(SUM(CASE WHEN f.is_fraud = 1 
              THEN t.amount ELSE 0 END)::numeric, 2)  AS total_fraud_amount, 
    ROUND(AVG(CASE WHEN f.is_fraud = 1 
              THEN t.amount END)::numeric, 2) AS avg_fraud_amount 
FROM transactions t 
JOIN fraud_labels f  
ON t.txn_id = f.txn_id; 
 
-- ROUND() sirf numeric type pe kaam karta hai — double precision pe nahi. Isliye ::numeric cast karna padta hai. 
-- ──────────────────────────────────────────────────────────── 
-- Q2: Fraud Rate by City — Ranked 
-- Business: Which cities should the fraud team focus on most? 
-- Display: user_city, total_txns, fraud_txns, 
--          fraud_rate_pct, risk_rank 
-- ──────────────────────────────────────────────────────────── 
 
SELECT  
 	u.user_city, 
 	count(*) as Total_txns, 
 	SUM(f.is_fraud) as fraud_txns, 
 	Round(AVG(f.is_fraud::numeric) * 100,2) as fraud_rate_pct, 
 	Rank() over ( order by AVG(f.is_fraud) DESC ) as risk_rank 
FROM transactions t 
JOIN users u       
ON t.user_id = u.user_id 
JOIN fraud_labels f  
ON t.txn_id = f.txn_id 
GROUP BY u.user_city 
ORDER BY fraud_rate_pct DESC; 
 
-- here why we not use partition by  and why not count for is_fraude in Notepad(doc file) 
-- Every city gets a risk rank — fraud team can directly prioritize which city needs investigation first instead of guessing.

-- ──────────────────────────────────────────────────────────── 
-- Q3: Fraud Rate by Payment Channel 
-- Business: Which payment channel is the riskiest? 
-- Display: channel, total_txns, fraud_txns, 
--          fraud_rate_pct, avg_txn_amount 
-- ──────────────────────────────────────────────────────────── 
SELECT  
 	t.channel, 
 	COUNT(*) AS total_txns, 
    SUM(f.is_fraud) AS fraud_txns, 
    ROUND(AVG(f.is_fraud::numeric) * 100, 2) AS fraud_rate_pct, 
    ROUND(AVG(t.amount::"numeric"),2) AS avg_txn_amout 
FROM transactions t 
Inner join fraud_labels f 
ON t.txn_id = f.txn_id GROUP by 1  order by 4 DESC ; 
 
-- ──────────────────────────────────────────────────────────── 
-- Q4: Top 10 Riskiest Merchants 
-- Business: Which merchants should be flagged or blocked? 
-- Display: merchant_id, merchant_name, category, merchant_city, 
--          total_txns, fraud_count, fraud_rate_pct, total_fraud_loss 
-- ──────────────────────────────────────────────────────────── 
SELECT * from merchants 
 
SELECT 
    m.merchant_id, 
    m.merchant_name, 
    m.category, 
    m.merchant_city, 
    COUNT(*)    AS total_txns, 
    SUM(f.is_fraud)  AS fraud_count, 
    ROUND(AVG(f.is_fraud :: numeric) * 100, 2) AS fraud_rate_pct, 
 	Round(SUM( 
 	CASE WHEN f.is_fraud = 1 THEN t.amount ELSE 0 END )::numeric,2) as total_fraud_loss 
FROM transactions  t 
JOIN merchants m  
ON t.merchant_id = m.merchant_id 
JOIN fraud_labels f 
ON t.txn_id = f.txn_id 
GROUP BY m.merchant_id, m.merchant_name, 
         m.category, m.merchant_city 
HAVING COUNT(*) >= 10 
ORDER BY fraud_rate_pct DESC 
LIMIT 10; 
 
-- ──────────────────────────────────────────────────────────── 
-- Q5: Payment Failure Retry Analysis 
-- Business: Kya zyada retry karne se transaction resolve hota hai? 
-- Display: retry_count, total_failures, resolved_count, 
--          resolution_rate_pct, avg_failed_amount 
-- ──────────────────────────────────────────────────────────── 
SELECT * from payment_failures 
 
 
SELECT 
    pf.retry_count, 
    COUNT(*)     AS total_failures, 
    SUM(CASE WHEN pf.resolved = 'True'  
        THEN 1 ELSE 0 END)   AS resolved_count, 
    ROUND(SUM(CASE WHEN pf.resolved = 'True' 
        THEN 1 ELSE 0 END) * 100.0  
        / COUNT(*), 2)    AS resolution_rate_pct, 
    ROUND(AVG(t.amount::numeric), 2)   AS avg_failed_amount 
FROM payment_failures pf 
JOIN transactions t 
ON pf.txn_id = t.txn_id 
GROUP BY pf.retry_count 
ORDER BY pf.retry_count; 
 
 
 
-- ──────────────────────────────────────────────────────────── 
-- Q6: Fraud Rate by Hour of Day 
-- Business: At which hours should step-up authentication trigger? 
-- Display: txn_hour, total_txns, fraud_txns, 
--          fraud_rate_pct, time_segment (High Risk / Normal) 
-- ──────────────────────────────────────────────────────────── 
SELECT  
 	t.txn_hour, 
 	count(t.txn_id) as total_txns, 
 	SUM(f.is_fraud) AS fraud_txns, 
 	Round(AVG(f.is_fraud :: "numeric")*100,2) as fraud_rate_pct, 
 	CASE  
 	 	WHEN t.txn_hour BETWEEN 0 and 4 OR t.txn_hour = 23 THEN 'High Risk' 
 	 	ELSE 'Normal Hours' 
 	 	END as time_segment 
From transactions as t 
JOIN fraud_labels f 
ON t.txn_id = f.txn_id 
GROUP by t.txn_hour 
ORDER by t.txn_hour ;  
 
-- Late night hours clearly labeled as High Risk — this directly tells engineering team when to trigger step-up authentication.
-- or  measures such as OTP verification, transaction limits may be applied. 
 
-- ──────────────────────────────────────────────────────────── 
-- Q7: Month-over-Month Fraud Growth Rate 
-- Business: Fraud badh raha hai ya ghath raha hai month by month? 
-- Display: txn_month, txn_month_name, fraud_rate_pct, 
--          prev_month_rate, mom_change_pct 
-- ──────────────────────────────────────────────────────────── 
WITH monthly_fraud AS ( 
    SELECT 
        t.txn_month, 
        t.txn_month_name, 
        ROUND(AVG(f.is_fraud::numeric) * 100, 2) AS fraud_rate_pct 
    FROM transactions t 
    JOIN fraud_labels f ON t.txn_id = f.txn_id 
    GROUP BY t.txn_month, t.txn_month_name 
) 
SELECT 
    txn_month,     txn_month_name,     fraud_rate_pct, 
    LAG(fraud_rate_pct) OVER ( 
        ORDER BY txn_month 
    )  AS prev_month_rate, 
    ROUND(fraud_rate_pct - LAG(fraud_rate_pct) OVER ( 
        ORDER BY txn_month 
    ), 2)   AS mom_change_pct 
FROM monthly_fraud 
ORDER BY txn_month; 
 
-- ──────────────────────────────────────────────────────────── 
-- Q8: Velocity Fraud Detection 
-- Business: Which users made 5+ transactions within 1 hour? 
-- Display: user_id, suspicious_txn_count 
-- ──────────────────────────────────────────────────────────── 
WITH user_velocity AS (     SELECT 
        user_id,         txn_id, 
        timestamp::timestamp AS timestamp, 
        COUNT(*) OVER ( 
            PARTITION BY user_id 
            ORDER BY timestamp::timestamp 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW 
        )                                    AS rolling_5_txns, 
        timestamp::timestamp - LAG(timestamp::timestamp, 4) OVER ( 
            PARTITION BY user_id 
            ORDER BY timestamp::timestamp 
        )                                    AS time_window 
    FROM transactions 
) 
SELECT DISTINCT 
    user_id, 
    COUNT(*) OVER (PARTITION BY user_id)     AS suspicious_txn_count 
FROM user_velocity 
WHERE rolling_5_txns = 5 
  AND EXTRACT(EPOCH FROM time_window) <= 3600 
ORDER BY suspicious_txn_count DESC 
LIMIT 20; 
 
-- SQLAlchemy se load karne pe datetime columns text ban jaate hain. Isliye ::timestamp cast karo tabhi subtraction aur LAG kaam karega. 
-- "Velocity fraud query ne zero results diye — jo expected tha kyunki synthetic dataset mein transactions randomly distributed the across 365 days. Real production data mein yeh query highfrequency fraudsters ko flag karti." 
-- EXTRACT(EPOCH FROM ...) converts a time interval into its total equivalent in seconds as a numeric value. 
 
-- quick check 
SELECT  
    user_id, 
    COUNT(*) AS total_txns, 
    MIN(timestamp::timestamp) AS first_txn, 
    MAX(timestamp::timestamp) AS last_txn 
FROM transactions 
GROUP BY user_id 
ORDER BY total_txns DESC 
LIMIT 10; 
-- repeat understand mahesh this Q  
 
-- ──────────────────────────────────────────────────────────── 
-- Q9: High Risk User Labeling 
-- Business: Which users need immediate action? 
-- Display: user_id, kyc_status, total_txns, fraud_count, 
--          personal_fraud_rate, risk_label 
-- ──────────────────────────────────────────────────────────── 
WITH user_stats AS ( 
    SELECT 
        t.user_id, 
        u.kyc_status, 
        u.new_account_flag, 
        u.account_age_days, 
        COUNT(*)                        AS total_txns, 
        SUM(f.is_fraud)                 AS fraud_count, 
        ROUND(AVG(f.is_fraud) * 100, 2) AS personal_fraud_rate 
    FROM transactions t 
    JOIN users u        ON t.user_id = u.user_id 
    JOIN fraud_labels f ON t.txn_id  = f.txn_id 
    GROUP BY t.user_id, u.kyc_status, 
             u.new_account_flag, u.account_age_days 
) 
SELECT *, 
    CASE 
        WHEN personal_fraud_rate > 5 
         AND kyc_status = 'Non-KYC'     THEN 'CRITICAL' 
        WHEN personal_fraud_rate > 3 
          OR new_account_flag = 1        THEN 'HIGH' 
        WHEN personal_fraud_rate > 1     THEN 'MEDIUM' 
        ELSE                                  'LOW' 
    END                                 AS risk_label 
FROM user_stats 
ORDER BY personal_fraud_rate DESC 
LIMIT 50; 
 
-- Thinking: 
-- This is a classification problem. 
-- We convert raw metrics (fraud rate, KYC status, -- account age) into actionable business categories. 
-- Analytics becomes useful only when it drives decisions. 
 
-- ──────────────────────────────────────────────────────────── 
-- Q10: Payment Failure Revenue Loss Analysis 
-- Business: Which failure reason causes maximum revenue loss? 
-- Display: failure_reason, failure_count, avg_failed_amount, 
--          total_revenue_lost, pct_of_failures 
-- ──────────────────────────────────────────────────────────── SELECT 
    pf.failure_reason, 
    COUNT(*)   AS failure_count, 
    ROUND(AVG(t.amount::numeric), 2)  AS avg_failed_amount, 
    ROUND(SUM(t.amount::numeric), 2) AS total_revenue_lost, 
    ROUND(COUNT(*) * 100.0 / 
        SUM(COUNT(*)) OVER (), 2)  AS pct_of_failures 
FROM payment_failures pf 
JOIN transactions t 
ON pf.txn_id = t.txn_id 
GROUP BY pf.failure_reason 
ORDER BY total_revenue_lost DESC; 
 
-- ──────────────────────────────────────────────────────────── 
-- Q11: Device Type vs Transaction Volume & Fraud 
-- Business: Konse device pe kitna business aur kitna risk hai? 
-- Display: device_type, total_txns, total_volume, 
--          fraud_txns, fraud_rate_pct, avg_amount 
-- ──────────────────────────────────────────────────────────── 
SELECT 
    t.device_type, 
    COUNT(*) AS total_txns, 
    ROUND(SUM(t.amount::numeric), 2)   AS total_volume, 
    SUM(f.is_fraud)  AS fraud_txns, 
    ROUND(AVG(f.is_fraud::numeric) * 100, 2)    AS fraud_rate_pct, 
    ROUND(AVG(t.amount::numeric), 2)  AS avg_amount 
FROM transactions t 
JOIN fraud_labels f ON t.txn_id = f.txn_id 
GROUP BY t.device_type 
ORDER BY total_volume DESC; 
 
 -- Shows both business volume AND fraud together — 
 -- Mobile may have highest volume but Desktop may have highest fraud rate. Two different decisions from one query.
 
 
-- ──────────────────────────────────────────────────────────── 
-- Q12: Account Cohort Fraud Analysis 
-- Business: Do new accounts carry more fraud risk than established? 
-- Display: account_cohort, total_txns, fraud_count, 
--          fraud_rate_pct, avg_amount, risk_rank 
-- ──────────────────────────────────────────────────────────── 
WITH cohort_stats AS ( 
    SELECT 
        u.account_cohort, 
        COUNT(*)  AS total_txns, 
        SUM(f.is_fraud) AS fraud_count, 
        ROUND(AVG(f.is_fraud)*100, 2)  AS fraud_rate_pct, 
        ROUND(AVG(t.amount)::numeric, 2) AS avg_amount 
    FROM transactions t 
    JOIN users u        
 	ON t.user_id = u.user_id 
    JOIN fraud_labels f  
 	ON t.txn_id  = f.txn_id 
    GROUP BY u.account_cohort 
) 
SELECT *, 
    RANK() OVER ( 
        ORDER BY fraud_rate_pct DESC 
    )        AS risk_rank 
FROM cohort_stats 
ORDER BY risk_rank; 
 
-- ──────────────────────────────────────────────────────────── 
-- Q13: Fraud Type Breakdown 
-- Business: Which fraud type is most common and most costly? 
-- Display: fraud_type, fraud_count, total_fraud_amount, 
--          avg_fraud_amount, pct_of_total_fraud 
-- ──────────────────────────────────────────────────────────── 
Select * from payment_failures 
 
SELECT 
    f.fraud_type, 
    COUNT(*)   AS fraud_count, 
    ROUND(SUM(t.amount::numeric), 2)  AS total_fraud_amount, 
    ROUND(AVG(t.amount::numeric), 2)  AS avg_fraud_amount, 
    ROUND(COUNT(*) * 100.0 / 
        SUM(COUNT(*)) OVER (), 2)  AS pct_of_total_fraud 
FROM fraud_labels f 
JOIN transactions t  
ON f.txn_id = t.txn_id 
WHERE f.is_fraud = 1 
GROUP BY f.fraud_type 
ORDER BY fraud_count DESC; 
 
-- ──────────────────────────────────────────────────────────── 
-- Q14: Late Night vs Normal Hours Fraud Comparison 
-- Business: How much more fraud happens in late night window? 
-- Display: time_window, total_txns, fraud_txns, 
--          fraud_rate_pct, total_volume, fraud_amount 
-- ──────────────────────────────────────────────────────────── 
 
SELECT 
    CASE 
        WHEN t.late_night_flag = 1 THEN 'Late Night (11PM-4AM)' 
        ELSE 'Normal Hours' 
    END   AS time_window, 
    COUNT(*) AS total_txns, 
    SUM(f.is_fraud)  AS fraud_txns, 
    ROUND(AVG(f.is_fraud) * 100, 2) AS fraud_rate_pct, 
    ROUND(SUM(t.amount::numeric), 2)    AS total_volume, 
    ROUND(SUM(CASE WHEN f.is_fraud = 1 
              THEN t.amount ELSE 0 END)::numeric, 2) AS fraud_amount 
FROM transactions t 
JOIN fraud_labels f ON t.txn_id = f.txn_id 
GROUP BY t.late_night_flag 
ORDER BY fraud_rate_pct DESC; 
 
-- ──────────────────────────────────────────────────────────── 
-- Q15: Verified vs Unverified Merchant Risk 
-- Business: Do unverified merchants have higher fraud exposure? 
-- Display: is_verified, merchant_count, total_txns, 
--          fraud_txns, fraud_rate_pct, total_fraud_loss 
-- ──────────────────────────────────────────────────────────── 
SELECT  
 	m.is_verified, 
 	COUNT(distinct m.merchant_id) as merchant_count, 
 	COUNT(*)  AS total_txns, 
    SUM(f.is_fraud)  AS fraud_txns, 
    ROUND(AVG(f.is_fraud) * 100, 2)     AS fraud_rate_pct, 
    ROUND(SUM(CASE WHEN f.is_fraud = 1 
              THEN t.amount ELSE 0 END):: numeric, 2) AS total_fraud_loss 
FROM transactions t 
JOIN merchants m    
ON t.merchant_id = m.merchant_id 
JOIN fraud_labels f 
ON t.txn_id = f.txn_id 
GROUP BY m.is_verified 
ORDER BY fraud_rate_pct DESC ; 

-- If unverified merchants show higher fraud —
-- onboarding team needs stricter verification process before activating new merchants.
 
-- ──────────────────────────────────────────────────────────── 
-- Q16: Top 5 Users by Total Fraud Amount Spent 
-- Business: Kaun se users ne sabse zyada fraud amount transact kiya? 
-- Display: user_id, name, user_city, fraud_txns, 
--          total_fraud_spent, avg_fraud_amount 
 
-- ──────────────────────────────────────────────────────────── 
SELECT * from users 
 
SELECT 
    u.user_id, 
    u.name, 
    u.user_city, 
    COUNT(*) AS fraud_txns, 
    SUM(t.amount:: "numeric") AS total_fraud_amount, 
    ROUND( 
        AVG(t.amount)::numeric, 
        2 
    ) AS avg_fraud_amount 
FROM users u 
JOIN transactions t 
ON u.user_id = t.user_id 
JOIN fraud_labels f 
ON t.txn_id = f.txn_id 
WHERE f.is_fraud = 1 
GROUP BY 1,2,3 
ORDER BY total_fraud_amount DESC 
LIMIT 5; 
 	 
-- Rule: 
-- If WHERE already filters rows, 
-- CASE WHEN inside SUM()/AVG() is usually unnecessary. 
 
-- ──────────────────────────────────────────────────────────── 
-- Q17 : Merchant City Risk Heatmap 
-- Business: Konse cities mein merchant fraud concentration hai? 
-- Display: merchant_city, total_merchants, total_txns, 
--          fraud_txns, fraud_rate_pct, total_fraud_loss 
--          city_risk_rank 
-- ──────────────────────────────────────────────────────────── 
 
SELECT 
    m.merchant_city, 
    COUNT(DISTINCT m.merchant_id) AS total_merchants, 
    COUNT(*) AS total_txns, 
    SUM(f.is_fraud) AS fraud_txns, 
    ROUND(AVG(f.is_fraud::numeric) * 100,2) AS fraud_rate_pct, 
    ROUND(SUM(CASE WHEN f.is_fraud = 1 THEN t.amount ELSE 0 END)::numeric,2) AS total_fraud_loss, 
    RANK() OVER ( 
        ORDER BY AVG(f.is_fraud) DESC 
    ) AS city_risk_rank 
FROM merchants m 
JOIN transactions t 
ON m.merchant_id = t.merchant_id 
JOIN fraud_labels f 
ON t.txn_id = f.txn_id 
GROUP BY m.merchant_city 
ORDER BY city_risk_rank; 

-- Different from user city (Q2) — merchant city shows where fraud is being received, user city shows where it's being initiated. Both together give complete geographic picture.
