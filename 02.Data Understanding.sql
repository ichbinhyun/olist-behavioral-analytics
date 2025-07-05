------------------------------------------------ 
------------------------------------------------ 
-- Data Unerstanding
------------------------------------------------ 
------------------------------------------------ 

---------------------------------------- 
-- Orders Table
---------------------------------------- 

-- 1. Data type
DESCRIBE orders;
-- Every column's data type is text. 
-- Columns that are timestamp will be changed to datetime later

-- 2. Total # of rows
SELECT COUNT(*) AS num_rows
FROM orders;
-- 99,441 rows 

-- 3. Finding PK
SELECT COUNT(DISTINCT order_id) AS num_orders
FROM orders;
-- 99,441 -> So, PK is order_id 

-- 4. Data's Period
-- 4-1. Date range + yearly trend of order volume

SELECT 
	YEAR(order_purchase_timestamp) AS year,
	COUNT(*) AS the_num_of_orders
FROM orders
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY YEAR ASC;
-- 2016: 329
-- 2017: 45,101
-- 2018: 54,011


-- 4-2. Min/Max timestamps across order lifecycle columns
SELECT
	MIN(order_purchase_timestamp) AS min_purchase,
	MAX(order_purchase_timestamp) AS max_purchase,
	MIN(order_approved_at) AS min_approved,
	MAX(order_approved_at) AS max_approved,
	MIN(order_delivered_carrier_date) AS min_carrier,
	MAX(order_delivered_carrier_date) AS max_carrier,
	MIN(order_delivered_customer_date) AS min_customer,
	MAX(order_delivered_customer_date) AS max_customer,
	MIN(order_estimated_delivery_date) AS min_estimated,
	MAX(order_estimated_delivery_date) AS max_estimated
FROM orders;



-- 5. Distinct values of crucial columns
-- 5-1. How many unique customer_ids are in the table? 
SELECT COUNT(DISTINCT customer_id)
FROM orders;
-- 99,441

-- 5-2. order status
SELECT order_status, COUNT(*) AS num_status
FROM orders
GROUP BY order_status
ORDER BY num_status DESC;
-- Result:
---- delivered: 96,478
---- shipped : 1,107
---- canceled: 625
---- unavailable: 609
---- invoiced: 314
---- processing: 301
---- created: 5
---- approved: 2


-- 6. Missing values
-- # of nulls by column
SELECT
  SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS nulls_order_id,
  SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS nulls_customer_id,
  SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS nulls_status,
  SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS nulls_purchase,
  SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS nulls_approved,
  SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS nulls_carrier,
  SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS nulls_customer,
  SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS nulls_estimated
FROM orders;
-- order_id, customer_id, order_status, order_purchase_timestamp, and order_estimated_delivery_date columns have no missing value
-- # of Null in order_approved_at: 160
-- # of Null in order_delivered_carrier_date: 1,783
-- # of Null in order_delivered_customer_date: 2,965

-- 7. Duplicated rows
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    COUNT(*) AS dup_count
FROM orders
GROUP BY 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
HAVING COUNT(*) > 1;
-- No duplicated rows

-- 8. About business logic
-- 8-1. Is order_approved_at the time when a payment is done or the one when seller approves an order?
SELECT *
FROM orders
WHERE order_approved_at IS NOT NULL
	AND order_status = 'unavailable' -- If an order is unavailable, then order_approved_at should be NULL
-- There are 609 'unavailable' orders that still have order_approved_at values.
-- This implies that 'order_approved_at' likely reflects payment completion, not seller confirmation.


-- 8-2. Missing values across order statuses
SELECT 
  order_status,
  COUNT(*) AS total_orders,
  SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS null_approved,
  SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS null_carrier,
  SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_customer_delivery,
  SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS null_estimated_delivery
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;
-- order_estimated_delivery's data is created when an order is created by being purchased. 
-- There are some anomalies in delivered orders that have missing values in columns in delivery process. 




---------------------------------------- 
-- Order_items Table
---------------------------------------- 

-- 1. Data type
DESCRIBE order_items;
-- order_id and product_id are text type
-- order_item_id is bigint type
-- price and freight_value are double type
-- shipping_limit_date is also text type, so it will be changed to datetime later. 

-- 2. Total # of rows
SELECT COUNT(*) AS num_rows -- Check # of rows
FROM order_items;
-- 112,650 rows


-- 3. Finding PK
SELECT COUNT(DISTINCT order_id) AS num_orders -- Check # of order_id
FROM order_items;
-- 98,666 unique order ids

SELECT COUNT(DISTINCT order_item_id) AS num_item -- Check # of distinct order_item_id
FROM order_items;
-- 21 unique order item numbers 

SELECT COUNT(DISTINCT order_id, order_item_id) AS num_combination -- Check # of distinct combinations of order_id & order_item_id
FROM order_items;
-- 112,650. 
-- PK is {order_id, order_item_id}


-- 4. Data's period
-- 4-1. Data range
SELECT
	YEAR(shipping_limit_date) AS year,
	COUNT(*) AS cnt
FROM order_items
GROUP BY YEAR(shipping_limit_date)
ORDER BY YEAR;
-- From 2016 to 2020

-- 4-2. Min/Max timestamp of shipping_limit_date
SELECT
	MIN(shipping_limit_date) AS min_shipping_limit,
	MAX(shipping_limit_date) AS max_shipping_limit
FROM order_items
-- Min: 2016-09-19
-- Max: 2020-04-09
-- shipping_limit_date represents the deadline by which the seller should ship the item.

-- 5. Distinct values of crucial columns
-- 5-1. How many order_ids are in the table? 
SELECT COUNT(DISTINCT order_id) AS num_order_id
FROM order_items
-- 98,666

-- 5-2. Unique order_item_id 
SELECT DISTINCT order_item_id
FROM order_items
-- order_item_id ranges from 1 to 21, meaning some orders contain up to 21 items.
-- It is a sequence within each order, not a global item identifier.

-- 5-3. How many product_ids are in the table? 
SELECT COUNT(DISTINCT product_id) AS num_product_id
FROM order_items
-- 32,951 unique product_ids

-- 5-4. How many seller_ids are in the table? 
SELECT COUNT(DISTINCT seller_id) AS num_seller_id
FROM order_items
-- 3,095 unique sellers

-- 6. Min/Max of price and freight_value
SELECT
	MIN(price) AS min_price,
	MAX(price) AS max_price,
	MIN(freight_value) AS min_freight_value,
	MAX(freight_value) AS max_freight_value
FROM order_items 
-- Price = min: 0.85, max: 6,735
-- Freight value = min: 0, max: 409.68

-- 7. Missing values 
SELECT
  SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS nulls_order_id,
  SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) AS nulls_item,
  SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS nulls_product,
  SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS nulls_seller,
  SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) AS nulls_shipping_limit,
  SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS nulls_price,
  SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS nulls_freight_value
FROM order_items;
-- There is no missing values in the table.

-- 8. Duplicated rows
SELECT 
  order_id, 
  order_item_id, 
  product_id, 
  seller_id, 
  shipping_limit_date, 
  price, 
  freight_value,
  COUNT(*) AS dup_count
FROM order_items
GROUP BY 
  order_id, 
  order_item_id, 
  product_id, 
  seller_id, 
  shipping_limit_date, 
  price, 
  freight_value
HAVING COUNT(*) > 1;
-- No duplicated rows


-- 9. About business logic
-- Does an order match only one seller or one product? 
-- a) Seller
SELECT order_id,
       COUNT(DISTINCT seller_id) AS seller_count
FROM order_items
GROUP BY order_id
HAVING COUNT(DISTINCT seller_id) > 1;
-- There are orders that have more than one seller

-- b) Product
SELECT order_id,
       COUNT(DISTINCT product_id) AS product_count
FROM order_items
GROUP BY order_id
HAVING COUNT(DISTINCT product_id) > 1;
-- There are orders that have more than one product
-- So, an order can contain several sellers and also products 


-------------------------------------------
-- Order_reviews Table
-------------------------------------------


-- 1. Data type
DESCRIBE order_reviews
-- review_id, order_id, review_comment_title, review_comment_message are text type. 
-- review_score is bigint type.
-- review_creation_date and review_answer_timestamp are datetime type. 

-- 2. Total # of rows
SELECT COUNT(*) AS total_rows
FROM order_reviews;
-- 99,224 rows

-- 3. Finding PK
SELECT COUNT(DISTINCT review_id)
FROM order_reviews;
-- 98,410 reviews

SELECT COUNT(DISTINCT order_id)
FROM order_reviews;
-- 98,673 order_ids
-- Both are not PK

SELECT COUNT(DISTINCT order_id)
FROM orders; -- check order_id from orders 
-- 99,441 order_ids

-- 3-1. Is the combination of review_id and order_id PK? 
SELECT
	COUNT(*) AS total_rows,
	COUNT(DISTINCT review_id, order_id) AS unique_combination
FROM order_reviews
-- 99,224
-- So, the combination of order_id and review_id looks like PK


-- 3-2. Are PK valid?
-- Review_id has 
WITH reviews_with_multiple_orders AS (
	SELECT review_id
	FROM order_reviews
	GROUP BY review_id
	HAVING COUNT(*) >= 2
)

SELECT COUNT(review_id) AS num_reviews
FROM reviews_with_multiple_orders; 
-- 789 review_ids have multiple orders
-- Usually, there should be one review per order.
-- That means the review is not for a specific product in the order, but for the order itself.
-- So each order should have a unique review_id which means review_id should be the primary key. But it's not.


-- 3-3. A case that a review_id matches with several order_ids

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



-- 3-3-1. Check the details of those reviews  
SELECT review_id, COUNT(DISTINCT order_id), COUNT(DISTINCT review_score), COUNT(DISTINCT review_comment_title), COUNT(DISTINCT review_comment_message)
FROM order_reviews
GROUP BY review_id
HAVING COUNT(DISTINCT order_id) > 1
ORDER BY COUNT(DISTINCT order_id) DESC;



-- 3-3-2.  Review Data Integrity Check

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
-- No inconsistencies found among the 789 duplicated review_id values. All review content is identical.
-- These duplicates will be deduplicated (keeping one per review_id), allowing review_id to be treated as a PK.



-- 4. Duplicated rows
SELECT
	order_id,
	review_id,
	review_score,
	review_comment_title,
	review_comment_message,
	review_creation_date,
	review_answer_timestamp,
	COUNT(*) AS dup_count
FROM order_reviews 
GROUP BY
	order_id,
	review_id,
	review_score,
	review_comment_title,
	review_comment_message,
	review_creation_date,
	review_answer_timestamp
HAVING COUNT(*) > 1;
-- No duplicated rows

-- 5. Distinct values of crucial columns
-- 5-1. Review score
SELECT DISTINCT review_score
FROM order_reviews
ORDER BY review_score;
-- The range of score is from 1 to 5


-- 6. Data Period
-- 6-1. Based on review_creation_date
SELECT
	MIN(review_creation_date) AS min_creation,
	MAX(review_creation_date) AS max_creation
FROM order_reviews;
-- From 2016-10-02 to 2018-08-31

-- 6-2. Based on review_answer_timestamp
SELECT
	MIN(review_answer_timestamp) AS min_answer,
	MAX(review_answer_timestamp) AS max_answer
FROM order_reviews;
-- From 2016-10-07 18:32:28 to 2018-10-29 12:27:35


-- 7. Missing values 
SELECT
	SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END) AS null_review_id,
	SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
	SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END) AS null_title,
	SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS null_message,
	SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS null_score,
	SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) AS null_creation,
	SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) AS null_answer
FROM order_reviews;
-- review_comment_title has 87,656 missing values and review_comment_message has 58,247 missing values. 
-- Other columns don't have null values. 



---------------------------------------- 
-- Order_payments Table
---------------------------------------- 

-- 1. Data type
DESCRIBE order_payments;
-- order_id and payment_type are text type.
-- payment_sequential and payment_installments are bigint type.
-- payment_value is double type. 


-- 2. Total # of rows
SELECT COUNT(*) AS total_rows
FROM order_payments
-- 103,886 rows

-- 3. Finding PK
SELECT COUNT(order_id) AS total_order_ids
FROM order_payments;
-- 103,886 order_ids -> PK is order_id

-- 4. Distinct values of crucial columns
-- 4-1. How is the payment_sequential range?
SELECT DISTINCT payment_sequential 
FROM order_payments
ORDER BY payment_sequential;
-- The range starts from 1 to 29

-- 4-2. Unique values and distribution of payment_type
SELECT
	payment_type,
	COUNT(*) AS num_type
FROM order_payments
GROUP BY payment_type;
-- The result:
---- Credit card: 76,795
---- Boleto: 19,784
---- Voucher: 5,775
---- Debit card: 1,529
---- Not DEFINED: 3 -> Needs to be drilled down later


-- 4-3. How is the payment_installments range?
SELECT DISTINCT payment_installments 
FROM order_payments
ORDER BY payment_installments;
-- The range starts from 0 to 24 excluding 19
-- 0 value for payment_installment seems suspicious. Will be dealt with later. 


-- 5. Min/Max of payment_value
SELECT
	MIN(payment_value) AS min_payment_value,
	MAX(payment_value) AS max_payment_value
FROM order_payments;
-- Min: 0, Max: 13,664.08 -> A payment_value of 0 is suspicious, but it could indicate a coupon or full discount usage.



-- 6. Missing values 
SELECT
	SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
	SUM(CASE WHEN payment_sequential IS NULL THEN 1 ELSE 0 END) AS null_sequential,
	SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) AS null_payment_type,
	SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END) AS null_installment,
	SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) AS null_value
FROM order_payments
-- No missing values

-- 7. Duplicated rows
SELECT 
  order_id,
  payment_sequential,
  payment_type,
  payment_installments,
  payment_value,
  COUNT(*) AS dup_count
FROM order_payments
GROUP BY 
  order_id,
  payment_sequential,
  payment_type,
  payment_installments,
  payment_value
HAVING COUNT(*) > 1;
-- No duplicated rows



---------------------------------------- 
-- Customers Table
---------------------------------------- 

-- 1. Data type
DESCRIBE customers;
-- Every column is text type except for customer_zip_code_prefix that is bigint type. 

-- 2. Total # of rows
SELECT COUNT(*) AS total_num_rows
FROM customers
-- 99,441 rows

-- 3. Finding PK
SELECT COUNT(DISTINCT customer_id) AS total_number_of_customer_id
FROM customers;
-- 99,441 = The number of total rows -> customer_id is PK
-- customer_id is customer ID based on order_id. customer_unique_id is unique id that identifies each customer

-- 4. Distinct values of crucial columns
-- 4-1. Total # of customer_unique_id
SELECT COUNT(DISTINCT customer_unique_id) AS total_number_of_distinct_customer_unique_id
FROM customers;
-- 96,096.
-- Some customers used the platform more than twice. 

-- 4-2. Total # of customer_zip_code_prefix
SELECT COUNT(DISTINCT customer_zip_code_prefix) AS num_zip
FROM customers;
-- 14,994

-- 4-3. Total # of cities 
SELECT COUNT(DISTINCT customer_city)
FROM customers;
-- 4,119 citys exist

-- 4-4. Total # of states
SELECT COUNT(DISTINCT customer_state) 
FROM customers;
-- 27 states exist


-- 5. Missing values
SELECT 
  COUNT(*) AS total_rows,
  SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
  SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS null_unique_id,
  SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip_code,
  SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS null_city,
  SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS null_state
FROM customers;
-- No missing values

-- 6. Duplicated rows
SELECT 
  customer_id,
  customer_unique_id,
  customer_zip_code_prefix,
  customer_city,
  customer_state,
  COUNT(*) AS dup_count
FROM customers
GROUP BY 
  customer_id,
  customer_unique_id,
  customer_zip_code_prefix,
  customer_city,
  customer_state
HAVING COUNT(*) > 1;
-- No duplicated rows


---------------------------------------- 
-- Sellers table
---------------------------------------- 

-- 1. Data type
DESCRIBE sellers;
-- Every column is text type except for seller_zip_code_prefix that is bigint type. 

-- 2. Total # of rows
SELECT COUNT(*) AS total_rows
FROM sellers
-- 3,095

-- 3. Finding PK
SELECT COUNT(DISTINCT seller_id) AS num_unique_sellers
FROM sellers 
-- 3,095.
-- seller_id is PK -> There are 3,095 unique sellers

-- 4. Distinct values of crucial columns
-- 4-1. Total # of unique seller_zip_code_prefix
SELECT COUNT(DISTINCT seller_zip_code_prefix) AS num_zip
FROM sellers;
-- 2,246 unique zip codes

-- 4-2. Total # of unique seller_city
SELECT COUNT(DISTINCT seller_city) AS num_city
FROM sellers;
-- 610 unique cities 

-- 4-3. Total # of unique seller_state
SELECT COUNT(DISTINCT seller_state) AS num_state
FROM sellers;
-- 23 unique states

-- 5. Missing values 
SELECT
	SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS null_seller_id,
	SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip,
	SUM(CASE WHEN seller_city IS NULL THEN 1 ELSE 0 END) AS null_city,
	SUM(CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) AS null_state
FROM sellers;
-- No missing values

-- 6. Duplicated rows
SELECT 
    *,
    COUNT(*) AS cnt
FROM sellers
GROUP BY 
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
HAVING cnt > 1;
-- No duplicated rows 



---------------------------------------- 
-- Products Table
---------------------------------------- 

-- 1. Data type
DESCRIBE products;
-- product_id and product_category_name are text type. The rest of the columns are double type.

-- 2. Total # of rows
SELECT COUNT(*)
FROM products;
-- 32,951

-- 3. Finding PK
SELECT COUNT(DISTINCT product_id) AS num_unique_product_id
FROM products;
-- 32,951 unique product_ids -> product_id is PK 


-- 4. Distinct values of product_category_name
SELECT COUNT(DISTINCT product_category_name)
FROM products
-- 73 unique categories

-- 5. Min/Max of crucial columns
SELECT
	MIN(product_length_cm) AS min_len,
	MAX(product_length_cm) AS max_len,
	MIN(product_height_cm) AS min_height,
	MAX(product_height_cm) AS max_height,
	MIN(product_width_cm) AS min_width,
	MAX(product_width_cm) AS max_width,
	MIN(product_weight_g) AS min_weight,
	MAX(product_weight_g) AS max_weight
FROM products;
-- Length = min:7, max:105
-- Height = min:2, max:105
-- Width = min:6, max:118
-- Weight = min:0, max:40425
-- 0 value of weight is unrealistic and will be checked later


-- 6. Missing values
SELECT
	SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
	SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_category,
	SUM(CASE WHEN product_name_length IS NULL THEN 1 ELSE 0 END) AS null_name_len,
	SUM(CASE WHEN product_description_length IS NULL THEN 1 ELSE 0 END) AS null_desc_len,
	SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) AS null_photo_qty,
	SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS null_weight,
	SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS null_len,
	SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) AS null_height,
	SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) AS null_width
FROM products;
-- Result:
---- product_id: 0
---- category_name: 610
---- name_length: 610
---- description_length: 610
---- photos_qty: 610
---- weight: 2
---- length: 2
---- height: 2
---- width: 2
-- There are 610 products without category_name, description, and photos
-- There are 2 products missing measurement data

-- 8. Duplicated rows
SELECT
	product_id,
	product_category_name,
	product_name_length,
	product_description_length,
	product_photos_qty,
	product_weight_g,
	product_length_cm,
	product_height_cm,
	product_width_cm,
	COUNT(*) AS cnt
FROM products
GROUP BY 
	product_id,
	product_category_name,
	product_name_length,
	product_description_length,
	product_photos_qty,
	product_weight_g,
	product_length_cm,
	product_height_cm,
	product_width_cm
HAVING cnt > 1
-- No duplicated rows


---------------------------------------- 
-- Product_category_eng Table
---------------------------------------- 

-- 1. Data type
DESCRIBE product_category_eng;
-- Both columns are text type. 

-- 2. Total # of rows
SELECT COUNT(*) AS total_rows
FROM product_category_eng;
-- 72 rows

-- 3. Finding PK
SELECT COUNT(DISTINCT product_category_name)
FROM product_category_eng
-- 72 unique category names -> PK
-- However, the # of unique category names in the table is different with the one in the product table. -> Will be dealt with later

-- 4. Distinct values of product_category_name_english column
SELECT COUNT(DISTINCT product_category_name_english)
FROM product_category_eng
-- 72 unique values
-- There is no missing value.

-- 5. Duplicated rows
SELECT
	product_category_name,
	product_category_name_english,
	COUNT(*) AS cnt
FROM product_category_eng
GROUP BY 
	product_category_name,
	product_category_name_english
HAVING cnt > 1;
-- No duplicated rows

---------------------------------------- 
-- Geolocation Table
---------------------------------------- 

-- 1. Data type
DESCRIBE geolocation;
-- geolocation_zip_code_prefix: bigint
-- geolocation_lat & geolocation_lng: double
-- geolocation_city & geolocation_state: text

-- 2. Total # of rows
SELECT COUNT(*)
FROM geolocation
-- 1,000,163 rows

-- 3. Finding PK
-- Check zip_code_prefix
SELECT COUNT(DISTINCT geolocation_zip_code_prefix)
FROM geolocation;
-- 19,015 unique zip codes

-- Check the combination of all columns
SELECT COUNT(DISTINCT geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
FROM geolocation;
-- 720,496 
-- It has duplicated rows.
-- Go to the #4 section 

-- 4. Duplicated rows
SELECT
	geolocation_zip_code_prefix,
	geolocation_lat,
	geolocation_lng,
	geolocation_city,
	geolocation_state,
	COUNT(*) AS dup_cnt
FROM geolocation
GROUP BY 
	geolocation_zip_code_prefix,
	geolocation_lat,
	geolocation_lng,
	geolocation_city,
	geolocation_state
HAVING dup_cnt > 1;
-- 131,544 rows have duplicate values across zip prefix, lat, lng, city, and state.
-- These duplicates will be removed in later preprocessing.

-- 5. Distinct values of crucial columns
-- 5-1. geolocation_city
SELECT COUNT(DISTINCT geolocation_city) AS cnt_unique_cities
FROM geolocation;
-- 5,969 cities

-- 5-2. geolocation_state
SELECT COUNT(DISTINCT geolocation_state) AS cnt_unique_states
FROM geolocation;
-- 27 states


-- 6. Missing values 
SELECT
	SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_prefix,
	SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END) AS null_lat,
	SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END) AS null_lng,
	SUM(CASE WHEN geolocation_city IS NULL THEN 1 ELSE 0 END) AS null_city,
	SUM(CASE WHEN geolocation_state IS NULL THEN 1 ELSE 0 END) AS null_state
FROM geolocation;
-- No missing values



-- 7. About business logic
-- Out of Brazil based on lang, long -> It's worth checking since O-list deal with only Brazil. 
SELECT COUNT(*) AS cnt_not_brazil
FROM geolocation
WHERE geolocation_lat NOT BETWEEN -34.0 AND 5.3 -- From googling
   OR geolocation_lng NOT BETWEEN -73.9 AND -34.8; -- From googling
-- The geographic data from those 47 rows are out of Brazil -> Will be deleted later 
