# UPI Transaction Fraud & Risk Analytics

**An end-to-end FinTech data analytics project** — from raw transaction generation to an executive-ready dashboard. Built to simulate the role of a Data Analyst inside a digital payments company's fraud and risk team.

`Python` · `PostgreSQL` · `Excel` · `Power BI`

---

## 📌 Problem Statement

Digital payment platforms in India process millions of UPI transactions daily. As volume grows, so does fraud — unauthorized transfers, account takeovers, and merchant-side fraud cause direct financial loss and erode customer trust. Most fraud detection in smaller FinTech operations is reactive, relying on customer complaints rather than proactive monitoring.

This project answers one core business question:

> **"Where is fraud happening, who is most at risk, and what should the business do about it?"**

---

## 🗂 Dataset Overview

A realistic synthetic dataset was generated using Python (Faker + NumPy) to simulate a UPI payments environment with embedded fraud patterns.

| Table | Rows | Key Columns |
|---|---|---|
| `transactions` | 50,000 | txn_id, user_id, merchant_id, amount, timestamp, status, channel |
| `users` | 5,000 | user_id, name, user_city, kyc_status, account_age_days |
| `merchants` | 500 | merchant_id, merchant_name, category, merchant_city, is_verified |
| `fraud_labels` | 50,000 | txn_id, is_fraud, fraud_type |
| `payment_failures` | 3,517 | txn_id, failure_reason, retry_count, resolved |

**Fraud rate:** 3.25% (1,624 fraudulent transactions out of 50,000)

**Engineered features:** `txn_hour`, `late_night_flag`, `amount_zscore`, `high_amount_flag`, `amount_bucket`, `account_cohort`, `merchant_fraud_rate`

---

## ⚙️ Tech Stack & Workflow

```
Raw Data Generation (Python)
        │
        ▼
Data Cleaning + Feature Engineering (Python)
        │
        ▼
Exploratory Data Analysis — 12 business questions (Python)
        │
        ▼
PostgreSQL  →  5 normalized tables  →  17 SQL business queries
        │
        ├──────────────────┬──────────────────┐
        ▼                                     ▼
  Excel Dashboard                      Power BI Dashboard
  (operational / row-level)             (3-page executive view)
```

| Stage | Tool | Purpose |
|---|---|---|
| Data generation | Python (Faker, NumPy) | Build a realistic synthetic dataset |
| Cleaning & EDA | Python (Pandas, Matplotlib, Seaborn) | Clean data, engineer features, answer 12 business questions |
| Database | PostgreSQL | Normalized schema, 17 business SQL queries |
| Operational dashboard | Excel (Power Query, PivotTables) | Row-level investigation tool for the operations team |
| Executive dashboard | Power BI | 3-page interactive dashboard for management decisions |

---

## 📊 Exploratory Data Analysis (Python)

All five raw tables were merged into a single master DataFrame, cleaned, and enriched with engineered features. Twelve business questions were then answered using Pandas, Matplotlib, and Seaborn.

**Questions explored:** city-level fraud rate · time-of-day risk · merchant category risk · fraud vs. legitimate amount patterns · KYC status impact · monthly trend · payment channel risk · top risky merchants · transaction status distribution · high-value transaction risk · device-type risk · new-vs-established account risk

### Sample Findings

**Fraud peaks in the early morning hours (12AM–4AM)**

![Peak fraud hours](https://github.com/mahesh735-ai/UPI-Transaction-Fraud-Risk-Analytics/blob/main/Peak%20fraud%20hours.png)

> Fraud activity peaks when user monitoring is lowest — these transactions should trigger automatic step-up authentication or temporary holds.

**Debit Card carries the highest fraud rate among all channels**

![Fraud rate by channel](https://github.com/mahesh735-ai/UPI-Transaction-Fraud-Risk-Analytics/blob/main/Fraud%20rate%20by%20channel.png)

> Debit Card shows the highest fraud rate (3.73%) while Wallet is the safest channel — stronger authentication should be prioritized for Debit Card, particularly for high-value payments.

---

## 🗄 SQL Analysis (PostgreSQL)

Cleaned data was loaded into a **normalized 5-table relational schema** with primary/foreign keys and indexes. Seventeen business queries were written covering aggregation, multi-table joins, CTEs, and window functions (`RANK()`, `LAG()`).

### Query Highlights

| # | Business Question | SQL Concept |
|---|---|---|
| Q1 | Overall fraud KPI summary | Aggregation, CASE |
| Q4 | Top 10 riskiest merchants | JOIN, HAVING, LIMIT |
| Q7 | Is fraud increasing or decreasing month over month? | CTE, `LAG()` window function |
| Q8 | Which users show 5+ transactions within 1 hour? | CTE, `COUNT() OVER`, `LAG()` |
| Q9 | Risk labeling: CRITICAL / HIGH / MEDIUM / LOW | CTE, CASE risk scoring |
| Q15 | Verified vs. unverified merchant risk | JOIN, `COUNT(DISTINCT)` |
| Q17 | Merchant city fraud concentration | JOIN, `RANK()` window function |

Full query set: [`sql/business_queries.sql`](sql/business_queries.sql) · Schema: [`sql/schema.sql`](sql/schema.sql)

---

## 📗 Operational Dashboard — Excel

Built for the **operations team** — a row-level investigation tool rather than an executive summary, connected to the cleaned transaction-level data via Power Query.

![Excel Dashboard](https://github.com/mahesh735-ai/UPI-Transaction-Fraud-Risk-Analytics/blob/main/Excel_Dashboard.png)

- 4 KPI cards: Total Transactions, Fraud Rate %, Total Fraud Loss, High Risk Transactions
- Fraud Rate by City and by Merchant (sorted bar charts)
- Channel: Total vs. Fraud Transactions (dual-axis)
- Fraud Rate by Hour and Monthly Fraud Trend (line charts)
- Slicers: Channel, City, Month, KYC Status — connected across all PivotTables

---

## 📘 Executive Dashboard — Power BI

A 3-page interactive dashboard built on the same PostgreSQL schema for **senior management**, with each page targeting a different audience and decision.

### Page 1 — Executive Overview
*Top-level KPIs and trends: overall fraud rate, failure rate, total fraud loss, fraud by city and channel.*

![Power BI Page 1](https://github.com/mahesh735-ai/UPI-Transaction-Fraud-Risk-Analytics/blob/main/Executive%20Overview.png)

### Page 2 — Merchant Risk Analysis
*For the fraud and merchant-relations team: highest-risk merchants, category risk, city-level fraud heatmap.*

![Power BI Page 2](https://github.com/mahesh735-ai/UPI-Transaction-Fraud-Risk-Analytics/blob/main/Merchant%20Risk%20Analysis.png)

### Page 3 — User Risk Profiles
*For the risk and compliance team: fraud by KYC status and account cohort, age-group risk, ranked high-risk user table.*

![Power BI Page 3](https://github.com/mahesh735-ai/UPI-Transaction-Fraud-Risk-Analytics/blob/main/User%20Risk%20Profiles.png)

A single **Dark Navy / Teal / Gold / Red** theme was applied consistently across Python charts, Excel, and all Power BI pages — red always signals fraud/risk, teal signals safety, gold flags warnings.

---

## 🔍 Key Insights

| # | Finding |
|---|---|
| 1 | Fraud peaks between 12 AM and 4 AM — a clear window for step-up authentication |
| 2 | Debit Card has the highest channel fraud rate (3.73%); Wallet is the safest |
| 3 | Top 10 riskiest merchants show fraud rates of 7.4%–9.4% — roughly 2–3x the platform average |
| 4 | Unverified merchants show a modestly higher fraud rate (3.42%) vs. verified (3.22%) |
| 5 | KYC status alone is not a strong fraud predictor — behavioral signals matter more |
| 6 | New and established accounts show similar fraud rates — fraud isn't limited to new sign-ups |

---

## 💡 Business Recommendations

| Finding | Recommended Action |
|---|---|
| Late-night fraud concentration (12 AM–4 AM) | Apply step-up authentication (OTP) on large transactions in this window |
| Debit Card has the highest channel fraud rate | Add extra verification for high-value Debit Card transactions |
| Top 10 merchants drive disproportionate fraud loss | Flag for manual review; consider reduced settlement limits |
| Unverified merchants carry higher exposure | Tighten onboarding verification before activating new merchants |
| Payment failures cause measurable revenue leakage | Investigate top failure reasons (e.g. server timeouts) as an engineering priority |

---

## 📁 Repository Structure

```
upi-fraud-risk-analytics/
├── README.md
├── notebooks/
│   ├── 01_data_generation.ipynb
│   ├── 02_eda_cleaning.ipynb
│   └── 03_excel_data_prep.ipynb
├── sql/
│   ├── schema.sql
│   └── business_queries.sql
├── excel/
│   └── excel_dashboard.xlsx
├── powerbi/
│   └── upi_fraud_risk_analytics.pbix
├── reports/
│   └── UPI_Fraud_Risk_Analytics_Report.docx
├── data/
│   ├── raw/          (5 original synthetic CSVs)
│   └── cleaned/       (5 cleaned CSVs)
└── images/            (dashboard & chart screenshots used in this README)
```

---

## ▶️ How to Run

1. Run `notebooks/01_data_generation.ipynb` to generate the 5 raw CSVs
2. Run `notebooks/02_eda_cleaning.ipynb` for cleaning, feature engineering, and EDA
3. Execute `sql/schema.sql` in PostgreSQL, then load the cleaned CSVs into the 5 tables
4. Run `sql/business_queries.sql` to reproduce the 17 business queries
5. Run `notebooks/03_excel_data_prep.ipynb` to generate the Excel-ready merged dataset
6. Open `excel/excel_dashboard.xlsx` and refresh the Power Query connection
7. Open `powerbi/upi_fraud_risk_analytics.pbix` and refresh the PostgreSQL connection

**Requirements:** Python 3.x · `pandas`, `numpy`, `matplotlib`, `seaborn`, `faker`, `sqlalchemy`, `psycopg2-binary` · PostgreSQL 14+ · Microsoft Excel · Power BI Desktop

---

## 📄 Full Report

A detailed write-up with all charts, SQL query screenshots, and dashboard pages is available here: [`reports/UPI_Fraud_Risk_Analytics_Report.docx`](https://github.com/mahesh735-ai/UPI-Transaction-Fraud-Risk-Analytics/blob/main/UPI_Fraud_Risk_Analytics_Report.docx)

---

## 👤 Author

**Mahesh Thakare**
Aspiring Data Analyst | Data Science & AI (IIT Roorkee Certification via Masai School)

[LinkedIn](www.linkedin.com/in/mahesh-thakare-75817b2a7) · [GitHub](https://github.com/mahesh735-ai)

