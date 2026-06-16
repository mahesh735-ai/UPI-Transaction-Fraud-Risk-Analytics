-- ============================================================
-- FILE    : schema.sql
-- PROJECT : UPI Transaction Fraud & Risk Analytics
-- DB      : "UPI_Fraud_DB"
-- ============================================================

-- Create Database (run this separately in pgAdmin)
CREATE DATABASE UPI_Fraud_DB;
use UPI_Fraud_DB;
-- Drop tables if exist (safe re-run)
DROP TABLE IF EXISTS payment_failures;
DROP TABLE IF EXISTS fraud_labels;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS merchants;
DROP TABLE IF EXISTS users;

-- ── Table 1: Users ───────────────────────────────────────────
CREATE TABLE users (
    user_id           VARCHAR(10)  PRIMARY KEY,
    name              VARCHAR(100) NOT NULL,
    user_city         VARCHAR(50),
    age_group         VARCHAR(10),
    account_age_days  INTEGER,
    kyc_status        VARCHAR(20),
    user_reg_date     DATE,
    new_account_flag  INTEGER,      -- 1 = new (<90 days), 0 = established
    account_cohort    VARCHAR(30)   -- New / Growing / Established
);

-- ── Table 2: Merchants ───────────────────────────────────────
CREATE TABLE merchants (
    merchant_id        VARCHAR(10)  PRIMARY KEY,
    merchant_name      VARCHAR(150) NOT NULL,
    category           VARCHAR(50),
    merchant_city      VARCHAR(50),
    merchant_reg_date  DATE,
    is_verified        BOOLEAN,
    merchant_fraud_rate DECIMAL(6,4) -- pre-calculated fraud rate  -- (8,6) use this instead of 6,4 cuz in importing time get error
);

-- now need changes for safely import csv
ALTER TABLE merchants
MODIFY merchant_fraud_rate DECIMAL(8,6);

-- ── Table 3: Transactions ────────────────────────────────────
CREATE TABLE transactions (
    txn_id           VARCHAR(12)  PRIMARY KEY,
    user_id          VARCHAR(10)  REFERENCES users(user_id),
    merchant_id      VARCHAR(10)  REFERENCES merchants(merchant_id),
    amount           DECIMAL(10,2) NOT NULL,
    timestamp        TIMESTAMP    NOT NULL,
    status           VARCHAR(15),  -- Success/Failed/Pending/Reversed
    channel          VARCHAR(15),  -- UPI/Wallet/Debit Card/Credit Card
    device_type      VARCHAR(10),  -- Mobile/Desktop/Tablet
    txn_hour         INTEGER,      -- 0-23
    txn_day          VARCHAR(10),  -- Monday, Tuesday...
    txn_month        INTEGER,      -- 1-12
    txn_month_name   VARCHAR(5),   -- Jan, Feb...
    late_night_flag  INTEGER,      -- 1 = between 11PM-4AM
    amount_zscore    DECIMAL(8,4), -- outlier detection score
    high_amount_flag INTEGER,      -- 1 = zscore > 3
    amount_bucket    VARCHAR(25)   -- Small/Medium/Large/Very Large
);

-- ── Table 4: Fraud Labels ────────────────────────────────────
CREATE TABLE fraud_labels (
    txn_id      VARCHAR(12) PRIMARY KEY
                REFERENCES transactions(txn_id),
    is_fraud    INTEGER     NOT NULL,  -- 1 = fraud, 0 = legit
    fraud_type  VARCHAR(50)            -- NULL if not fraud
);

-- ── Table 5: Payment Failures ────────────────────────────────
CREATE TABLE payment_failures (
    txn_id          VARCHAR(12) PRIMARY KEY
                    REFERENCES transactions(txn_id),
    failure_reason  VARCHAR(100),
    retry_count     INTEGER,
    resolved        VARCHAR(10)  -- True/False/N/A
);

-- ── Indexes for faster queries ───────────────────────────────
-- CREATE INDEX idx_txn_user     ON transactions(user_id);
-- CREATE INDEX idx_txn_merchant ON transactions(merchant_id);
-- CREATE INDEX idx_txn_status   ON transactions(status);
-- CREATE INDEX idx_txn_timestamp ON transactions(timestamp);
-- CREATE INDEX idx_fraud_label  ON fraud_labels(is_fraud);



SELECT * FROM fraud_labels;

SELECT * FROM merchants;

SELECT * FROM payment_failures;

SELECT * FROM transactions;

SELECT * FROM users;

--- Now .Import all csv in each table

SELECT * FROM fraud_labels LIMIT 10;
SELECT * FROM merchants LIMIT 10;
SELECT * FROM payment_failures LIMIT 10;
SELECT * FROM transactions LIMIT 10;
SELECT * FROM users LIMIT 10;