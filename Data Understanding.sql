------------------------------------------------ 
------------------------------------------------ 
-- Data Unerstanding (Mainly on Orders Table)
------------------------------------------------ 
------------------------------------------------ 


---------------------------------------- 
-- Orders Table
---------------------------------------- 

SELECT *
FROM orders;
-- 99,441 rows 

SELECT COUNT(DISTINCT order_id)
FROM orders;
-- 99,441 -> So, PK is order_id 



-- Approval at -> is it seller's approval?
SELECT *
FROM orders
WHERE order_approved_at IS NOT NULL
	AND order_status = 'unavailable'
-- There are 609 rows. 
-- So, It's more like when the payment is done


---- Data's Period

SELECT 
	YEAR(order_purchase_timestamp) AS year,
	COUNT(*) AS the_num_of_orders
FROM orders
GROUP BY YEAR(order_purchase_timestamp);
-- 2016: 329
-- 2017: 45,101
-- 2018: 54,011




---- CHECK the quantities BY ORDER status 

SELECT order_status, COUNT(*) AS cnt
FROM orders
GROUP BY order_status
ORDER BY cnt DESC;
-- 1. delivered: 96,478
-- 2. shipped : 1,107
-- 3. canceled: 625
-- 4. unavailable: 609
-- 5. invoiced: 314
-- 6. processing: 301
-- 7. created: 5
-- 8. approved: 2


---------------------------------------- 
-- Order_items Table
---------------------------------------- 

SELECT *
FROM order_items
-- 112,650 rows
-- PK is {order_id, order_item_id}


SELECT COUNT(DISTINCT order_id) AS unique_orders
FROM order_items;
-- 98,666 unique orders

SELECT COUNT(order_id) AS unique_orders
FROM cleaned_orders;
-- 95,082 unique orders



SELECT COUNT(DISTINCT order_id)
FROM order_items
-- 98,666 unique order_ids


-- Rows that are in order_items but not in cleaned_orders for DOUBLE CHECK!

SELECT *
FROM cleaned_orders co
LEFT JOIN order_items oi ON oi.order_id = co.order_id
WHERE oi.order_id IS NULL
-- 775 rows

SELECT *
FROM cleaned_orders
WHERE has_order_items = 0



-- Does an order match only one seller or one product? 

SELECT order_id,
       COUNT(DISTINCT seller_id) AS seller_count
FROM order_items
GROUP BY order_id
HAVING COUNT(DISTINCT seller_id) > 1;

SELECT order_id,
       COUNT(DISTINCT product_id) AS product_count
FROM order_items
GROUP BY order_id
HAVING COUNT(DISTINCT product_id) > 1;
-- No, an order can contain several sellers and also products 


ALTER TABLE cleaned_order_items
MODIFY COLUMN shipping_limit_date DATETIME;




---------------------------------------- 
-- Customers Table
---------------------------------------- 

-- Check missing values
SELECT *
FROM customers c
WHERE c.customer_city IS NULL
	OR c.customer_id IS NULL
	OR c.customer_state IS NULL
	OR c.customer_unique_id IS NULL
	OR c.customer_zip_code_prefix IS NULL
-- There is no missing value in the table. 


SELECT COUNT(DISTINCT customer_id) AS total_number_of_customer_id
FROM customers;
-- 99,441 = The number of total rows -> customer_id is PK -> It's customer ID based on order_id 

SELECT COUNT(DISTINCT customer_unique_id) AS total_number_of_distinct_customer_unique_id
FROM customers;
-- 96,096

SELECT COUNT(DISTINCT order_id)
FROM cleaned_orders
-- 99,395

SELECT COUNT(order_id)
FROM orders
-- 99,441 


SELECT DISTINCT customers.customer_city
FROM customers;
-- 4,119 citys exist

SELECT DISTINCT customers.customer_state 
FROM customers;
-- 27 states exist


SELECT DISTINCT customer_city
FROM customers 


-- When it's joined with clean_orders 

SELECT *
FROM cleaned_orders co 
LEFT JOIN customers c
	ON c.customer_id = co.customer_id
WHERE c.customer_id IS NULL
-- 0 row

SELECT *
FROM customers c 
LEFT JOIN cleaned_orders co
	ON c.customer_id = co.customer_id
WHERE co.customer_id IS NULL
-- 46 rows




-------------------------------------------
-- ORDER_REVIEWS TABLE
-------------------------------------------


SELECT *
FROM order_reviews;
-- 99,224 rows

SELECT COUNT(DISTINCT review_id)
FROM order_reviews;
-- 98,410 reviews

SELECT COUNT(DISTINCT order_id)
FROM order_reviews;
-- 98,673 order_ids

SELECT COUNT(DISTINCT order_id)
FROM orders;
-- 99,441 order_ids

-- ARE PKs unique? 
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(review_id, '_', order_id)) AS unique_combinations
FROM order_reviews;



-- As I understand it, there should be one review per order.
-- That means the review is not for a specific product in the order, but for the order itself.
-- So each order should have a unique review_id — meaning review_id should be the primary key. But it's not.
-- So why are there duplicate values in both order_id and review_id?



-- Check the number of reviews based on order_id 

WITH review_count_table AS (
	SELECT order_id, COUNT(*) AS review_count
	FROM order_reviews
	GROUP BY order_id
	ORDER BY review_count DESC
)

SELECT
	review_count,
	COUNT(*) AS order_count
FROM review_count_table 
GROUP BY review_count
ORDER BY review_count ASC




-- Vise versa. Check the number of order id based on review_id 

SELECT review_id, COUNT(*) AS order_count
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY order_count DESC;




-- Then what are the order_status of orders in order_reviews?

SELECT co.order_status, COUNT(*) AS order_status_count
FROM order_reviews ors
JOIN cleaned_orders co
	ON ors.order_id = co.order_id
GROUP BY co.order_status
ORDER BY order_status_count DESC;
-- delivered, canceled, and so on
-- It is possible to leave a review even before an order status becomes 'delivered'


SELECT review_id, COUNT(DISTINCT order_id)
FROM order_reviews
GROUP BY review_id
HAVING COUNT(DISTINCT order_id) > 1;


-- A case that a review_id matches with several order_ids

SELECT r.review_id, r.order_id, r.review_comment_title, r.review_comment_message, r.review_score
FROM order_reviews r
JOIN (
    SELECT review_id
    FROM order_reviews
    GROUP BY review_id
    HAVING COUNT(DISTINCT order_id) > 1
) dup
ON r.review_id = dup.review_id
ORDER BY r.review_id, r.order_id;
-- 1,603 rows. All values are same except for order_id value 
-- Dig in more 



-- Check those duplicates 
SELECT review_id, COUNT(DISTINCT order_id), COUNT(DISTINCT review_score), COUNT(DISTINCT review_comment_title), COUNT(DISTINCT review_comment_message)
FROM order_reviews
GROUP BY review_id
HAVING COUNT(DISTINCT order_id) > 1
ORDER BY COUNT(DISTINCT order_id) DESC;


-- Last check

WITH count_num_by_duplicated_reviews AS (
	SELECT 
		review_id,
		COUNT(DISTINCT order_id) AS count_order_id,
		COUNT(DISTINCT review_score) AS count_review_score,
		COUNT(DISTINCT review_comment_title) AS count_review_title,
		COUNT(DISTINCT review_comment_message) AS count_review_message
	FROM order_reviews
	GROUP BY review_id
	HAVING COUNT(DISTINCT order_id) > 1
)

SELECT *
FROM count_num_by_duplicated_reviews
WHERE count_review_score >= 2
   OR count_review_title >= 2
   OR count_review_message >= 2;



-- Create a view for records that redundant review_id

CREATE VIEW order_reviews_duplicates_review_id AS 
SELECT r.review_id, r.order_id, r.review_comment_title, r.review_comment_message, r.review_score
FROM order_reviews r
JOIN (
    SELECT review_id
    FROM order_reviews
    GROUP BY review_id
    HAVING COUNT(DISTINCT order_id) > 1
) dup
ON r.review_id = dup.review_id
ORDER BY r.review_id, r.order_id;
 

-- cleaned_order_reviews

CREATE TABLE cleaned_order_reviews AS
SELECT review_id, order_id, review_comment_title, review_comment_message, review_score
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY order_id) AS rn
    FROM order_reviews
) t
WHERE rn = 1;

ALTER TABLE cleaned_order_reviews
ADD PRIMARY KEY (review_id(50));


SHOW KEYS FROM cleaned_order_reviews WHERE Key_name = 'PRIMARY';


---------------------------------------- 
-- Geolocation Table
---------------------------------------- 

-- Duplicates

SELECT COUNT(*) AS total_duplicates
FROM (
    SELECT 
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state,
        COUNT(*) AS cnt
    FROM geolocation
    GROUP BY 
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    HAVING COUNT(*) > 1
) AS duplicates;



SELECT 
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    COUNT(*) AS cnt
FROM geolocation
GROUP BY 
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) > 1;

-- Copy Version without duplicates

CREATE TABLE geolocation_copy AS
SELECT DISTINCT 
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
FROM geolocation;



-- Check NULL in all columns

SELECT 
  COUNT(*) AS total_rows,
  COUNT(*) - COUNT(geolocation_zip_code_prefix) AS null_zip_code_prefix,
  COUNT(*) - COUNT(geolocation_lat) AS null_lat,
  COUNT(*) - COUNT(geolocation_lng) AS null_lng,
  COUNT(*) - COUNT(geolocation_city) AS null_city,
  COUNT(*) - COUNT(geolocation_state) AS null_state
FROM geolocation_copy;
-- NO Null Values


-- Check PK
SELECT COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zips,
       COUNT(*) AS total_rows
FROM geolocation_copy;

-- Not a single PK
SELECT COUNT(DISTINCT CONCAT(
    geolocation_zip_code_prefix, '-', 
    geolocation_lat, '-', 
    geolocation_lng, '-', 
    geolocation_city, '-', 
    geolocation_state)) AS unique_combinations,
       COUNT(*) AS total_rows
FROM geolocation_copy;



-- Data Type Check

DESCRIBE geolocation_copy;


-- Out of Brazil based on lang, long

SELECT * 
FROM geolocation_copy
WHERE geolocation_lat NOT BETWEEN -34.0 AND 5.3
   OR geolocation_lng NOT BETWEEN -73.9 AND -34.8;

-- Delete outliers (Out of Brazil)

DELETE FROM geolocation_copy
WHERE geolocation_lat NOT BETWEEN -34.0 AND 5.3
   OR geolocation_lng NOT BETWEEN -73.9 AND -34.8;


