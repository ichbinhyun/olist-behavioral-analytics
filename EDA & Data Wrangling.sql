---------------------------------
---------------------------------
-- DATA WRANGLING
---------------------------------
---------------------------------



---------------------------------
-- ORDER TABLE
---------------------------------

-- Missing values  

SELECT DISTINCT order_status
FROM orders


-- Related estimated delivery date

SELECT *
FROM orders 
WHERE order_estimated_delivery_date IS NULL
-- Result: ZERO

SELECT *
FROM orders 
WHERE order_purchase_timestamp IS NULL
-- Also Zero!


------------- CHECK anomalies based ON ORDER status

-- 1. Delivered 
-- Records that are actually delivered but aren't delivered to a customer or a carrier or aren't even approved 

SELECT *
FROM orders
WHERE orders.order_status = 'delivered'
	AND (orders.order_id IS NULL
		OR orders.order_approved_at IS NULL
		OR orders.order_delivered_carrier_date IS NULL
		OR orders.order_delivered_customer_date IS NULL  
		OR orders.order_estimated_delivery_date IS NULL
		OR orders.order_purchase_timestamp IS NULL
		OR orders.order_status IS NULL);

-- 23 Rows are violating the business logic.
-- Either it's actually delivered or not, but it's hard to check and they will be affecting a result of further analysis. -> Will be deleted 



-- 2. Shipped
-- shipped, but not delivered to a carrier or not approved

SELECT *
FROM orders
WHERE order_status = 'shipped'

SELECT *
FROM orders 
WHERE orders.order_status = 'shipped'
	AND (orders.order_delivered_carrier_date IS NULL
		OR orders.order_approved_at IS NULL
		OR orders.order_purchase_timestamp IS NULL
		OR orders.order_delivered_customer_date IS NOT NULL);
-- 0 row.



-- 3. Invoiced 

-- Check other columns when order status is 'invoiced'
SELECT *
FROM orders 
WHERE order_status = 'invoiced'
-- purchased_timestamp, approved_at should be filled


SELECT *
FROM orders
WHERE orders.order_status = 'invoiced'
	AND (orders.order_approved_at IS NULL
		OR orders.order_purchase_timestamp IS NULL
		OR orders.order_delivered_carrier_date IS NOT NULL
		OR orders.order_delivered_customer_date IS NOT NULL);
-- 0 row. 



-- 4. Processing


-- Check other columns when order status is 'processing'
SELECT *
FROM orders 
WHERE order_status = 'processing'
-- purchased_timestamp, approved_at should be filled


SELECT *
FROM orders
WHERE orders.order_status = 'processing'
	AND (orders.order_approved_at IS NULL
		OR orders.order_purchase_timestamp IS NULL
		OR orders.order_delivered_carrier_date IS NOT NULL
		OR orders.order_delivered_customer_date IS NOT NULL);
-- 0 row.



-- 5. Created

SELECT *
FROM orders
WHERE order_status = 'created'
-- Only 5 rows and they all have purchased_timestamps.
-- No anomaly

-- 6. Approved

SELECT *
FROM orders
WHERE order_status = 'approved'
-- Only 2 rows. No anomaly


-- 7. Unavailable

SELECT *
FROM orders 
WHERE order_status = 'unavailable'


SELECT *
FROM orders
WHERE orders.order_status = 'unavailable'
	AND (orders.order_approved_at IS NULL
		OR orders.order_purchase_timestamp IS NULL
		OR orders.order_delivered_carrier_date IS NOT NULL
		OR orders.order_delivered_customer_date IS NOT NULL);
-- 0 row.


-- 8. Canceled

SELECT *
FROM orders
WHERE order_status = 'canceled'
-- If a record has purchased_timestamp and estimated_delivery_date,
-- then, approved_at, delivered_carrier_date, delivered_customer_date can be NULL
 


-- Records that are against delivery flow
	
SELECT *
FROM orders
WHERE order_status = 'canceled'
  AND (
    -- Delivered but no previous records
    (order_delivered_customer_date IS NOT NULL AND (
        order_delivered_carrier_date IS NULL OR
        order_approved_at IS NULL
    ))
    OR
    -- Already devlivered to a carrier but no approved time
    (order_delivered_carrier_date IS NOT NULL AND order_approved_at IS NULL)
  );

-- 0 row 





----------------- TIME-SEQUENCE ANOMALIES
--- The cases are below: 
-- 1) delivered_carrier > delivered_customer -> Anomaly -> WIll be deleted
-- 2) Purchased_timestamp > Approved_at  -> Anomaly -> WIll be deleted

-- Not an anomaly that should be removed, but the case that should be monitored. 
-- 3) Approved_at > delivered_carrier -> will be flagged  


-- 1) delivered_carrier > delivered_customer

SELECT *
FROM orders 
WHERE order_delivered_carrier_date > order_delivered_customer_date
-- 23 rows. 

-- 2) Purchased_timestamp > Approved_at

SELECT *
FROM orders 
WHERE order_purchase_timestamp > order_approved_at;
-- 0 row 




-- 3) Approved_at > delivered_carrier

SELECT *
FROM orders 
WHERE order_approved_at > order_delivered_carrier_date
-- 1,359 rows.

-- 1,359 records will be flagged 

WITH orders_timediff AS (

	SELECT 
	  *,
		TIMESTAMPDIFF(HOUR, order_delivered_carrier_date, order_approved_at) AS hours_diff_approved_carrier,
	  CASE
	    WHEN TIMESTAMPDIFF(HOUR, order_delivered_carrier_date, order_approved_at) <= 0 THEN 'safe'
		WHEN TIMESTAMPDIFF(HOUR, order_delivered_carrier_date, order_approved_at) <= 2 THEN 'low'
	    WHEN TIMESTAMPDIFF(HOUR, order_delivered_carrier_date, order_approved_at) <= 24 THEN 'medium'
	    WHEN TIMESTAMPDIFF(HOUR, order_delivered_carrier_date, order_approved_at) IS NULL THEN NULL
	    ELSE 'high'
	  END AS payment_issue_risk_level
	FROM orders
)

SELECT *
FROM orders_timediff 
WHERE payment_issue_risk_level = 'high'
	AND order_status = 'shipped'
	





----- The LAST part TO CHECK anomalies 
-- Records that are in orders but not in order_items 


SELECT *
FROM orders o 
LEFT JOIN order_items oi
	ON o.order_id = oi.order_id 
WHERE oi.order_id IS NULL
-- 775 rows. 

SELECT
	o.order_status,
	COUNT(*) AS num
FROM orders o 
LEFT JOIN order_items oi
	ON o.order_id = oi.order_id 
WHERE oi.order_id IS NULL
GROUP BY o.order_status
-- Unavailable: 603, Canceled: 164, Created: 5, Invoiced: 2, Shipped: 1 



-- Check the distribution of order status when the table is joined

SELECT
	o.order_status,
	COUNT(*) AS num
FROM orders o 
LEFT JOIN order_items oi
	ON o.order_id = oi.order_id 
GROUP BY o.order_status
ORDER BY num DESC

-- all type of order status have values
-- Finding: order_items table can contain any order with any order status
-- Those records that are not in order_items might be dropped for some reason





-- FINALLY, creating views for anomalies in orders table

-- NULL based anomaly -> WILL BE DELETED

CREATE OR REPLACE VIEW orders_null_based_anomaly AS
SELECT *
FROM orders
WHERE order_status = 'delivered'
  AND (
    order_id IS NULL OR
    order_approved_at IS NULL OR
    order_delivered_carrier_date IS NULL OR
    order_delivered_customer_date IS NULL OR
    order_estimated_delivery_date IS NULL OR
    order_purchase_timestamp IS NULL OR
    order_status IS NULL
  );


-- time_flow_violation

CREATE OR REPLACE VIEW orders_time_flow_violation_anomaly AS
SELECT *
FROM orders 
WHERE order_delivered_carrier_date > order_delivered_customer_date;


CREATE OR REPLACE VIEW orders_time_flow_violation_flagging AS
SELECT *
FROM orders 
WHERE order_approved_at > order_delivered_customer_date
	OR order_approved_at > order_delivered_carrier_date;





-- Approved_at > delivered_carrier -> WILL KEEP IT BUT BE FLAGED! 

WITH orders_timediff AS (

	SELECT 
	  *,
		TIMESTAMPDIFF(HOUR, order_delivered_carrier_date, order_approved_at) AS hours_diff_approved_carrier,
	  CASE
	    WHEN TIMESTAMPDIFF(HOUR, order_delivered_carrier_date, order_approved_at) <= 0 THEN 'safe'
		WHEN TIMESTAMPDIFF(HOUR, order_delivered_carrier_date, order_approved_at) <= 2 THEN 'low'
	    WHEN TIMESTAMPDIFF(HOUR, order_delivered_carrier_date, order_approved_at) <= 24 THEN 'medium'
	    WHEN TIMESTAMPDIFF(HOUR, order_delivered_carrier_date, order_approved_at) IS NULL THEN NULL
	    ELSE 'high'
	  END AS payment_issue_risk_level
	FROM orders
)

SELECT *
FROM orders_timediff 






-- Orders in orders table but not in order_items table
-- Also, will be flagged with 'has_order_items' column. 1 = True, 0 = False




------ Cleaned Orders (after getting rid of all the anomalies and orders related to order_items)

CREATE TABLE cleaned_orders AS
SELECT 
    o.*,
    TIMESTAMPDIFF(HOUR, o.order_delivered_carrier_date, o.order_approved_at) AS hours_diff_approved_carrier,
    CASE
        WHEN TIMESTAMPDIFF(HOUR, o.order_delivered_carrier_date, o.order_approved_at) <= 0 THEN 'safe'
        WHEN TIMESTAMPDIFF(HOUR, o.order_delivered_carrier_date, o.order_approved_at) <= 2 THEN 'low'
        WHEN TIMESTAMPDIFF(HOUR, o.order_delivered_carrier_date, o.order_approved_at) <= 24 THEN 'medium'
        WHEN TIMESTAMPDIFF(HOUR, o.order_delivered_carrier_date, o.order_approved_at) IS NULL THEN NULL
        ELSE 'high'
    END AS payment_issue_risk_level,
    CASE 
        WHEN oi.order_id IS NULL THEN 0
        ELSE 1
    END AS has_order_items

FROM orders o

-- Anomalies related to NULL value
LEFT JOIN orders_null_based_anomaly null_anomaly
    ON o.order_id = null_anomaly.order_id
-- Time-violation anomalies
LEFT JOIN orders_time_flow_violation time_anomaly
    ON o.order_id = time_anomaly.order_id
LEFT JOIN (
    SELECT DISTINCT order_id FROM order_items
) oi
    ON o.order_id = oi.order_id
WHERE null_anomaly.order_id IS NULL
  AND time_anomaly.order_id IS NULL;



-- Check the cleaned one. 

SELECT *
FROM orders 
-- 99,441

SELECT *
FROM cleaned_orders;
-- 99,395



-- UPDATE! Approved > Customer_delivery_date

-- 1. Change the column name (payment_issue_risk_level → payment_issue_risk_level_ac)

ALTER TABLE cleaned_orders
CHANGE COLUMN payment_issue_risk_level payment_issue_risk_level_ac VARCHAR(10);

-- 2. A new column
ALTER TABLE cleaned_orders
ADD COLUMN hours_diff_approved_delivery INT,
ADD COLUMN payment_issue_risk_level_ad VARCHAR(10);

-- 3. Time diff : approved - delivered
UPDATE cleaned_orders
SET hours_diff_approved_delivery = TIMESTAMPDIFF(
    HOUR,
    order_delivered_customer_date,
    order_approved_at
);

-- 4. Updating Risk Level based on the time diff
UPDATE cleaned_orders
SET payment_issue_risk_level_ad = CASE
    WHEN hours_diff_approved_delivery IS NULL THEN NULL
    WHEN hours_diff_approved_delivery <= 0 THEN 'safe'
    WHEN hours_diff_approved_delivery <= 2 THEN 'low'
    WHEN hours_diff_approved_delivery <= 24 THEN 'medium'
    ELSE 'high'
END;


-- Last Check after updating (To flag)

SELECT *
FROM cleaned_orders 
WHERE order_approved_at > order_delivered_customer_date;
-- 61 rows 

SELECT *
FROM cleaned_orders
WHERE payment_issue_risk_level_ad IN ('low', 'medium', 'high')
	

SELECT 
	payment_issue_risk_level_ad,
	COUNT(*) AS num
FROM cleaned_orders
GROUP BY payment_issue_risk_level_ad 
-- 55 rows

SELECT *
FROM cleaned_orders
WHERE order_approved_at > order_delivered_customer_date
  AND payment_issue_risk_level_ad = 'safe';



-- Check cleaned_orders joined with order_payments

SELECT *
FROM cleaned_orders co
LEFT JOIN order_payments op
	ON co.order_id = op.order_id
WHERE op.order_id IS NULL

-- 1 row. 

-- Create a View for orders in cleaned_orders but not in order_payments

CREATE OR REPLACE VIEW cleaned_orders_not_in_payment AS
SELECT co.*
FROM cleaned_orders co
LEFT JOIN order_payments op
  ON co.order_id = op.order_id
WHERE op.order_id IS NULL;


-- Check cleaned_orders joined with customers

SELECT *
FROM cleaned_orders co
LEFT JOIN customers c
	ON co.customer_id = c.customer_id
WHERE c.customer_id IS NULL

-- 0 row


---------- NEED TO UPDATE! 

-- canceled but already delivered
SELECT *
FROM cleaned_orders
WHERE order_status = 'canceled'	
	AND order_delivered_customer_date IS NOT NULL
-- 6 orders 
-- Probably returns or refunds 
-- Need to check reviews 
	

-- Check reviews

SELECT *
FROM order_reviews
WHERE order_id IN (
    SELECT order_id
    FROM cleaned_orders
    WHERE order_status = 'canceled'	
      AND order_delivered_customer_date IS NOT NULL)

-- only 1 row is anomaly. Successfully delivered and reviewed but the order status is canceled. WRONG! 
-- The order status will be changed to 'delivered'
      
 
 UPDATE cleaned_orders
SET order_status = 'delivered'
WHERE order_id = 'dabf2b0e35b423f94618bf965fcb7514'
  AND order_status = 'canceled'
  AND order_delivered_customer_date IS NOT NULL;


-- UPDATE! check the duplicates
 
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    has_order_items,
    payment_issue_risk_level_ac,
    payment_issue_risk_level_ad,
    hours_diff_approved_carrier,
    hours_diff_approved_delivery,
    COUNT(*) AS dup_count
FROM cleaned_orders
GROUP BY 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    has_order_items,
    payment_issue_risk_level_ac,
    payment_issue_risk_level_ad,
    hours_diff_approved_carrier,
    hours_diff_approved_delivery
HAVING COUNT(*) > 1;
-- 0
 

-- UPDATE!!!
-- Data Type Check

SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'cleaned_orders'
  AND TABLE_SCHEMA = 'ec_portfolio1';


-- Data Type Change: Text to Datetime
  
  ALTER TABLE order_reviews
MODIFY COLUMN review_creation_date DATETIME;

ALTER TABLE order_reviews
MODIFY COLUMN review_answer_timestamp DATETIME;

-- Update Query
UPDATE order_reviews
SET review_creation_date = STR_TO_DATE(review_creation_date, '%Y-%m-%d %H:%i:%s'),
    review_answer_timestamp = STR_TO_DATE(review_answer_timestamp, '%Y-%m-%d %H:%i:%s');

ALTER TABLE cleaned_orders
MODIFY COLUMN order_purchase_timestamp DATETIME;

ALTER TABLE cleaned_orders
MODIFY COLUMN order_approved_at DATETIME;

ALTER TABLE cleaned_orders
MODIFY COLUMN order_delivered_carrier_date DATETIME;

ALTER TABLE cleaned_orders
MODIFY COLUMN order_delivered_customer_date DATETIME;

ALTER TABLE cleaned_orders
MODIFY COLUMN order_estimated_delivery_date DATETIME;






----------------------------------
-- ORDER_ITEMS TABLE
----------------------------------

----------------- CHECK ANOMALIES

-- Check the number of orders that are not in order_items, but in cleaned_orders

-- 1. has_order_items = 0 
SELECT COUNT(*) AS zero_item_orders
FROM cleaned_orders
WHERE has_order_items = 0;
-- 775

-- 2. Check with Left Join
SELECT COUNT(*) AS zero_item_orders
FROM cleaned_orders co
LEFT JOIN order_items oi
  ON co.order_id = oi.order_id
WHERE oi.order_id IS NULL;
-- 775

-- Is PK really unique? 
SELECT order_id, order_item_id, COUNT(*) AS cnt
FROM order_items
GROUP BY order_id, order_item_id
HAVING cnt > 1;


-- NULL first

SELECT *
FROM order_items
WHERE order_id IS NULL
	OR order_item_id IS NULL
	OR product_id IS NULL
	OR seller_id IS NULL
	OR shipping_limit_date IS NULL
	OR price IS NULL
	OR freight_value IS NULL;
-- 0 row



-- freight value zero? 

SELECT *
FROM order_items 
WHERE freight_value = 0;
-- 383 rows


-- Then, what happened with freight value zero rows? 


SELECT DISTINCT co.order_status
FROM order_items oi
LEFT JOIN cleaned_orders co
  ON oi.order_id = co.order_id
WHERE oi.freight_value = 0;
-- They are all either delivered or shipped. What does it mean? Does order_status relate to freight value?
-- There is a possibility for free delivery. So, hard to say it's anomaly




-- Approved_at > shipping_limit_date

WITH cleaned_orders_ship_limit AS (
	SELECT
		oi.order_id,
		oi.order_item_id,
		oi.product_id,
		oi.seller_id,
		co.order_purchase_timestamp,
		co.order_approved_at,
		oi.shipping_limit_date, 
		co.order_delivered_carrier_date,
		co.order_delivered_customer_date,
		co.order_estimated_delivery_date 
	FROM order_items oi
	LEFT JOIN cleaned_orders co
	  ON oi.order_id = co.order_id
	 ORDER BY oi.order_id ASC, oi.order_item_id ASC
 )
 
 
 SELECT DISTINCT order_id AS unique_order_id
 FROM cleaned_orders_ship_limit
 WHERE order_approved_at > shipping_limit_date;
 
-- 116 unique order ids.
-- No need to flag since shipping limit date isn't a part of actual delivery process.  
-- Howver, they will be useful when late or possible late devliery cases are discovered

 
 
 
 -- What about canceled or unavailable orders? 
 
 WITH cleaned_orders_order_items AS (
	SELECT oi.order_id, co.order_status
	FROM order_items oi
	LEFT JOIN cleaned_orders co
	  ON oi.order_id = co.order_id
 )
 
 SELECT DISTINCT order_id AS unique_order_id
 FROM cleaned_order_items
 WHERE order_status = 'canceled'
 	OR order_status = 'unavailable'
 
 -- 467 unique orders are canceled or unavailable. 
-- Those records will be kept since it might give insights to find a reason why those orders were cancelled. i.e) Because of specific sellers or products


-- price zero?

SELECT *
FROM order_items 
WHERE price = 0;
-- 0 row which is so great


-- Create views for flagging

-- Canceled or unavailable orders 


CREATE OR REPLACE VIEW order_items_canceled_unavailable AS
SELECT oi.*
FROM order_items oi
LEFT JOIN cleaned_orders co
  ON oi.order_id = co.order_id
WHERE co.order_status IN ('canceled', 'unavailable');


---- So, LONG story short, there IS NO need TO remove OR REPLACE VALUES IN order_items TABLE. Still IN ORDER TO CHECK, cleaned_order_items will be created.
-- No cleaning required. Table cloned for consistency and modularity.

CREATE TABLE cleaned_order_items AS
SELECT *
FROM order_items


-- UPDATE! check the duplicates haha 
 
 SELECT *, COUNT(*) 
FROM cleaned_order_items
GROUP BY order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value
HAVING COUNT(*) > 1;
-- 0, so done



-- UPDATE! OUTLIERS 
-- Need to think about whether they should be deleted or replaced, especially premium sellers

SELECT *
FROM cleaned_order_items
WHERE price = 0
-- 0 row


SELECT *
FROM cleaned_order_items 
ORDER BY price DESC;

SELECT *
FROM cleaned_order_items
WHERE price < freight_value
ORDER BY price ASC
-- price: 0.85,  freight value: 22.3 or 18.23. 
-- 3 order ids are below: 
-- c5bdd8ef3c0ec420232e668302179113
-- 3ee6513ae7ea23bdfab5b9ab60bffcb5
-- 6e864b3f0ec71031117ad4cf46b7f2a1
-- Now, let's check those 3 order_ids in the reviews table. 


SELECT
	coi.order_id,
	coi.product_id,
	coi.price,
	coi.freight_value,
	ors.*
FROM cleaned_order_items coi
JOIN order_reviews ors
	ON coi.order_id = ors.order_id
WHERE coi.order_id = 'c5bdd8ef3c0ec420232e668302179113';
-- Review message: "I bought two items: a LAN cable tester for RJ45 and RJ11, and a pack of 100 RJ45 connectors.
-- But the delivered box only contained the 100 connectors — the cable tester was missing."

SELECT
	coi.order_id,
	coi.product_id,
	coi.price,
	coi.freight_value,
	ors.*
FROM cleaned_order_items coi
JOIN order_reviews ors
	ON coi.order_id = ors.order_id
WHERE coi.order_id = '3ee6513ae7ea23bdfab5b9ab60bffcb5';
-- No comment for the review, only rating exists

SELECT
	coi.order_id,
	coi.product_id,
	coi.price,
	coi.freight_value,
	ors.*
FROM cleaned_order_items coi
JOIN order_reviews ors
	ON coi.order_id = ors.order_id
WHERE coi.order_id = '6e864b3f0ec71031117ad4cf46b7f2a1';
-- No comment for the review, only rating exists





--------------------------
-- CUSTOMER TABLE
--------------------------


-- Let's check by using views of anomaly

WITH customers_not_co AS (
	SELECT c.*
	FROM customers c 
	LEFT JOIN cleaned_orders co
		ON c.customer_id = co.customer_id
	WHERE co.customer_id IS NULL
),
anomalies_union AS (
	SELECT customer_id
	FROM orders_time_flow_violation_anomaly
	UNION
	SELECT customer_id
	FROM orders_null_based_anomaly
)
SELECT c.*
FROM customers_not_co c
JOIN anomalies_union a
	ON c.customer_id = a.customer_id;

-- SO, those 46 rows are actually anomalies from orders table. 
-- Since they are unvalid, delete them. 
	


-- Create a view for lovely 46 old anomalies 

CREATE VIEW customers_anomaly_from_orders AS 
SELECT c.*
FROM customers c 
LEFT JOIN cleaned_orders co
	ON c.customer_id = co.customer_id
WHERE co.customer_id IS NULL;


-- Cleaning cleaned_customers

CREATE TABLE cleaned_customers AS
WITH anomaly_customers AS (
	SELECT customer_id
	FROM customers_anomaly_from_orders
)
SELECT c.*
FROM customers c
LEFT JOIN anomaly_customers a
	ON c.customer_id = a.customer_id
WHERE a.customer_id IS NULL;



-- UPDATE! Check the duplicates 

SELECT *, COUNT(*) AS dup_count
FROM cleaned_customers
GROUP BY 
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
HAVING COUNT(*) > 1;
-- 0 so done 



SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'cleaned_customers'
  AND TABLE_SCHEMA = 'ec_portfolio1';



SELECT 
    ccpv.customer_city,
    ccpv.customer_state,
    ROUND(SUM(op.payment_value), 2) AS total_sales
FROM cleaned_customers_previous_version ccpv
JOIN cleaned_orders o
    ON ccpv.customer_id = o.customer_id
JOIN cleaned_order_payments op
    ON o.order_id = op.order_id
GROUP BY ccpv.customer_city, ccpv.customer_state
ORDER BY total_sales DESC;



----------------------------------
-- ORDER_REVIEWS TABLE
----------------------------------



-- Duplicates Detection
SELECT *
FROM order_reviews
GROUP BY review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp 
HAVING COUNT(*) > 1


SELECT review_id, order_id, review_score, review_comment_title,
       review_comment_message, review_creation_date, review_answer_timestamp,
       COUNT(*) as duplicate_count
FROM order_reviews
GROUP BY review_id, order_id, review_score, review_comment_title,
         review_comment_message, review_creation_date, review_answer_timestamp
HAVING COUNT(*) > 1;

-- No duplicate




---- Anamolies Detection

SELECT *
FROM order_reviews
WHERE review_creation_date IS NULL
	OR review_answer_timestamp IS NULL
	OR review_score IS NULL
	OR review_id IS NULL
	OR order_id IS NULL
-- All reviews have ids, creation date, answer timestamp, review score. 


-- Checking review_creation_date and answer_timestamp

SELECT *
FROM order_reviews
WHERE review_creation_date > review_answer_timestamp;
-- 0, So there is no anomaly. No need to clean.



-- Data Type Check

SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'order_reviews'
  AND TABLE_SCHEMA = 'ec_portfolio1';


-- Data Type Change: Text to Datetime
  
  ALTER TABLE order_reviews
MODIFY COLUMN review_creation_date DATETIME;

ALTER TABLE order_reviews
MODIFY COLUMN review_answer_timestamp DATETIME;

-- Update Query
UPDATE order_reviews
SET review_creation_date = STR_TO_DATE(review_creation_date, '%Y-%m-%d %H:%i:%s'),
    review_answer_timestamp = STR_TO_DATE(review_answer_timestamp, '%Y-%m-%d %H:%i:%s');


---------------------------------------- 
-- Products Table
---------------------------------------- 

-- Change typo in product_name_length and product_description_length

ALTER TABLE products
RENAME COLUMN product_name_lenght TO product_name_length;


-- Check Null values
SELECT COUNT(*) 
FROM products
WHERE product_category_name IS NULL;
-- > 610

SELECT COUNT(*) 
FROM products
WHERE product_id IS NULL;
-- > obviously 0



-- First, copy the original table

CREATE TABLE products_copy AS
SELECT * FROM products;

ALTER TABLE products
RENAME COLUMN product_description_lenght TO product_description_length;

ALTER TABLE products_copy
DROP COLUMN product_name_length,
DROP COLUMN product_description_length,
DROP COLUMN product_photos_qty,
DROP COLUMN product_weight_g,
DROP COLUMN product_length_cm,
DROP COLUMN product_height_cm,
DROP COLUMN product_width_cm;


-- Replace NUll values in category with etc

UPDATE products_copy
SET product_category_name = 'etc'
WHERE product_category_name IS NULL;

-- Check after replacing
SELECT product_category_name, COUNT(*) 
FROM products_copy
GROUP BY product_category_name
ORDER BY COUNT(*) DESC;



-- Check PK

SELECT *
FROM products_copy
-- 32,951 rows

SELECT product_id
FROM products_copy
GROUP BY product_id
-- 32,951 rows -> product_id IS PK


-- Check Duplicates

SELECT product_id, product_category_name
FROM products_copy
GROUP BY product_id, product_category_name
-- 0 rows


-- Data Type Check

SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'products_copy'
  AND TABLE_SCHEMA = 'ec_portfolio1';

-- PK check

SELECT
    k.COLUMN_NAME,
    k.CONSTRAINT_NAME,
    k.TABLE_NAME
FROM
    information_schema.TABLE_CONSTRAINTS t
JOIN
    information_schema.KEY_COLUMN_USAGE k
    ON t.CONSTRAINT_NAME = k.CONSTRAINT_NAME
    AND t.TABLE_SCHEMA = k.TABLE_SCHEMA
WHERE
    t.CONSTRAINT_TYPE = 'PRIMARY KEY'
    AND t.TABLE_NAME = 'products_copy'
    AND t.TABLE_SCHEMA = 'ec_portfolio1';


-- Check Unique category names

SELECT COUNT(DISTINCT product_category_name)
FROM products_copy
-- 74

SELECT COUNT(DISTINCT product_category_name)
FROM product_category_eng
-- 71



-- Insert etc to product_category_eng manually

INSERT INTO product_category_eng (product_category_name, product_category_name_english)
VALUES ('etc', 'etc');


-- Rows that are not in category_eng but in products_copy

SELECT DISTINCT p.product_category_name
FROM products_copy p
LEFT JOIN product_category_eng e
  ON p.product_category_name = e.product_category_name
WHERE e.product_category_name IS NULL;
-- pc gamer and blahblah -> will be put in the category eng manually


-- copy the category eng
CREATE TABLE product_category_eng_copy AS
SELECT * FROM product_category_eng;

INSERT INTO product_category_eng_copy (product_category_name, product_category_name_english)
VALUES 
  ('pc_gamer', 'pc_gamer'),
  ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_processors');


-- Find new values in the existing values in category_eng

SELECT *
FROM product_category_eng_copy
WHERE product_category_name_english LIKE '%kitchen%'
	OR product_category_name_english LIKE '%processer%'
	OR product_category_name_english LIKE '%food%'
-- No overlapping category name	

	
-- Join with product_category_eng

SELECT *
FROM products_copy pc
JOIN product_category_eng_copy pcec
	ON pc.product_category_name = pcec.product_category_name


SELECT pc.product_id, pc.product_category_name AS product_category, pcec.product_category_name_english AS product_category_eng
FROM products_copy pc
JOIN product_category_eng_copy pcec
	ON pc.product_category_name = pcec.product_category_name;


-- Cleaned Products with category_eng

CREATE TABLE cleaned_products AS 
SELECT pc.product_id, pc.product_category_name AS product_category, pcec.product_category_name_english AS product_category_eng
FROM products_copy pc
JOIN product_category_eng_copy pcec
	ON pc.product_category_name = pcec.product_category_name;


---------------------------------------- 
-- Order Payments Table
---------------------------------------- 

-- About payment type 

SELECT payment_type, COUNT(*) 
FROM order_payments
GROUP BY payment_type
-- credit_card, boleto, voucher, debit_card, not_defined


-- About payment_sequential 
SELECT DISTINCT payment_sequential 
FROM order_payments
ORDER BY payment_sequential DESC;
-- Max is 29 

-- dig it with the 29 sequential order
SELECT op.*
FROM order_payments op
JOIN (
    SELECT order_id
    FROM order_payments
    WHERE payment_sequential = 16
) AS target_orders
ON op.order_id = target_orders.order_id
ORDER BY op.order_id, op.payment_sequential;
-- Multiple vouchers or credit card + multiple vouchers




-- About installments
SELECT order_id, COUNT(*) AS payment_count
FROM order_payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_count DESC;

SELECT op.*
FROM order_payments op
JOIN (
    SELECT order_id
    FROM order_payments
    GROUP BY order_id
    HAVING COUNT(*) > 1
) multi_payments
ON op.order_id = multi_payments.order_id
ORDER BY op.order_id, op.payment_sequential;









-- Check each item's price when an order has several items 

WITH order_totals AS (
  SELECT
    order_id,
    ROUND(SUM(price + freight_value), 2) AS total_item_value
  FROM order_items
  GROUP BY order_id
),

payment_totals AS (
  SELECT
    order_id,
    ROUND(SUM(payment_value), 2) AS total_payment_value
  FROM order_payments
  GROUP BY order_id
)

SELECT 
  o.order_id,
  o.total_item_value,
  p.total_payment_value,
  o.total_item_value - p.total_payment_value AS diff
FROM order_totals o
JOIN payment_totals p ON o.order_id = p.order_id
WHERE ROUND(o.total_item_value, 2) != ROUND(p.total_payment_value, 2)
ORDER BY ABS(o.total_item_value - p.total_payment_value) DESC
LIMIT 50;



-- Check Anomalies

-- PK check

SELECT *
FROM order_payments 
-- 103,886 rows

SELECT DISTINCT order_id
FROM order_payments
-- 99,440 rows 

SELECT *
FROM order_payments
GROUP BY order_id, payment_sequential 
-- 103,886 rows 
-- So, PK is {order_id, payment_sequential}

-- Check Duplicates

SELECT 
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    COUNT(*) AS row_count
FROM order_payments
GROUP BY 
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
HAVING COUNT(*) > 1
ORDER BY row_count DESC;
-- 0


-- Check Missing Values

SELECT
  SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
  SUM(CASE WHEN payment_sequential IS NULL THEN 1 ELSE 0 END) AS null_payment_sequential,
  SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) AS null_payment_type,
  SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END) AS null_payment_installments,
  SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) AS null_payment_value
FROM order_payments;
-- All zero


-- Against business logic

-- Payment type is Voucher or Boleto, but with installments?  
SELECT payment_type, payment_installments, COUNT(*) AS count
FROM order_payments
WHERE payment_type IN ('boleto', 'voucher', 'debit_card') AND payment_installments > 1
GROUP BY payment_type, payment_installments
ORDER BY count DESC;
-- None


-- Payment type: not_defined -> But payment value is 0 and canceled. 

SELECT *
FROM order_payments 
WHERE payment_type = 'not_defined'
-- 3 different orders and payment_values are all 0
-- Check them in other tables

-- 4637ca194b6387e2d538dc89b124b0ee
-- 00b1cb0320190ca0daa2c88b35206009
-- c8c528189310eaa44a745b8d9d26908b

-- They are all in cleaned_orders table. Those are all canceled
-- Those three aren't in cleaned_order_items.
-- Two of them have reviews, but the other one doesn't even have it
-- --> Will be deleted

-- Check the actual values
SELECT *
FROM cleaned_order_reviews
WHERE order_id = 'c8c528189310eaa44a745b8d9d26908b'



-- 0 or negative payment value

SELECT *
FROM order_payments
WHERE payment_value <= 0;
-- 9 rows

-- installment = 0 or negative

SELECT *
FROM order_payments
WHERE payment_installments <= 0;
-- 2 


-- 0 or negative sequential

SELECT *
FROM order_payments 
WHERE payment_sequential <= 0
-- 0


  
 -- Using creadit card or debit card more than once in an order.
  
SELECT op.*
FROM order_payments op
JOIN (
    SELECT order_id, payment_type
    FROM order_payments
    WHERE payment_type IN ('credit_card', 'debit_card')
    GROUP BY order_id, payment_type
    HAVING COUNT(*) > 1
) dup
ON op.order_id = dup.order_id
WHERE op.payment_type = dup.payment_type
ORDER BY op.order_id, op.payment_type, op.payment_sequential;
-- A lot.
-- And it's not a problem to pay with several cards in Brazil


-- Copy the table 

CREATE TABLE order_payments_copy AS
SELECT *
FROM order_payments;

-- Deleting anomalies
-- Not defined one
-- payment value <= 0
-- installments <= 0

SELECT *
FROM order_payments
WHERE payment_type = 'not_defined'
   OR payment_value <= 0
   OR payment_installments <= 0;
-- 11


DELETE FROM order_payments_copy
WHERE payment_type = 'not_defined'
   OR payment_value <= 0
   OR payment_installments <= 0;




---------------------------------------- 
-- Seller Table
---------------------------------------- 

-- The Number of Sellers 

SELECT COUNT(DISTINCT seller_id)
FROM sellers
-- 3095 sellers = 3095 rows. seller_id is PK. 


-- The Number of Seller City

SELECT COUNT(DISTINCT seller_city)
FROM sellers;
-- 610 cities. 


-- The Number of Seller State

SELECT COUNT(DISTINCT seller_state)
FROM sellers;
-- 23 states. 


-- Top Sellers


-- Top Selling Product Categories

SELECT 
  pct.product_category_name_english AS category,
  COUNT(DISTINCT oi.order_id) AS num_orders,
  ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
JOIN cleaned_products p ON oi.product_id = p.product_id
LEFT JOIN cleaned_product_category_eng pct
  ON p.product_category_name = pct.product_category_name
GROUP BY pct.product_category_name_english
ORDER BY total_revenue DESC, num_orders DESC;


-- Top 10 Selling Product Categories

SELECT 
  pct.product_category_name_english AS category,
  COUNT(DISTINCT oi.order_id) AS num_orders,
  ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
JOIN cleaned_products p ON oi.product_id = p.product_id
LEFT JOIN cleaned_product_category_eng pct
  ON p.product_category_name = pct.product_category_name
GROUP BY pct.product_category_name_english
ORDER BY total_revenue DESC, num_orders DESC
LIMIT 10;
-- 0



---- Check Anomalies


-- Duplicates

SELECT seller_id, seller_zip_code_prefix, seller_city, seller_state
FROM sellers
GROUP BY seller_id, seller_zip_code_prefix, seller_city, seller_state
-- 3,005 rows. No prob


-- Data Type Check

SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sellers'
  AND TABLE_SCHEMA = 'ec_portfolio1';
-- zip code prefix = bigint, the rest of them are text -> no prob

-- Outliers -> No need to check

-- Check Missing Values

SELECT *
FROM sellers
WHERE seller_id IS NULL
	OR seller_zip_code_prefix IS NULL
	OR seller_city IS NULL
	OR seller_state IS NULL;
-- 0 rows. No prob


-- Business Logic-wise

-- Sellers who are not in order_items. 
SELECT *
FROM sellers s
LEFT JOIN order_items oi
  ON s.seller_id = oi.seller_id
WHERE oi.seller_id IS NULL;
-- 0


SELECT 
  seller_zip_code_prefix,
  seller_city,
  seller_state,
  COUNT(*) AS seller_count
FROM sellers
GROUP BY seller_zip_code_prefix, seller_city, seller_state
HAVING COUNT(*) > 5
ORDER BY seller_count DESC;


-- City & State namce check

SELECT COUNT(DISTINCT seller_city)
FROM sellers