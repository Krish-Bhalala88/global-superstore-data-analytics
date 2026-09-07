-- ============================================================
-- GLOBAL SUPERSTORE SALES ANALYTICS
-- MySQL 8.x / XAMPP compatible
-- Run this file section-by-section in MySQL Workbench/phpMyAdmin.
-- ============================================================

CREATE DATABASE IF NOT EXISTS superstore_analytics;
USE superstore_analytics;

DROP VIEW IF EXISTS sales_analysis;

DROP TABLE IF EXISTS superstore;

CREATE TABLE superstore (
    Category VARCHAR(100),
    City VARCHAR(150),
    Country VARCHAR(150),
    Customer_ID VARCHAR(50),
    Customer_Name VARCHAR(200),
    Discount DECIMAL(10,4),
    Market VARCHAR(50),
    record_count INT,
    Order_Date DATETIME,
    Order_ID VARCHAR(60),
    Order_Priority VARCHAR(30),
    Product_ID VARCHAR(60),
    Product_Name VARCHAR(300),
    Profit DECIMAL(18,4),
    Quantity INT,
    Region VARCHAR(100),
    Row_ID INT PRIMARY KEY,
    Sales DECIMAL(18,4),
    Segment VARCHAR(50),
    Ship_Date DATETIME,
    Ship_Mode VARCHAR(60),
    Shipping_Cost DECIMAL(18,4),
    State VARCHAR(150),
    Sub_Category VARCHAR(100),
    Year INT,
    Market2 VARCHAR(100),
    weeknum INT
);

-- IMPORTANT:
-- Put superstore.csv in an accessible local folder and replace the path below.
-- Example Windows:
-- 'C:/Users/YourName/Downloads/superstore.csv'
-- If LOCAL INFILE is disabled in your MySQL installation, enable local_infile
-- or import the CSV through phpMyAdmin, then start from the DATA QUALITY section.

LOAD DATA LOCAL INFILE 'C:/Users/YourName/Downloads/superstore.csv'
INTO TABLE superstore
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Category, City, Country, Customer_ID, Customer_Name, Discount, Market,
 record_count, @Order_Date, Order_ID, Order_Priority, Product_ID, Product_Name,
 Profit, Quantity, Region, Row_ID, Sales, Segment, @Ship_Date, Ship_Mode,
 Shipping_Cost, State, Sub_Category, Year, Market2, weeknum)
SET
    Order_Date = STR_TO_DATE(@Order_Date, '%Y-%m-%d %H:%i:%s.%f'),
    Ship_Date = STR_TO_DATE(@Ship_Date, '%Y-%m-%d %H:%i:%s.%f');

-- ============================================================
-- 1. DATA QUALITY
-- ============================================================

SELECT COUNT(*) AS total_rows FROM superstore;

SELECT COUNT(DISTINCT Row_ID) AS unique_row_ids,
       COUNT(*) - COUNT(DISTINCT Row_ID) AS duplicate_row_ids
FROM superstore;

SELECT
    SUM(Category IS NULL) AS missing_category,
    SUM(Sales IS NULL) AS missing_sales,
    SUM(Profit IS NULL) AS missing_profit,
    SUM(Customer_ID IS NULL) AS missing_customer,
    SUM(Order_ID IS NULL) AS missing_order,
    SUM(Order_Date IS NULL) AS missing_order_date,
    SUM(Ship_Date IS NULL) AS missing_ship_date
FROM superstore;

SELECT MIN(Order_Date) AS first_order_date,
       MAX(Order_Date) AS last_order_date
FROM superstore;

-- ============================================================
-- 2. ANALYTICAL VIEW
-- ============================================================

CREATE OR REPLACE VIEW sales_analysis AS
SELECT
    s.*,
    YEAR(Order_Date) AS Order_Year,
    MONTH(Order_Date) AS Order_Month,
    MONTHNAME(Order_Date) AS Order_Month_Name,
    DATEDIFF(Ship_Date, Order_Date) AS Shipping_Days,
    CASE
        WHEN Profit > 0 THEN 'Profitable'
        WHEN Profit < 0 THEN 'Loss'
        ELSE 'Break Even'
    END AS Profit_Status,
    CASE
        WHEN Discount = 0 THEN '0%'
        WHEN Discount <= 0.10 THEN '1-10%'
        WHEN Discount <= 0.20 THEN '11-20%'
        WHEN Discount <= 0.30 THEN '21-30%'
        ELSE '31%+'
    END AS Discount_Band
FROM superstore s;

-- ============================================================
-- 3. EXECUTIVE KPIs
-- ============================================================

SELECT
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales),0) * 100, 2) AS Profit_Margin_Pct,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    COUNT(DISTINCT Customer_ID) AS Total_Customers,
    SUM(Quantity) AS Total_Quantity,
    ROUND(SUM(Sales) / NULLIF(COUNT(DISTINCT Order_ID),0), 2) AS Average_Order_Value,
    ROUND(AVG(Shipping_Days), 2) AS Average_Shipping_Days
FROM sales_analysis;

-- ============================================================
-- 4. CATEGORY / SUB-CATEGORY
-- ============================================================

SELECT Category, SUM(Sales) Sales, SUM(Profit) Profit, SUM(Quantity) Quantity,
       ROUND(SUM(Profit)/NULLIF(SUM(Sales),0)*100,2) Profit_Margin_Pct
FROM sales_analysis
GROUP BY Category ORDER BY Sales DESC;

SELECT Sub_Category, SUM(Sales) Sales, SUM(Profit) Profit, SUM(Quantity) Quantity,
       ROUND(SUM(Profit)/NULLIF(SUM(Sales),0)*100,2) Profit_Margin_Pct
FROM sales_analysis
GROUP BY Sub_Category ORDER BY Profit DESC;

SELECT Sub_Category, SUM(Sales) Sales, SUM(Profit) Profit
FROM sales_analysis
GROUP BY Sub_Category
HAVING SUM(Profit) < 0
ORDER BY Profit ASC;

-- ============================================================
-- 5. CUSTOMER ANALYSIS
-- ============================================================

SELECT Customer_ID, Customer_Name, Segment,
       SUM(Sales) Sales, SUM(Profit) Profit,
       COUNT(DISTINCT Order_ID) Orders
FROM sales_analysis
GROUP BY Customer_ID, Customer_Name, Segment
ORDER BY Sales DESC
LIMIT 20;

SELECT Customer_ID, Customer_Name, Segment,
       SUM(Sales) Sales, SUM(Profit) Profit,
       COUNT(DISTINCT Order_ID) Orders
FROM sales_analysis
GROUP BY Customer_ID, Customer_Name, Segment
ORDER BY Profit DESC
LIMIT 20;

SELECT Customer_ID, Customer_Name,
       SUM(Sales) Sales, SUM(Profit) Profit
FROM sales_analysis
GROUP BY Customer_ID, Customer_Name
HAVING SUM(Profit) < 0
ORDER BY Profit ASC;

-- ============================================================
-- 6. PRODUCT ANALYSIS
-- ============================================================

SELECT Product_ID, Product_Name,
       SUM(Sales) Sales, SUM(Profit) Profit, SUM(Quantity) Quantity
FROM sales_analysis
GROUP BY Product_ID, Product_Name
ORDER BY Sales DESC
LIMIT 20;

SELECT Product_ID, Product_Name,
       SUM(Sales) Sales, SUM(Profit) Profit, SUM(Quantity) Quantity
FROM sales_analysis
GROUP BY Product_ID, Product_Name
ORDER BY Profit DESC
LIMIT 20;

SELECT Product_ID, Product_Name,
       SUM(Sales) Sales, SUM(Profit) Profit, SUM(Quantity) Quantity
FROM sales_analysis
GROUP BY Product_ID, Product_Name
ORDER BY Profit ASC
LIMIT 20;

-- ============================================================
-- 7. REGION / MARKET / COUNTRY / STATE
-- ============================================================

SELECT Region, SUM(Sales) Sales, SUM(Profit) Profit,
       ROUND(SUM(Profit)/NULLIF(SUM(Sales),0)*100,2) Profit_Margin_Pct
FROM sales_analysis
GROUP BY Region ORDER BY Profit DESC;

SELECT Market, SUM(Sales) Sales, SUM(Profit) Profit,
       ROUND(SUM(Profit)/NULLIF(SUM(Sales),0)*100,2) Profit_Margin_Pct
FROM sales_analysis
GROUP BY Market ORDER BY Sales DESC;

SELECT Country, SUM(Sales) Sales, SUM(Profit) Profit
FROM sales_analysis
GROUP BY Country ORDER BY Sales DESC
LIMIT 30;

SELECT State, SUM(Sales) Sales, SUM(Profit) Profit
FROM sales_analysis
GROUP BY State ORDER BY Profit ASC
LIMIT 30;

-- ============================================================
-- 8. SEGMENT / SHIPPING / PRIORITY
-- ============================================================

SELECT Segment, COUNT(DISTINCT Customer_ID) Customers,
       COUNT(DISTINCT Order_ID) Orders, SUM(Sales) Sales, SUM(Profit) Profit
FROM sales_analysis
GROUP BY Segment ORDER BY Profit DESC;

SELECT Ship_Mode, COUNT(DISTINCT Order_ID) Orders,
       SUM(Sales) Sales, SUM(Profit) Profit,
       ROUND(AVG(Shipping_Days),2) Avg_Shipping_Days
FROM sales_analysis
GROUP BY Ship_Mode ORDER BY Profit DESC;

SELECT Order_Priority, COUNT(DISTINCT Order_ID) Orders,
       SUM(Sales) Sales, SUM(Profit) Profit
FROM sales_analysis
GROUP BY Order_Priority ORDER BY Profit DESC;

-- ============================================================
-- 9. TIME SERIES
-- ============================================================

SELECT Order_Year, SUM(Sales) Sales, SUM(Profit) Profit,
       COUNT(DISTINCT Order_ID) Orders
FROM sales_analysis
GROUP BY Order_Year ORDER BY Order_Year;

SELECT Order_Year, Order_Month, Order_Month_Name,
       SUM(Sales) Sales, SUM(Profit) Profit
FROM sales_analysis
GROUP BY Order_Year, Order_Month, Order_Month_Name
ORDER BY Order_Year, Order_Month;

-- ============================================================
-- 10. DISCOUNT ANALYSIS
-- ============================================================

SELECT Discount, COUNT(*) Transactions,
       SUM(Sales) Sales, SUM(Profit) Profit,
       ROUND(SUM(Profit)/NULLIF(SUM(Sales),0)*100,2) Profit_Margin_Pct
FROM sales_analysis
GROUP BY Discount ORDER BY Discount;

SELECT Discount_Band, COUNT(*) Transactions,
       SUM(Sales) Sales, SUM(Profit) Profit,
       ROUND(SUM(Profit)/NULLIF(SUM(Sales),0)*100,2) Profit_Margin_Pct
FROM sales_analysis
GROUP BY Discount_Band
ORDER BY MIN(Discount);

-- ============================================================
-- 11. CASE WHEN / BUSINESS SEGMENTATION
-- ============================================================

SELECT
    Product_ID,
    Product_Name,
    SUM(Sales) Sales,
    SUM(Profit) Profit,
    CASE
        WHEN SUM(Profit) < 0 THEN 'Loss Making'
        WHEN SUM(Profit)/NULLIF(SUM(Sales),0) < 0.05 THEN 'Low Margin'
        WHEN SUM(Profit)/NULLIF(SUM(Sales),0) < 0.15 THEN 'Medium Margin'
        ELSE 'High Margin'
    END AS Profitability_Segment
FROM sales_analysis
GROUP BY Product_ID, Product_Name
ORDER BY Profit ASC
LIMIT 50;

-- ============================================================
-- 12. CTE
-- ============================================================

WITH category_profit AS (
    SELECT Category, SUM(Sales) Sales, SUM(Profit) Profit
    FROM sales_analysis
    GROUP BY Category
)
SELECT Category, Sales, Profit,
       ROUND(Profit/NULLIF(Sales,0)*100,2) Profit_Margin_Pct
FROM category_profit
ORDER BY Profit DESC;

-- ============================================================
-- 13. SUBQUERY
-- Products whose profit is below the average product profit
-- ============================================================

SELECT Product_ID, Product_Name, SUM(Profit) Profit
FROM sales_analysis
GROUP BY Product_ID, Product_Name
HAVING SUM(Profit) < (
    SELECT AVG(Product_Profit)
    FROM (
        SELECT SUM(Profit) Product_Profit
        FROM sales_analysis
        GROUP BY Product_ID
    ) p
)
ORDER BY Profit ASC
LIMIT 20;

-- ============================================================
-- 14. WINDOW FUNCTIONS
-- ============================================================

WITH product_profit AS (
    SELECT Product_ID, Product_Name, SUM(Sales) Sales, SUM(Profit) Profit
    FROM sales_analysis
    GROUP BY Product_ID, Product_Name
)
SELECT *,
       RANK() OVER (ORDER BY Profit DESC) AS Profit_Rank,
       DENSE_RANK() OVER (ORDER BY Sales DESC) AS Sales_Rank
FROM product_profit
ORDER BY Profit_Rank;

WITH region_product AS (
    SELECT Region, Product_ID, Product_Name, SUM(Profit) Profit
    FROM sales_analysis
    GROUP BY Region, Product_ID, Product_Name
)
SELECT *,
       RANK() OVER (PARTITION BY Region ORDER BY Profit DESC) AS Region_Product_Rank
FROM region_product;

WITH monthly_sales AS (
    SELECT Order_Year, Order_Month,
           SUM(Sales) Sales
    FROM sales_analysis
    GROUP BY Order_Year, Order_Month
)
SELECT *,
       SUM(Sales) OVER (
           ORDER BY Order_Year, Order_Month
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS Running_Sales,
       LAG(Sales) OVER (
           ORDER BY Order_Year, Order_Month
       ) AS Previous_Month_Sales
FROM monthly_sales
ORDER BY Order_Year, Order_Month;

-- ============================================================
-- 15. ADVANCED BUSINESS QUESTIONS
-- ============================================================

-- High sales but negative profit products
SELECT Product_ID, Product_Name,
       SUM(Sales) Sales, SUM(Profit) Profit
FROM sales_analysis
GROUP BY Product_ID, Product_Name
HAVING SUM(Sales) > (SELECT AVG(Product_Sales)
                     FROM (SELECT SUM(Sales) Product_Sales
                           FROM sales_analysis GROUP BY Product_ID) x)
   AND SUM(Profit) < 0
ORDER BY Sales DESC;

-- Loss-making states
SELECT State, SUM(Sales) Sales, SUM(Profit) Profit
FROM sales_analysis
GROUP BY State
HAVING SUM(Profit) < 0
ORDER BY Profit ASC;

-- Customers with sales above average customer sales
WITH customer_sales AS (
    SELECT Customer_ID, Customer_Name, SUM(Sales) Sales, SUM(Profit) Profit
    FROM sales_analysis
    GROUP BY Customer_ID, Customer_Name
)
SELECT *
FROM customer_sales
WHERE Sales > (SELECT AVG(Sales) FROM customer_sales)
ORDER BY Sales DESC;

-- ============================================================
-- 16. FINAL MANAGEMENT SUMMARY
-- ============================================================

SELECT
    Category,
    SUM(Sales) AS Sales,
    SUM(Profit) AS Profit,
    ROUND(SUM(Profit)/NULLIF(SUM(Sales),0)*100,2) AS Profit_Margin_Pct,
    CASE
        WHEN SUM(Profit) < 0 THEN 'Immediate review'
        WHEN SUM(Profit)/NULLIF(SUM(Sales),0) < 0.10 THEN 'Improve margin'
        ELSE 'Maintain / scale'
    END AS Management_Action
FROM sales_analysis
GROUP BY Category
ORDER BY Profit DESC;
