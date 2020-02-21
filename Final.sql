/*
Eric Born
CS 779
Fall 2020
Final project - Oline data warehouse
*/

-- Unneeded, these errors were introduced from importing with the import data feature instead of import flat file
---- Rename tables
--EXEC sp_rename 'olist_customers_dataset', 'customers'
--EXEC sp_rename 'olist_geolocation_dataset', 'geolocation'
--EXEC sp_rename 'olist_order_items_dataset', 'order_items'
--EXEC sp_rename 'olist_order_payments_dataset', 'order_payments'
--EXEC sp_rename 'olist_order_reviews_dataset', 'order_reviews'
--EXEC sp_rename 'olist_orders_dataset', 'orders'
--EXEC sp_rename 'olist_products_dataset', 'products'
--EXEC sp_rename 'olist_sellers_dataset', 'sellers'
--EXEC sp_rename 'product_category_name_translation', 'category'

---- Remove quotes from column names
--EXEC sp_rename 'customers.["customer_id"]', 'customer_id'
--EXEC sp_rename 'customers.["customer_unique_id"]', 'customer_unique_id'
--EXEC sp_rename 'customers.["customer_zip_code_prefix"]', 'customer_zip_code_prefix'
--EXEC sp_rename 'customers.["customer_city"]', 'customer_city'
--EXEC sp_rename 'customers.["customer_state"]', 'customer_state'

---- Code section to clean any issues found in the data
---- Find if all zips are the same length
--SELECT DISTINCT LEN(customer_zip_code_prefix)
--FROM customers

---- Selects 5 numbers between the two quotes
--SELECT RIGHT(LEFT(customer_zip_code_prefix, 6),5)
--FROM customers

---- Removes quotes from start and end of zipcode 
---- in the customers table customer_zip_code_prefix column
--UPDATE customers
--SET customer_zip_code_prefix = (SELECT RIGHT(LEFT(customer_zip_code_prefix, 6),5)
--								FROM customers c
--								WHERE customers.customer_id = c.customer_id)

-- script to output database schema
-- Provided by lucidchart.com with their import data feature
SELECT 'sqlserver' dbms,t.TABLE_CATALOG,t.TABLE_SCHEMA,t.TABLE_NAME,c.COLUMN_NAME,c.ORDINAL_POSITION,c.DATA_TYPE,
c.CHARACTER_MAXIMUM_LENGTH,n.CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLES t 
LEFT JOIN INFORMATION_SCHEMA.COLUMNS c ON t.TABLE_CATALOG=c.TABLE_CATALOG AND t.TABLE_SCHEMA=c.TABLE_SCHEMA AND t.TABLE_NAME=c.TABLE_NAME 
LEFT JOIN(INFORMATION_SCHEMA.KEY_COLUMN_USAGE k 
JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS n ON k.CONSTRAINT_CATALOG=n.CONSTRAINT_CATALOG 
AND k.CONSTRAINT_SCHEMA=n.CONSTRAINT_SCHEMA AND k.CONSTRAINT_NAME=n.CONSTRAINT_NAME 
LEFT JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS r ON k.CONSTRAINT_CATALOG=r.CONSTRAINT_CATALOG AND k.CONSTRAINT_SCHEMA=r.CONSTRAINT_SCHEMA 
AND k.CONSTRAINT_NAME=r.CONSTRAINT_NAME)ON c.TABLE_CATALOG=k.TABLE_CATALOG AND c.TABLE_SCHEMA=k.TABLE_SCHEMA AND c.TABLE_NAME=k.TABLE_NAME AND c.COLUMN_NAME=k.COLUMN_NAME 
WHERE t.TABLE_TYPE='BASE TABLE';

----------------------------

USE Olist_DW

--DROP TABLE orders

-- Gathers the data from the Olist database and insert it into a table called orders in the Olist_DW database
-- does a convert on the time.datekey from INT to DATE
-- also converts orders order_purchase_timestamp from DATETIME to DATE
SELECT t.DateKey, c.product_category_name_english AS 'product_category', oi.seller_id, s.seller_city, 
s.seller_state, SUM(oi.price) AS 'Total_Value', COUNT(oi.product_id) AS 'Units_Sold'
INTO orders
FROM Olist.dbo.orders o
JOIN Olist.dbo.order_items oi ON oi.order_id = o.order_id
JOIN Olist.dbo.products p ON p.product_id = oi.product_id
JOIN Olist.dbo.category c ON c.product_category_name = p.product_category_name
JOIN Olist.dbo.sellers s ON s.seller_id = oi.seller_id
JOIN time_period t ON CONVERT(DATE,CONVERT(VARCHAR(8),t.DateKey,112)) = CONVERT(DATE,o.order_purchase_timestamp,112)
GROUP BY t.DateKey, o.order_purchase_timestamp, c.product_category_name_english, oi.seller_id, s.seller_city, s.seller_state
 


-- Find misspelled Sãu Paulo in seller_city column
SELECT distinct seller_city
FROM sellers s
WHERE seller_city LIKE 'sao pau%' OR seller_city LIKE 'sao palu%'

-- Replace misspellings
UPDATE sellers
SET seller_city = 'Sãu Paulo'
WHERE seller_city LIKE 'sao pau%' OR seller_city LIKE 'sao palu%'

SELECT top 100 * from time

SELECT top 100 *
FROM sellers s
JOIN geolocation gl ON gl.geolocation_zip_code_prefix = s.seller_zip_code_prefix

SELECT * FROM geolocation

SELECT * --p. 
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN category c ON c.product_category_name = p.product_category_name

SELECT TOP 100 *
FROM order_items --orders

SELECT TOP 100 *--count(*)
FROM products p
JOIN category c ON c.product_category_name = p.product_category_name

