-- Portfolio
SHOW TABLES;
DROP TABLE superstore;

SELECT * FROM superstore;

-- Cek jumlah row nya
SELECT COUNT("Row ID") FROM superstore;

-- Data Preparation (Cek NULL dan Ubah tipe data)
SELECT * FROM superstore
WHERE "Row ID" IS NULL;

ALTER TABLE superstore
ADD COLUMN order_date_new DATE,
ADD COLUMN ship_date_new DATE;

UPDATE superstore
SET order_date_new = STR_TO_DATE(`Order Date`, '%m/%d/%Y'),
    ship_date_new = STR_TO_DATE(`Ship Date`, '%m/%d/%Y');

SELECT * FROM superstore;

-- 1. Penjualan dan profit per region
SELECT 
  Region,
  ROUND(SUM(Sales), 2) AS Total_Penjualan,
  ROUND(SUM(Profit), 2) AS Total_Profit,
  SUM(Quantity) AS Total_Quantity,
  ROUND(SUM(Discount), 2) AS Total_Diskon
FROM superstore
GROUP BY Region
ORDER BY Total_Penjualan DESC;

-- Melihat profit di setiap bulannya dari sepanjang tahun 2014 sampai 2018
SELECT 
  DATE_FORMAT(order_date_new, '%Y-%m') AS Bulan,
  ROUND(SUM(Profit),2) AS Total_Profit
FROM superstore
GROUP BY Bulan
ORDER BY Bulan;

-- Setelahnya dicari profit yang negatifnya 
SELECT 
	DATE_FORMAT(order_date_new, '%Y-%m') AS Bulan,
	ROUND(SUM(Profit)) AS Total_Profit
FROM superstore
GROUP BY Bulan
HAVING Total_Profit < 0
ORDER BY Bulan;


-- Gabungan kategori, sub kategori, bulan, profit, diskon, dan jumlah order
SELECT 
  DATE_FORMAT(order_date_new, '%Y-%m') AS Bulan,
  Category, 
  `Sub-Category`,
  ROUND(SUM(Profit),2) AS Total_Profit,
  ROUND(SUM(Discount),2) AS Total_Diskon
FROM superstore
WHERE DATE_FORMAT(order_date_new, '%Y-%m') IN (
  SELECT 
    DATE_FORMAT(order_date_new, '%Y-%m')
  FROM superstore
  GROUP BY DATE_FORMAT(order_date_new, '%Y-%m')
  HAVING SUM(Profit) < 0
)
GROUP BY Bulan, Category, `Sub-Category`
ORDER BY Bulan, Total_Profit ASC;


SELECT 
	Category, `Sub-Category`,
	ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(SUM(Discount), 2) AS Total_Profit
FROM superstore
GROUP BY Category, `Sub-Category`
HAVING Total_Profit < 0;

SELECT * FROM superstore;

-- Rata-Rata Waktu Pengiriman per Bulan
WITH shipping_status AS (
	SELECT Category,
    DATE_FORMAT(order_date_new, '%Y-%m') AS order_month,
    CASE
		WHEN DATEDIFF(ship_date_new, order_date_new) <= 4 THEN 'Tepat Waktu'
		ELSE 'Terlambat'
    END AS status
    FROM superstore
)
SELECT order_month, category, status, COUNT(*) AS jumlah_order
FROM shipping_status
GROUP BY order_month, status
ORDER BY order_month;

SELECT * FROM superstore;

-- Ship Mode dengan Pengiriman yang Terlambat
WITH shipstatus AS (
	SELECT `Ship Mode`, Category,
    CASE 
		WHEN DATEDIFF(ship_date_new, order_date_new) <= 4 THEN 'Tepat Waktu'
        ELSE 'Terlambat'
	END AS status
    FROM superstore
)
SELECT `Ship Mode`, Category, status, COUNT(*) AS Total_Order
FROM shipstatus
WHERE status = 'Terlambat'
GROUP BY `Ship Mode`, Category
ORDER BY Total_Order DESC;

-- Pelanggan yang melakukan pembelian terbanyak
SELECT `Customer ID`, `Customer Name`, 
	COUNT(DISTINCT `Order ID`) AS Total_Orders,
    AVG(Discount) AS AVG_Discount,
    AVG(Sales) AS AVG_Sales,
    ROUND(SUM(Sales),2) AS Total_Sales,
    ROUND(SUM(Profit),2) AS Total_Profit
FROM superstore
GROUP BY  `Customer ID`, `Customer Name`
ORDER BY Total_Sales DESC;

-- Kenapa SEAN MILLER ini salesnya paling tnggi tapi profitnya rendah, mari analisis
-- Diskonnya ngga begitu besar tapi coba kita liat faktor lain siapa tau dia selalu beli barang yang marginnya kecil
SELECT `Customer Name`, Category, `Sub-Category`, 
	COUNT(`Order ID`) AS Total_Order,
	ROUND(SUM(Sales),2) AS Total_Sales,
	ROUND(SUM(Profit),2) AS Total_Profit
FROM superstore
WHERE `Customer Name` = 'Sean Miller'
GROUP BY `Customer Name`, Category, `Sub-Category`
ORDER BY Total_Sales;

-- Produk apa yang paling mendominasi penjualan
-- Cari Rank Profit paling tinggi per sub kategori
WITH Subcat_Profit AS (
	SELECT `Sub-Category`,
		ROUND(SUM(Profit),2) AS SubTotal_Profit,
        RANK() OVER(ORDER BY SUM(Profit) DESC) AS Rank_Profit
	FROM superstore
    GROUP BY `Sub-Category`
),
ProductProfit AS (
	SELECT `Sub-Category`, `Product Name`, 
		ROUND(SUM(Profit),2) AS Product_Profit
	FROM superstore
    WHERE `Sub-Category` = (SELECT `Sub-Category` FROM Subcat_Profit WHERE Rank_Profit = 1)
    GROUP BY `Sub-Category`, `Product Name`
)
SELECT 
	pp.`Sub-Category`,
    scp.SubTotal_Profit,
    pp.`Product Name`,
    pp.Product_Profit
FROM ProductProfit pp
JOIN Subcat_Profit scp
	ON pp.`Sub-Category`=scp.`Sub-Category`
WHERE scp.Rank_Profit = 1
ORDER BY pp.Product_Profit DESC;