-- ==========================================================
-- Credit Card Transaction Analysis
-- Data Exploration
--
-- Objective:
-- Explore the dataset to understand its size, customer base,
-- merchant coverage, and overall transaction activity before 
--performing deeper analysis.
-- ==========================================================

-- ==========================================================
-- SECTION 1: DATA EXPLORATION
-- ==========================================================

-- ----------------------------------------------------------
-- Query 1: Total Number of Transactions
--
-- Business Question:
-- How many transaction records are in the dataset?
--
-- Insight:
-- This helps determine the overall scale of the dataset.
-- ----------------------------------------------------------

SELECT COUNT(*) AS total_transactions
FROM transactions;

-- ----------------------------------------------------------
-- Query 2: Unique Customers
--
-- Business Question:
-- How many unique customers made transactions?
--
-- Insight:
-- Understanding the customer base helps measure customer
-- activity and calculate future customer metrics.
-- ----------------------------------------------------------

SELECT COUNT(DISTINCT client_id) AS unique_customers
FROM transactions;


-- ----------------------------------------------------------
-- Query 3: Unique Merchants
--
-- Business Question:
-- How many unique merchants processed transactions?
-- Insight:
-- This measures the size and diversity of the merchant network.
-- ----------------------------------------------------------

SELECT COUNT(DISTINCT merchant_id) AS merchants
FROM transactions;

-- ----------------------------------------------------------
-- Query 4: Average Transaction Amount
--
-- Business Question:
-- What is the average dollar amount per transaction?
--
-- Note:
-- The amount column is stored as text (e.g. "$42.98"),
-- so REPLACE() removes the "$" and CAST() converts the
-- value into a numeric data type.
-- ----------------------------------------------------------

SELECT
ROUND(AVG(CAST(REPLACE(amount,'$','') AS REAL)),2) AS average_transaction
FROM transactions;

-- ==========================================================
-- SECTION 2: CUSTOMER ANALYSIS
-- ==========================================================

-- ----------------------------------------------------------
-- Query 5: Top Customers by Total Spending
--
-- Business Question:
-- Which customers generated the highest total spending?
--
-- Insight:
-- Identifies high-value customers based on cumulative
-- transaction amounts.
-- ----------------------------------------------------------

SELECT
client_id,
ROUND(SUM(CAST(REPLACE(amount,'$','') AS REAL)),2) AS total_spent
FROM transactions
GROUP BY client_id
ORDER BY total_spent DESC
LIMIT 10;

-- ----------------------------------------------------------
-- Query 6: Average Lifetime Spending per Customer
--
-- Business Question:
-- What is the average amount spent by each customer over
-- the lifetime of the dataset?
--
-- Why this matters:
-- This provides a benchmark for comparing individual
-- customers against the overall customer base and helps
-- identify unusually high-value customers.
-- ----------------------------------------------------------

SELECT
ROUND(AVG(total_spent),2) AS avg_customer_spend
FROM (
    SELECT
    client_id,
    SUM(CAST(REPLACE(amount,'$','') AS REAL)) AS total_spent
    FROM transactions
    GROUP BY client_id
);

-- ----------------------------------------------------------
-- Query 7: Customer Spending Segmentation
--
-- Business Question:
-- How are customers distributed based on their total
-- lifetime spending?
--
-- Why this matters:
-- Helps identify high-value vs low-value customers for
-- business strategy and marketing.
-- ----------------------------------------------------------

SELECT
    CASE
        WHEN total_spent < 100000 THEN 'Under $100k'
        WHEN total_spent < 500000 THEN '$100k - $500k'
        WHEN total_spent < 1000000 THEN '$500k - $1M'
        ELSE 'Over $1M'
    END AS spending_segment,
    COUNT(*) AS customers
FROM (
    SELECT
        client_id,
        SUM(CAST(REPLACE(amount,'$','') AS REAL)) AS total_spent
    FROM transactions
    GROUP BY client_id
)
GROUP BY spending_segment
ORDER BY customers DESC;

-- ==========================================================
-- SECTION 3: DEMOGRAPHICS (USERS JOIN)
-- ==========================================================

-- Age vs Number of Transactions
SELECT
    u.current_age,
    COUNT(*) AS transactions
FROM transactions t
JOIN users u
ON t.client_id = u.id
GROUP BY u.current_age
ORDER BY transactions DESC;


-- Age vs Total Spending
SELECT
    u.current_age,
    ROUND(SUM(CAST(REPLACE(t.amount,'$','') AS REAL)),2) AS total_spent
FROM transactions t
JOIN users u
ON t.client_id = u.id
GROUP BY u.current_age
ORDER BY total_spent DESC
LIMIT 10;

-- ==========================================================
-- SECTION 4: CREDIT SCORE ANALYSIS
-- ==========================================================

SELECT
    CASE
        WHEN u.credit_score < 600 THEN 'Poor'
        WHEN u.credit_score < 700 THEN 'Fair'
        WHEN u.credit_score < 750 THEN 'Good'
        ELSE 'Excellent'
    END AS credit_group,
    ROUND(AVG(CAST(REPLACE(t.amount,'$','') AS REAL)),2) AS avg_transaction,
    COUNT(*) AS transactions
FROM transactions t
JOIN users u
ON t.client_id = u.id
GROUP BY credit_group;

-- ==========================================================
-- SECTION 5: INCOME VS SPENDING BEHAVIOR
-- ==========================================================

SELECT
    CASE
        WHEN u.yearly_income < 50000 THEN 'Low Income'
        WHEN u.yearly_income BETWEEN 50000 AND 100000 THEN 'Middle Income'
        ELSE 'High Income'
    END AS income_group,
    COUNT(DISTINCT u.id) AS customers,
    ROUND(AVG(t.total_spent),2) AS avg_spending
FROM users u
JOIN (
    SELECT
        client_id,
        SUM(CAST(REPLACE(amount,'$','') AS REAL)) AS total_spent
    FROM transactions
    GROUP BY client_id
) t
ON u.id = t.client_id
GROUP BY income_group;