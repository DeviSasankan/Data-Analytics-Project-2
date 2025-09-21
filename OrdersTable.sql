Select *
From dbo.Orders
--*************************************************************

-- a. Data Examination and Cleaning

-- 1. Check for NULLs in key fields
SELECT 
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS NullCustomerID,
    SUM(CASE WHEN OrderNumber IS NULL THEN 1 ELSE 0 END) AS NullOrderNumber,
    SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS NullOrderDate,
    SUM(CASE WHEN ProductCode IS NULL THEN 1 ELSE 0 END) AS NullProductCode,
    SUM(CASE WHEN UnitSales IS NULL THEN 1 ELSE 0 END) AS NullUnitSales,
    SUM(CASE WHEN OriginalPrice IS NULL THEN 1 ELSE 0 END) AS NullOriginalPrice,
    SUM(CASE WHEN DiscountedPrice IS NULL THEN 1 ELSE 0 END) AS NullDiscountedPrice,
    SUM(CASE WHEN NetSales IS NULL THEN 1 ELSE 0 END) AS NullNetSales,
    SUM(CASE WHEN GrossProfit IS NULL THEN 1 ELSE 0 END) AS NullGrossProfit
FROM dbo.Orders;

--Handling NULL/Missing values
-- ===========================
-- STEP 1: FIX NULL NetSales
-- ===========================

-- Only update if UnitSales and DiscountedPrice are available
UPDATE dbo.Orders
SET NetSales = UnitSales * DiscountedPrice
WHERE NetSales IS NULL 
  AND UnitSales IS NOT NULL 
  AND DiscountedPrice IS NOT NULL;

-- ===========================
-- STEP 2: FIX NULL UnitSales
-- ===========================

-- Only update if NetSales and DiscountedPrice are available
UPDATE dbo.Orders
SET UnitSales = NetSales / DiscountedPrice
WHERE UnitSales IS NULL 
  AND NetSales IS NOT NULL 
  AND DiscountedPrice IS NOT NULL;

-- ===========================
-- STEP 3: FIX NULL OriginalPrice
-- ===========================

-- Step 1: Create a CTE (Common Table Expression) to map ProductCode to known OriginalPrice
WITH ProductPriceReference AS (
    SELECT ProductCode, MAX(OriginalPrice) AS ReferencePrice
    FROM dbo.Orders
    WHERE OriginalPrice IS NOT NULL
    GROUP BY ProductCode
)

-- Step 2: Update rows where OriginalPrice is NULL
UPDATE T
SET T.OriginalPrice = P.ReferencePrice
FROM dbo.Orders T
JOIN ProductPriceReference P
    ON T.ProductCode = P.ProductCode
WHERE T.OriginalPrice IS NULL;

-- ===========================
-- STEP 3: FIX NULL GrossProfit
-- ===========================

-- Step 1: Build reference table only from reliable rows
WITH GrossProfitReference AS (
    SELECT 
        ProductCode,
        COALESCE(DiscountedPrice, OriginalPrice) AS SalePrice,
        MAX(GrossProfit) AS UnitGrossProfit
    FROM dbo.Orders
    WHERE GrossProfit IS NOT NULL
      AND UnitSales = 1
      AND OriginalPrice IS NOT NULL
      AND DiscountedPrice IS NOT NULL  -- 
    GROUP BY ProductCode, COALESCE(DiscountedPrice, OriginalPrice)
)

-- Step 2: Use the reference to update NULL GrossProfit
UPDATE T
SET T.GrossProfit = R.UnitGrossProfit * T.UnitSales
FROM dbo.Orders T
JOIN GrossProfitReference R
  ON T.ProductCode = R.ProductCode
 AND COALESCE(T.DiscountedPrice, T.OriginalPrice) = R.SalePrice
WHERE T.GrossProfit IS NULL
  AND T.UnitSales IS NOT NULL;


-- 2. Detect invalid negative or zero values
SELECT *
FROM dbo.Orders
WHERE UnitSales <= 0
   OR OriginalPrice < 0
   OR DiscountedPrice < 0
   OR NetSales < 0
   OR GrossProfit < 0;


--Fixing a row having zero values for UnitSales, NetSales, and GrossPrifit
DELETE FROM dbo.Orders
WHERE UnitSales = 0
  AND NetSales = 0
  AND GrossProfit = 0;


-- 3. Check for cases where DiscountedPrice > OriginalPrice
SELECT *
FROM Orders
WHERE DiscountedPrice > OriginalPrice;

-- 4. Check for duplicate rows
SELECT 
    CustomerID,
    OrderNumber,
    OrderDate,
    ProductCode,
    UnitSales,
    OriginalPrice,
    DiscountedPrice,
    NetSales,
    GrossProfit,
    COUNT(*) AS DuplicateCount
FROM Orders
GROUP BY 
    CustomerID,
    OrderNumber,
    OrderDate,
    ProductCode,
    UnitSales,
    OriginalPrice,
    DiscountedPrice,
    NetSales,
    GrossProfit
HAVING COUNT(*) > 1;

-- Joining the three tables
SELECT
	o.CustomerID,
	o.OrderNumber,
	o.OrderDate,
	o.UnitSales,
	o.OriginalPrice,
	o.DiscountedPrice,
	o.NetSales,
	o.GrossProfit,
	c.Market,
	p.ProductCode,
	p.ProductName,
	p.ProductBrand,
	p.Category
FROM dbo.Orders AS o
LEFT JOIN dbo.Customers AS c ON o.CustomerID = c.CustomerID
LEFT JOIN dbo.Products AS p ON o.ProductCode = p.ProductCode;

-- b. Analysis of Sales from Products on Discount

WITH DiscountStatus AS (
    SELECT
        o.CustomerID,
        c.Market AS Region,
        CASE WHEN o.OriginalPrice > o.DiscountedPrice THEN 1 ELSE 0 END AS IsDiscounted
    FROM dbo.Orders o
    LEFT JOIN dbo.Customers c ON o.CustomerID = c.CustomerID
),

DiscountOnlyCustomers AS (
    SELECT 
        CustomerID, 
        Region
    FROM DiscountStatus
    GROUP BY CustomerID, Region
    HAVING SUM(CASE WHEN IsDiscounted = 0 THEN 1 ELSE 0 END) = 0
        AND SUM(CASE WHEN IsDiscounted = 1 THEN 1 ELSE 0 END) > 0
),

TotalCustomers AS (
    SELECT 
        c.Market AS Region, 
        COUNT(DISTINCT o.CustomerID) AS TotalCustomers
    FROM dbo.Orders o
    LEFT JOIN dbo.Customers c ON o.CustomerID = c.CustomerID
    GROUP BY c.Market
),

DiscountCustomerCounts AS (
    SELECT 
        Region, 
        COUNT(DISTINCT CustomerID) AS DiscountOnlyCustomers
    FROM DiscountOnlyCustomers
    GROUP BY Region
),

TotalSales AS (
    SELECT 
        c.Market AS Region, 
        SUM(o.NetSales) AS TotalRegionSales
    FROM dbo.Orders o
    LEFT JOIN dbo.Customers c ON o.CustomerID = c.CustomerID
    GROUP BY c.Market
),

DiscountOnlySales AS (
    SELECT 
        c.Market AS Region, 
        SUM(o.NetSales) AS DiscountOnlySales
    FROM dbo.Orders o
    LEFT JOIN dbo.Customers c ON o.CustomerID = c.CustomerID
    WHERE o.CustomerID IN (SELECT CustomerID FROM DiscountOnlyCustomers)
    GROUP BY c.Market
)

SELECT 
    t.Region,
    t.TotalCustomers,
    ISNULL(d.DiscountOnlyCustomers, 0) AS DiscountOnlyCustomers,
    CAST(ROUND(100.0 * ISNULL(d.DiscountOnlyCustomers, 0) / t.TotalCustomers, 2) AS DECIMAL(5,2)) AS DiscountOnlyCustomerPercentage,
    CAST(ROUND(ts.TotalRegionSales, 2) AS DECIMAL(12,2)) AS TotalRegionSales,
    CAST(ROUND(ISNULL(ds.DiscountOnlySales, 0), 2) AS DECIMAL(12,2)) AS DiscountOnlySales,
    CAST(
        CASE 
            WHEN ts.TotalRegionSales = 0 THEN 0
            ELSE ROUND(100.0 * ISNULL(ds.DiscountOnlySales, 0) / ts.TotalRegionSales, 2)
        END AS DECIMAL(5,2)
    ) AS DiscountOnlySalesPercentage,
    CAST(
        ROUND(
            (100.0 * ISNULL(d.DiscountOnlyCustomers, 0) / t.TotalCustomers + 
            CASE WHEN ts.TotalRegionSales = 0 THEN 0 
                 ELSE 100.0 * ISNULL(ds.DiscountOnlySales, 0) / ts.TotalRegionSales END
            ) / 2, 
        2
        ) AS DECIMAL(5,2)
    ) AS DiscountResponsivenessScore
FROM TotalCustomers t
LEFT JOIN DiscountCustomerCounts d ON t.Region = d.Region
LEFT JOIN TotalSales ts ON t.Region = ts.Region
LEFT JOIN DiscountOnlySales ds ON t.Region = ds.Region
ORDER BY DiscountResponsivenessScore DESC;

-- c. Best-Performing Discounted Products Analysis
WITH DiscountedProducts AS (
    SELECT
        p.ProductCode,
        p.ProductName,
        p.ProductBrand,
        p.Category,
        o.OriginalPrice,
        o.DiscountedPrice,
        o.NetSales,
        o.GrossProfit,
        (o.OriginalPrice - o.DiscountedPrice) AS DiscountAmount,
        (o.GrossProfit / o.NetSales) AS GrossProfitMargin,
        CASE 
            WHEN (o.OriginalPrice - o.DiscountedPrice) > 0 
            THEN (o.GrossProfit / (o.OriginalPrice - o.DiscountedPrice)) 
            ELSE NULL 
        END AS DiscountImpactRatio
    FROM dbo.Orders AS o
    LEFT JOIN dbo.Products AS p ON o.ProductCode = p.ProductCode
    WHERE o.OriginalPrice > o.DiscountedPrice  -- Only include discounted products
),

ProductPerformance AS (
    SELECT
        ProductCode,
        ProductName,
        ProductBrand,
        Category,
        COUNT(*) AS TotalUnitsSold,
        AVG(OriginalPrice) AS AvgOriginalPrice,
        AVG(DiscountedPrice) AS AvgDiscountedPrice,
        AVG(DiscountAmount) AS AvgDiscountAmount,
        (AVG(DiscountAmount) / AVG(OriginalPrice)) * 100 AS AvgDiscountPercentage,
        SUM(NetSales) AS TotalNetSales,
        SUM(GrossProfit) AS TotalGrossProfit,
        AVG(GrossProfitMargin) AS AvgGrossProfitMargin,
        AVG(DiscountImpactRatio) AS AvgDiscountImpactRatio
    FROM DiscountedProducts
    GROUP BY ProductCode, ProductName, ProductBrand, Category
)

-- Final ranked results
SELECT
    ROW_NUMBER() OVER (ORDER BY AvgGrossProfitMargin DESC, AvgDiscountImpactRatio DESC, TotalGrossProfit DESC) AS PerformanceRank,
  --  ProductCode,
    ProductName,
    ProductBrand,
    Category,
    TotalUnitsSold,
    CAST(AvgOriginalPrice AS DECIMAL(10,2)) AS AvgOriginalPrice,
    CAST(AvgDiscountedPrice AS DECIMAL(10,2)) AS AvgDiscountedPrice,
    CAST(AvgDiscountAmount AS DECIMAL(10,2)) AS AvgDiscountAmount,
    CAST(AvgDiscountPercentage AS DECIMAL(5,2)) AS AvgDiscountPercentage,
    CAST(TotalNetSales AS DECIMAL(10,2)) AS TotalNetSales,
    CAST(TotalGrossProfit AS DECIMAL(10,2)) AS TotalGrossProfit,
    CAST(AvgGrossProfitMargin AS DECIMAL(5,4)) AS AvgGrossProfitMargin,
    CAST(AvgDiscountImpactRatio AS DECIMAL(5,2)) AS AvgDiscountImpactRatio
FROM ProductPerformance
ORDER BY PerformanceRank;

