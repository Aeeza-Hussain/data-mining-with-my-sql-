-- ====================================================================
-- Project: Online Retail Data Mining & Customer Segmentation
-- Author: Aleeza Hussain
-- Tool: MySQL / MySQL Workbench
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. DATABASE & SCHEMA SETUP
-- --------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS online_retail_db;
USE online_retail_db;

CREATE TABLE IF NOT EXISTS online_retail (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice DECIMAL(10, 2),
    CustomerID INT,
    Country VARCHAR(100)
);

-- --------------------------------------------------------------------
-- 2. DATA CLEANING & PREPARATION
-- --------------------------------------------------------------------

-- Address missing CustomerIDs and filter out returns/cancellations (Quantity <= 0)
-- View clean record count
SELECT COUNT(*) AS ValidTransactions
FROM online_retail
WHERE CustomerID IS NOT NULL 
  AND Quantity > 0 
  AND UnitPrice > 0;


-- --------------------------------------------------------------------
-- 3. CORE BUSINESS ANALYSIS QUERIES
-- --------------------------------------------------------------------

-- Question 1: What is the distribution of order values across all customers?
-- Calculates total order monetary value per customer in descending order
SELECT 
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders,
    SUM(Quantity) AS TotalItemsBought,
    ROUND(SUM(Quantity * UnitPrice), 2) AS TotalOrderValue
FROM online_retail
WHERE CustomerID IS NOT NULL AND Quantity > 0
GROUP BY CustomerID
ORDER BY TotalOrderValue DESC;

-- Question 2: How many unique products has each customer purchased?
-- Identifies if customers explore diverse product lines or are repeat buyers of the same items
SELECT 
    CustomerID,
    COUNT(DISTINCT StockCode) AS UniqueProductsPurchased,
    SUM(Quantity) AS TotalUnitsPurchased
FROM online_retail
WHERE CustomerID IS NOT NULL AND Quantity > 0
GROUP BY CustomerID
ORDER BY UniqueProductsPurchased DESC;

-- Question 3: Which customers have only made a single purchase?
-- Identifies first-time buyers vs repeat customers to evaluate retention
SELECT 
    CustomerID,
    MIN(InvoiceDate) AS FirstPurchaseDate,
    ROUND(SUM(Quantity * UnitPrice), 2) AS TotalSpent
FROM online_retail
WHERE CustomerID IS NOT NULL AND Quantity > 0
GROUP BY CustomerID
HAVING COUNT(DISTINCT InvoiceNo) = 1
ORDER BY TotalSpent DESC;

-- Question 4: Which products are most commonly purchased together?
-- Market Basket Analysis: Identifies top item pairs co-purchased in the same invoice
SELECT 
    a.StockCode AS Product_A_Code,
    a.Description AS Product_A_Name,
    b.StockCode AS Product_B_Code,
    b.Description AS Product_B_Name,
    COUNT(*) AS TimesPurchasedTogether
FROM online_retail a
JOIN online_retail b 
    ON a.InvoiceNo = b.InvoiceNo 
    AND a.StockCode < b.StockCode
WHERE a.Quantity > 0 
  AND b.Quantity > 0
  AND a.Description IS NOT NULL 
  AND b.Description IS NOT NULL
GROUP BY a.StockCode, a.Description, b.StockCode, b.Description
ORDER BY TimesPurchasedTogether DESC
LIMIT 10;


-- --------------------------------------------------------------------
-- 4. ADVANCED ANALYTICS & CUSTOMER SEGMENTATION
-- --------------------------------------------------------------------

-- Advanced 1: Customer Segmentation by Purchase Frequency
-- Classifies buyers into High-Frequency (Loyal), Medium-Frequency, and Low-Frequency tiers
WITH CustomerFrequency AS (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS OrderCount,
        ROUND(SUM(Quantity * UnitPrice), 2) AS TotalSpend
    FROM online_retail
    WHERE CustomerID IS NOT NULL AND Quantity > 0
    GROUP BY CustomerID
)
SELECT 
    CustomerID,
    OrderCount,
    TotalSpend,
    CASE 
        WHEN OrderCount >= 10 THEN 'High-Frequency (Loyal Customer)'
        WHEN OrderCount BETWEEN 4 AND 9 THEN 'Medium-Frequency (Regular Customer)'
        ELSE 'Low-Frequency (Occasional / New Customer)'
    END AS FrequencySegment
FROM CustomerFrequency
ORDER BY OrderCount DESC, TotalSpend DESC;

-- Advanced 2: Average Order Value (AOV) by Country
-- Highlights high-value geographic regions to inform marketing investments
SELECT 
    Country,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders,
    ROUND(SUM(Quantity * UnitPrice), 2) AS TotalRevenue,
    ROUND(SUM(Quantity * UnitPrice) / COUNT(DISTINCT InvoiceNo), 2) AS AverageOrderValue
FROM online_retail
WHERE Quantity > 0
GROUP BY Country
HAVING TotalOrders >= 5
ORDER BY AverageOrderValue DESC;

-- Advanced 3: Customer Churn Analysis (Recency > 6 Months)
-- Identifies accounts at risk of churn based on months since last transaction
WITH ReferenceDate AS (
    SELECT MAX(InvoiceDate) AS MaxDate FROM online_retail
),
CustomerActivity AS (
    SELECT 
        r.CustomerID,
        MAX(r.InvoiceDate) AS LastPurchaseDate,
        TIMESTAMPDIFF(MONTH, MAX(r.InvoiceDate), (SELECT MaxDate FROM ReferenceDate)) AS MonthsSinceLastPurchase,
        ROUND(SUM(r.Quantity * r.UnitPrice), 2) AS TotalMonetaryValue
    FROM online_retail r
    WHERE r.CustomerID IS NOT NULL AND r.Quantity > 0
    GROUP BY r.CustomerID
)
SELECT 
    CustomerID,
    LastPurchaseDate,
    MonthsSinceLastPurchase,
    TotalMonetaryValue,
    CASE 
        WHEN MonthsSinceLastPurchase >= 6 THEN 'Churned (>= 6 Months Inactive)'
        WHEN MonthsSinceLastPurchase BETWEEN 3 AND 5 THEN 'At Risk (3-5 Months Inactive)'
        ELSE 'Active (< 3 Months Inactive)'
    END AS ChurnStatus
FROM CustomerActivity
ORDER BY MonthsSinceLastPurchase DESC, TotalMonetaryValue DESC;

-- Advanced 4: Product Affinity Analysis
-- Discovers affinity patterns between frequently paired product categories
SELECT 
    a.Description AS PrimaryProduct,
    b.Description AS RecommendedProduct,
    COUNT(DISTINCT a.InvoiceNo) AS SharedOrderCount
FROM online_retail a
JOIN online_retail b 
    ON a.InvoiceNo = b.InvoiceNo 
    AND a.StockCode != b.StockCode
WHERE a.Quantity > 0 AND b.Quantity > 0
GROUP BY a.Description, b.Description
HAVING SharedOrderCount >= 10
ORDER BY SharedOrderCount DESC
LIMIT 20;

-- Advanced 5: Time-Based Trend Analysis (Monthly Revenue & Velocity)
-- Explores seasonal sales cycles, monthly revenue, and active customer trends
SELECT 
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS SalesMonth,
    COUNT(DISTINCT InvoiceNo) AS MonthlyOrders,
    COUNT(DISTINCT CustomerID) AS ActiveCustomerCount,
    SUM(Quantity) AS TotalUnitsSold,
    ROUND(SUM(Quantity * UnitPrice), 2) AS GrossRevenue
FROM online_retail
WHERE Quantity > 0
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY SalesMonth ASC;
