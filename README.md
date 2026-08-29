# 📊 Online Retail Customer Segmentation & Data Mining with MySQL

[![MySQL](https://img.shields.io/badge/Database-MySQL%208.0-blue.svg?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![SQL](https://img.shields.io/badge/Language-SQL-orange.svg)]()
[![Domain](https://img.shields.io/badge/Domain-E--Commerce%20%7C%20Retail%20Analytics-green.svg)]()
[![Analysis](https://img.shields.io/badge/Techniques-RFM%20%7C%20Market%20Basket%20%7C%20Churn-purple.svg)]()

---

## 📌 Project Overview
This data mining and business intelligence project performs exploratory analysis, customer segmentation, and behavioral modeling on transactional e-commerce data using **MySQL**.

By leveraging SQL techniques such as Common Table Expressions (CTEs), self-joins, window functions, and time-based aggregations, this project derives actionable insights to improve customer retention, increase average order value (AOV), and optimize product cross-selling.

---

## 🎯 Key Objectives
* **Data Mining in SQL:** Formulate and execute structured queries to extract behavioral and financial patterns.
* **Customer Segmentation:** Classify customers into High, Medium, and Low frequency cohorts to enable targeted marketing.
* **Market Basket Analysis:** Identify commonly co-purchased items to recommend bundling strategies.
* **Churn & Lifecycle Tracking:** Detect at-risk and churned customers (>6 months inactivity) for win-back campaigns.
* **Revenue & Geographic Analysis:** Measure sales performance across countries and analyze monthly growth velocity.

---

## 🗄️ Dataset & Schema
The dataset consists of **13,116+ transactional records** across 8 key attributes:

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| InvoiceNo | VARCHAR(20) | Unique 6-digit transaction identifier. |
| StockCode | VARCHAR(20) | Unique product / item code. |
| Description | VARCHAR(255) | Product name and description. |
| Quantity | INT | Quantity of items purchased per transaction. |
| InvoiceDate | DATETIME | Timestamp of when the transaction occurred. |
| UnitPrice | DECIMAL(10,2) | Price per single unit of product. |
| CustomerID | INT | Unique identifier assigned to each customer. |
| Country | VARCHAR(100) | Country where the customer resides. |

---

## 📁 Repository Structure
`	ext
├── queries.sql                   # Complete executable MySQL queries (Basic & Advanced)
├── Data mining with mysql.docx   # Original project report & analysis documentation
└── README.md                     # Comprehensive project summary & business insights
`

---

## 🔍 Core Analysis & SQL Queries

### 1. Order Value Distribution Across Customers
`sql
SELECT 
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders,
    ROUND(SUM(Quantity * UnitPrice), 2) AS TotalOrderValue
FROM online_retail
WHERE CustomerID IS NOT NULL AND Quantity > 0
GROUP BY CustomerID
ORDER BY TotalOrderValue DESC;
`
* **Insight:** Identifies top-tier high-spending VIP customers who drive the majority of revenue versus low-spending occasional buyers.

---

### 2. Market Basket Analysis (Co-Purchased Products)
`sql
SELECT 
    a.StockCode AS Product_A,
    a.Description AS Description_A,
    b.StockCode AS Product_B,
    b.Description AS Description_B,
    COUNT(*) AS TimesPurchasedTogether
FROM online_retail a
JOIN online_retail b 
    ON a.InvoiceNo = b.InvoiceNo 
    AND a.StockCode < b.StockCode
WHERE a.Quantity > 0 AND b.Quantity > 0
GROUP BY a.StockCode, a.Description, b.StockCode, b.Description
ORDER BY TimesPurchasedTogether DESC
LIMIT 10;
`
* **Insight:** Surfaces complementary products frequently bought in the same checkout session, ideal for bundling discounts and checkout recommendation engines.

---

### 3. Customer Frequency Segmentation (RFM Tiering)
`sql
WITH CustomerFrequency AS (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS OrderCount,
        ROUND(SUM(Quantity * UnitPrice), 2) AS TotalSpend
    FROM online_retail
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
)
SELECT 
    CustomerID,
    OrderCount,
    TotalSpend,
    CASE 
        WHEN OrderCount >= 10 THEN 'High-Frequency (Loyal)'
        WHEN OrderCount BETWEEN 4 AND 9 THEN 'Medium-Frequency (Regular)'
        ELSE 'Low-Frequency (Occasional)'
    END AS CustomerSegment
FROM CustomerFrequency
ORDER BY OrderCount DESC;
`
* **Insight:** Categorizes customer base into actionable tiers for tailored loyalty rewards and frequency incentives.

---

### 4. Customer Churn Risk Analysis
`sql
WITH MaxDateRef AS (
    SELECT MAX(InvoiceDate) AS MaxDatasetDate FROM online_retail
),
CustomerRecency AS (
    SELECT 
        r.CustomerID,
        MAX(r.InvoiceDate) AS LastPurchaseDate,
        TIMESTAMPDIFF(MONTH, MAX(r.InvoiceDate), (SELECT MaxDatasetDate FROM MaxDateRef)) AS MonthsInactive,
        ROUND(SUM(r.Quantity * r.UnitPrice), 2) AS TotalHistoricalSpend
    FROM online_retail r
    WHERE r.CustomerID IS NOT NULL
    GROUP BY r.CustomerID
)
SELECT 
    CustomerID,
    LastPurchaseDate,
    MonthsInactive,
    TotalHistoricalSpend,
    CASE 
        WHEN MonthsInactive >= 6 THEN 'Churned (>= 6 Mos Inactive)'
        WHEN MonthsInactive BETWEEN 3 AND 5 THEN 'At-Risk (3-5 Mos)'
        ELSE 'Active (< 3 Mos)'
    END AS ChurnStatus
FROM CustomerRecency
ORDER BY MonthsInactive DESC;
`
* **Insight:** Provides an automated early-warning list of accounts that have lapsed for targeted re-engagement email promotions.

---

### 5. Average Order Value (AOV) by Country
`sql
SELECT 
    Country,
    COUNT(DISTINCT InvoiceNo) AS TotalInvoices,
    ROUND(SUM(Quantity * UnitPrice), 2) AS TotalRevenue,
    ROUND(SUM(Quantity * UnitPrice) / COUNT(DISTINCT InvoiceNo), 2) AS AverageOrderValue
FROM online_retail
WHERE Quantity > 0
GROUP BY Country
HAVING TotalInvoices >= 5
ORDER BY AverageOrderValue DESC;
`
* **Insight:** Identifies international markets with high purchasing power to optimize ad spend allocation.

---

## 📈 Strategic Business Recommendations

1. **Loyalty Programs for High-Frequency Accounts:**
   * Create dedicated VIP tiers, early product access, and point-based rewards for top customers ( \ge 10$).
2. **Dynamic Cross-Selling & Bundle Discounts:**
   * Implement automated cart suggestions based on top co-purchased product pairs discovered in the Market Basket Analysis.
3. **Automated Churn Prevention Campaigns:**
   * Set up automated re-engagement workflows at the 90-day mark with personalized coupons to recover at-risk customers before they hit 6 months of inactivity.
4. **Targeted Geographic Expansion:**
   * Double down on marketing budgets in regions demonstrating above-average AOV.

---

## 👤 Author
* **Aleeza Hussain**
* **Role:** AI & Data Science
* **GitHub:** [@Aeeza-Hussain](https://github.com/Aeeza-Hussain)
