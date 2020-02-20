-- Rename tables
EXEC sp_rename 'olist_customers_dataset', 'customers'
EXEC sp_rename 'olist_geolocation_dataset', 'geolocation'
EXEC sp_rename 'olist_order_items_dataset', 'order_items'
EXEC sp_rename 'olist_order_payments_dataset', 'order_payments'
EXEC sp_rename 'olist_order_reviews_dataset', 'order_reviews'
EXEC sp_rename 'olist_orders_dataset', 'orders'
EXEC sp_rename 'olist_products_dataset', 'products'
EXEC sp_rename 'olist_sellers_dataset', 'sellers'
EXEC sp_rename 'product_category_name_translation', 'category'

-- Remove quotes from column names
EXEC sp_rename 'customers.["customer_id"]', 'customer_id'
EXEC sp_rename 'customers.["customer_unique_id"]', 'customer_unique_id'
EXEC sp_rename 'customers.["customer_zip_code_prefix"]', 'customer_zip_code_prefix'
EXEC sp_rename 'customers.["customer_city"]', 'customer_city'
EXEC sp_rename 'customers.["customer_state"]', 'customer_state'

-- Find if all zips are the same length
SELECT DISTINCT LEN(customer_zip_code_prefix)
FROM customers

-- Selects 5 numbers between the two quotes
SELECT RIGHT(LEFT(customer_zip_code_prefix, 6),5)
FROM customers

-- Removes quotes from start and end of zipcode 
-- in the customers table customer_zip_code_prefix column
UPDATE customers
SET customer_zip_code_prefix = (SELECT RIGHT(LEFT(customer_zip_code_prefix, 6),5)
								FROM customers c
								WHERE customers.customer_id = c.customer_id)
 
SELECT * FROM customers

-- find misspelled Sãu Paulo in seller_city column
SELECT distinct seller_city
FROM sellers s
WHERE seller_city LIKE 'sao pau%' OR seller_city LIKE 'sao palu%'

SELECT top 100 *
FROM sellers s
JOIN geolocation gl ON gl.geolocation_zip_code_prefix = s.seller_zip_code_prefix

SELECT * FROM geolocation

SELECT * --p. 
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN category c ON c.product_category_name = p.product_category_name

SELECT count(*) --TOP 100 *
FROM order_items --orders

SELECT TOP 100 *--count(*)
FROM products p
JOIN category c ON c.product_category_name = p.product_category_name

