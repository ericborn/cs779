EXEC sp_rename 'olist_customers_dataset', 'customers'
EXEC sp_rename 'olist_geolocation_dataset', 'geolocation'
EXEC sp_rename 'olist_order_items_dataset', 'order_items'
EXEC sp_rename 'olist_order_payments_dataset', 'order_payments'
EXEC sp_rename 'olist_order_reviews_dataset', 'order_reviews'
EXEC sp_rename 'olist_orders_dataset', 'orders'
EXEC sp_rename 'olist_products_dataset', 'products'
EXEC sp_rename 'olist_sellers_dataset', 'sellers'
EXEC sp_rename 'product_category_name_translation', 'category'


SELECT * --p. 
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN category c ON c.product_category_name = p.product_category_name


SELECT * 
FROM customers