
----------------------------
----------------------------
-- Problem Statement
----------------------------
----------------------------


-- Who are the customers and sellers?
-- How are their behaviors?
-- How can we increase the number of active sellers on the platform?
-- How can we increase sellers' consistent activity and customer retention? 
-- How can we help sellers increase their sales performance? 
-- How can we ensure product variety that benefits both sellers and customers, without pushing products that don’t sell?



-- Data Period based on purchase timestamp

SELECT MIN(order_purchase_timestamp)
FROM cleaned_orders 
WHERE order_status = 'delivered'
-- 2016-09-15

SELECT MAX(order_purchase_timestamp)
FROM cleaned_orders
WHERE order_status = 'delivered'
-- 2018-08-29



----------------------------
----------------------------
-- KPIs 
----------------------------
----------------------------



----------------------------
-- 1. SALES
----------------------------


-- 1-1. AOV (Average Order Value)
-- SUM(payment_value) / COUNT(DISTINCT order_id)


SELECT
	ROUND(SUM(cop.payment_value) / COUNT(DISTINCT co.order_id), 2) AS aov
FROM cleaned_order_payments cop
JOIN cleaned_orders co
	ON cop.order_id = co.order_id
WHERE co.order_status = 'delivered'
-- 159.85




-- 1-2. Annual Sales Trend


-- Only Year
SELECT
	YEAR(co.order_purchase_timestamp) AS YEAR,
	ROUND(SUM(cop.payment_value), 2) AS total_sales
FROM cleaned_order_payments cop 
JOIN cleaned_orders co
	ON cop.order_id = co.order_id
WHERE co.order_status = 'delivered'
GROUP BY YEAR(co.order_purchase_timestamp)
ORDER BY YEAR ASC;

-- 2016: 46,067.71
-- 2017: 6,916,544.95
-- 2018: 8,451,736.48


-- 1-2-1. Total number of orders in 2016 (Delivered)

SELECT
	YEAR(co.order_purchase_timestamp) AS YEAR,
	COUNT(*) AS total_num_orders
FROM cleaned_order_payments cop 
JOIN cleaned_orders co
	ON cop.order_id = co.order_id
WHERE co.order_status = 'delivered'
GROUP BY YEAR(co.order_purchase_timestamp)
ORDER BY YEAR ASC;


-- Only Region
SELECT
	cc.customer_state AS state,
	ROUND(SUM(cop.payment_value), 2) AS total_sales
FROM cleaned_order_payments cop 
JOIN cleaned_orders co
	ON cop.order_id = co.order_id
JOIN cleaned_customers cc
	ON cc.customer_id = co.customer_id
WHERE co.order_status = 'delivered'
GROUP BY cc.customer_state
ORDER BY total_sales DESC;

-- Top 10 States: SP, RJ, MG, RS, PR, SC, BA, DF, GO, ES

SELECT 
	cs.seller_city,
	ROUND(SUM(price), 2) AS total_sales 
FROM cleaned_order_items coi 
JOIN cleaned_orders co
	ON coi.order_id = co.order_id
JOIN cleaned_sellers cs
	ON cs.seller_id = coi.seller_id
GROUP BY cs.seller_city
ORDER BY total_sales DESC
LIMIT 5;




-- Both Regions and Years
SELECT
	YEAR(co.order_purchase_timestamp) AS YEAR,
	cc.customer_state AS state,
	ROUND(SUM(cop.payment_value), 2) AS total_sales
FROM cleaned_order_payments cop 
JOIN cleaned_orders co
	ON cop.order_id = co.order_id
JOIN cleaned_customers cc
	ON cc.customer_id = co.customer_id
WHERE co.order_status = 'delivered'
GROUP BY YEAR(co.order_purchase_timestamp), cc.customer_state
ORDER BY YEAR ASC, total_sales DESC;



-- 1-3. Growth Rate of Product Categories

-- 2018.10.07 was the last but for convience, ignored Oct, and chose Jul, Aug, Sep

-- The recent 3 months sales

CREATE VIEW recent_3months_sales AS 
WITH items_with_status AS (
	SELECT 
		coi.order_id,
		coi.product_id,
		coi.price,
		co.order_status
	FROM cleaned_order_items coi
	JOIN cleaned_orders co
	ON coi.order_id = co.order_id
	WHERE co.order_status = 'delivered'
		AND YEAR(co.order_purchase_timestamp) = 2018
		AND MONTH(co.order_purchase_timestamp) IN (07, 08, 09)
)

SELECT
	cp.product_category_eng AS product_category,
	ROUND(SUM(iws.price), 2) AS total_sales 
FROM cleaned_products cp
JOIN items_with_status iws
	ON cp.product_id = iws.product_id
GROUP BY cp.product_category_eng
ORDER BY total_sales DESC; 



-- The previous 3 months sales from the most recent one 

CREATE VIEW previous_3months_sales AS 
WITH items_with_status AS (
	SELECT 
		coi.order_id,
		coi.product_id,
		coi.price,
		co.order_status
	FROM cleaned_order_items coi
	JOIN cleaned_orders co
	ON coi.order_id = co.order_id
	WHERE co.order_status = 'delivered'
		AND YEAR(co.order_purchase_timestamp) = 2018
		AND MONTH(co.order_purchase_timestamp) IN (04, 05, 06)
)

SELECT
	cp.product_category_eng AS product_category,
	ROUND(SUM(iws.price), 2) AS total_sales 
FROM cleaned_products cp
JOIN items_with_status iws
	ON cp.product_id = iws.product_id
GROUP BY cp.product_category_eng
ORDER BY total_sales DESC; 



-- Growth Rate Calculation

SELECT
	rms.product_category,
	rms.total_sales AS recent_3month_sales,
	pms.total_sales AS previous_3month_sales,
	CASE 
  		WHEN pms.total_sales = 0 THEN NULL
  		ELSE ROUND((rms.total_sales - pms.total_sales) / pms.total_sales * 100, 1)
	END AS growth_rate
FROM recent_3months_sales rms 
JOIN previous_3months_sales pms 
	ON rms.product_category = pms.product_category
ORDER BY growth_rate DESC;



-- 1-4.  Fulfillment Rate

SELECT
  ROUND((
    (SELECT COUNT(*) 
     FROM cleaned_orders 
     WHERE order_status = 'delivered')
    /
    (SELECT COUNT(*) 
     FROM cleaned_orders)
  ) * 100, 2) AS order_fulfillment_rate;
-- 97.2% 


-- Order Fulfillment Rate by Year

SELECT
  YEAR(order_purchase_timestamp) AS year,
  ROUND(
    SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2
  ) AS order_fulfillment_rate
FROM cleaned_orders
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY year;
-- it Keeps increasing over years



-- 1-5. Total Sales by Payment Type Over Year

SELECT
	YEAR(co.order_purchase_timestamp) AS YEAR,
	cop.payment_type,
	ROUND(SUM(cop.payment_value), 2) AS total_sales
FROM cleaned_order_payments cop
JOIN cleaned_orders co
	ON cop.order_id = co.order_id
WHERE co.order_status = 'delivered'
GROUP BY YEAR(co.order_purchase_timestamp), cop.payment_type
ORDER BY YEAR ASC, total_sales DESC;



-- 1-6. Sold Category Diversity by Year

SELECT 
	YEAR(co.order_purchase_timestamp) AS YEAR,
	COUNT(DISTINCT cp.product_category_eng) AS count_product_category
FROM cleaned_orders co
JOIN cleaned_order_items coi
	ON co.order_id = coi.order_id
JOIN cleaned_products cp
	ON coi.product_id = cp.product_id
GROUP BY YEAR(co.order_purchase_timestamp)
ORDER BY YEAR ASC;
-- 2016: 32, 2017: 73, 2018: 73


SELECT COUNT(DISTINCT product_category_eng)
FROM cleaned_products;


-- (Optional) Category Sold by Year

WITH total_categories AS (
	SELECT COUNT(DISTINCT product_category_eng) AS total_catalog_categories
	FROM cleaned_products
),
sold_by_year AS (
	SELECT 
		YEAR(co.order_purchase_timestamp) AS year,
		COUNT(DISTINCT cp.product_category_eng) AS categories_sold
	FROM cleaned_orders co
	JOIN cleaned_order_items coi ON co.order_id = coi.order_id
	JOIN cleaned_products cp ON coi.product_id = cp.product_id
	WHERE co.order_status = 'delivered'
	GROUP BY YEAR(co.order_purchase_timestamp)
)

SELECT
	s.year,
	s.categories_sold,
	t.total_catalog_categories,
	ROUND((s.categories_sold / t.total_catalog_categories) * 100, 1) AS category_utilization_pct
FROM sold_by_year s, total_categories t
ORDER BY s.year;


-- Which category didn't make a sale in 2017 and 2018? 

WITH sold_categories_1718 AS (
	SELECT DISTINCT cp.product_category_eng
	FROM cleaned_orders co
	JOIN cleaned_order_items coi ON co.order_id = coi.order_id
	JOIN cleaned_products cp ON coi.product_id = cp.product_id
	WHERE co.order_status = 'delivered'
	  AND YEAR(co.order_purchase_timestamp) = 2017
)

SELECT DISTINCT cp.product_category_eng
FROM cleaned_products cp
WHERE cp.product_category_eng NOT IN (
	SELECT product_category_eng FROM sold_categories_1718
);
-- portable Kitchen and food processors

WITH sold_categories_1718 AS (
	SELECT DISTINCT cp.product_category_eng
	FROM cleaned_orders co
	JOIN cleaned_order_items coi ON co.order_id = coi.order_id
	JOIN cleaned_products cp ON coi.product_id = cp.product_id
	WHERE co.order_status = 'delivered'
	  AND YEAR(co.order_purchase_timestamp) = 2018
)

SELECT DISTINCT cp.product_category_eng
FROM cleaned_products cp
WHERE cp.product_category_eng NOT IN (
	SELECT product_category_eng FROM sold_categories_1718
);
-- Security and Services


-- 1-7) Num of sold Products

-- 1-7) Number of Sold Products
SELECT COUNT(*) AS num_sold_products
FROM cleaned_order_items coi
JOIN cleaned_orders cs
    ON coi.order_id = cs.order_id
WHERE cs.order_status = 'delivered';




-- 1-8) Sales by Product Category Across Year

SELECT
	cp.product_category_eng AS category,
	ROUND(SUM(coi.price), 2) AS total_sales
FROM cleaned_products cp
JOIN cleaned_order_items coi
	ON cp.product_id = coi.product_id
GROUP BY cp.product_category_eng 
ORDER BY total_sales DESC
LIMIT 5;




----------------------------
-- SELLERS
----------------------------

---------------------------
-- SELLER DIVISION FIRST
---------------------------

-- Top 5% sellers

-- Step 1: for seller's total sales

CREATE VIEW premium_sellers AS 
WITH seller_sales AS (
  SELECT
    coi.seller_id,
    ROUND(SUM(coi.price), 2) AS total_sales
  FROM cleaned_order_items coi
  JOIN cleaned_orders co ON coi.order_id = co.order_id
  WHERE co.order_status = 'delivered'
  GROUP BY coi.seller_id
),

-- Step 2: Only top 5%
ranked_sellers AS (
  SELECT
    seller_id,
    total_sales
  FROM seller_sales
  ORDER BY total_sales DESC
  LIMIT 155
)

SELECT * FROM ranked_sellers;




-- AOV of premium sellers

WITH seller_sales AS (
  SELECT
    coi.seller_id,
    SUM(coi.price) AS total_sales,
    COUNT(DISTINCT coi.order_id) AS num_orders
  FROM cleaned_order_items coi
  JOIN cleaned_orders co ON coi.order_id = co.order_id
  WHERE co.order_status = 'delivered'
  GROUP BY coi.seller_id
),

premium_sellers AS (
  SELECT
    seller_id,
    total_sales
  FROM seller_sales
  ORDER BY total_sales DESC
  LIMIT 155
),

premium_seller_aov AS (
  SELECT
    ss.seller_id,
    ss.total_sales,
    ss.num_orders,
    ROUND(ss.total_sales / ss.num_orders, 2) AS aov
  FROM seller_sales ss
  JOIN premium_sellers ps ON ss.seller_id = ps.seller_id
)

SELECT * FROM premium_seller_aov
ORDER BY aov DESC;

-- Rank based on median
CREATE VIEW premium_sellers_with_type AS
WITH seller_sales AS (
  SELECT
    coi.seller_id,
    SUM(coi.price) AS total_sales,
    COUNT(DISTINCT coi.order_id) AS num_orders
  FROM cleaned_order_items coi
  JOIN cleaned_orders co ON coi.order_id = co.order_id
  WHERE co.order_status = 'delivered'
  GROUP BY coi.seller_id
),

premium_sellers AS (
  SELECT
    seller_id,
    total_sales
  FROM seller_sales
  ORDER BY total_sales DESC
  LIMIT 155
),

premium_seller_aov AS (
  SELECT
    ss.seller_id,
    ss.total_sales,
    ss.num_orders,
    ROUND(ss.total_sales / ss.num_orders, 2) AS aov
  FROM seller_sales ss
  JOIN premium_sellers ps ON ss.seller_id = ps.seller_id
),


ranked AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (ORDER BY aov DESC) AS rn
  FROM premium_seller_aov
),

median_split AS (
  SELECT 
    *,
    CASE 
      WHEN rn <= CEIL(155 / 2) THEN 'highend_premium'
      ELSE 'volume_premium'
    END AS premium_type
  FROM ranked
)

SELECT * FROM median_split;


-- Creating the 'seller_type' Column

ALTER TABLE cleaned_sellers
ADD COLUMN seller_type VARCHAR(50);


-- Update seller type
-- highend_premium, volume_premium
UPDATE cleaned_sellers cs
JOIN premium_sellers_with_type pswt
  ON cs.seller_id = pswt.seller_id
SET cs.seller_type = pswt.premium_type;


-- Else -> regular
UPDATE cleaned_sellers
SET seller_type = 'regular'
WHERE seller_type IS NULL;



--------------------------
-- SELLER KPI
--------------------------



-- 1. The number of sellers by seller type

SELECT
    seller_type,
    COUNT(DISTINCT seller_id) AS seller_count
FROM
    cleaned_sellers
GROUP BY
    seller_type;
-- Premium: 155, Regular: 2940 
-- Highend: 78, Volume: 77


-- 2. The average sales by seller_type

SELECT
    s.seller_type,
    ROUND(SUM(oi.price) / COUNT(DISTINCT s.seller_id), 2) AS avg_total_sales_per_seller
FROM cleaned_order_items oi
JOIN cleaned_orders o ON oi.order_id = o.order_id
JOIN cleaned_sellers s ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_type;
-- Highend: 46,810.14
-- Volume: 44,934.95
-- Regular: 2,169.77




-- Create a table for efficient processing. 

CREATE TABLE delivered_order_items AS
SELECT
    oi.order_id,
    oi.seller_id,
    s.seller_type,
    YEAR(o.order_purchase_timestamp) AS year,
    oi.price
FROM cleaned_order_items oi
JOIN cleaned_orders o ON oi.order_id = o.order_id
JOIN cleaned_sellers s ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered';



-- 3. AOV by seller type

SELECT
    seller_type,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2) AS avg_aov
FROM delivered_order_items
GROUP BY seller_type;
-- highend: 327.64
-- Volume: 102.12
-- Regular: 117.41
-- Highend sellers tend to have a higher AOV, but likely a lower sales frequency.
-- On the other hand, volume sellers have an AOV similar to that of regular sellers which implies they’re selling a much higher quantity.
-- The ideal scenario would be to encourage a significant number of regular sellers to transition into volume premium sellers.



-- 4. Total Sales by Seller Type Over Year

SELECT
    seller_type,
    year,
    ROUND(SUM(price), 2) AS total_sales
FROM delivered_order_items
GROUP BY seller_type, year
ORDER BY seller_type, year;
-- Highend & Volume: Increase constantly except for 17/18 
-- Regualr: An impressively steady growth. 17/18 was awesome 


-- 4-1. Total Sales by seller type

SELECT
    seller_type,
    ROUND(SUM(price), 2) AS total_sales
FROM delivered_order_items
GROUP BY seller_type
ORDER BY total_sales DESC;
-- Regular: 6,103,568.31
-- Highend: 3,651,190.75
-- Volume: 3,459,911.5


-- 5. Region Distribution of Sellers

SELECT
	seller_type,
	COUNT(DISTINCT seller_state) AS num_state,
	COUNT(DISTINCT seller_city) AS num_cities
FROM cleaned_sellers
GROUP BY seller_type


-- 5-1. Which State and City Each Type of Sellers stay the most? 

-- State
SELECT seller_type, seller_state, seller_count
FROM (
    SELECT
        seller_type,
        seller_state,
        COUNT(*) AS seller_count,
        ROW_NUMBER() OVER (PARTITION BY seller_type ORDER BY COUNT(*) DESC) AS row_num
    FROM cleaned_sellers
    GROUP BY seller_type, seller_state
) AS ranked
WHERE row_num = 1;
-- SP


-- City
SELECT seller_type, seller_city, seller_count
FROM (
    SELECT
        seller_type,
        seller_city,
        COUNT(*) AS seller_count,
        ROW_NUMBER() OVER (PARTITION BY seller_type ORDER BY COUNT(*) DESC) AS row_num
    FROM cleaned_sellers
    GROUP BY seller_type, seller_city
) AS ranked
WHERE row_num = 1;
-- Sao Paulo



-- Creating a Table for efficient work

CREATE TABLE delivered_order_items_full AS
SELECT
    oi.order_id,
    oi.product_id,
    oi.seller_id,
    s.seller_type,
    p.product_category_eng,
    o.order_purchase_timestamp,
    oi.price,
    oi.freight_value
FROM cleaned_order_items oi
JOIN cleaned_orders o ON oi.order_id = o.order_id
JOIN cleaned_sellers s ON oi.seller_id = s.seller_id
JOIN cleaned_products p ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered';



-- 6. The number of categories by seller type

SELECT
    seller_type,
    COUNT(DISTINCT product_category_eng) AS num_categories
FROM delivered_order_items_full
GROUP BY seller_type
ORDER BY num_categories DESC;
-- Highend: 53
-- Volume: 57
-- Regular: 72
-- Highend sellers deal with more categories than I expected. However, there's still a room to improve

-- 6-1. Categories by seller_type
SELECT
    seller_type,
    product_category_eng,
    COUNT(*) AS num_orders,
    ROUND(SUM(price), 2) AS total_sales -- or SUM(price) if you want sales volume
FROM delivered_order_items_full
GROUP BY seller_type, product_category_eng
ORDER BY seller_type, num_orders DESC;
-- Highend: wathches_gifts, office_furniture, health_beauty, computers_accessories, cool_stuff, and so son
-- Volume: bed_bath_table, furniture_docor, health_beauty, computers_accessories, garden_tools, and so son
-- Regular: sport_leisure, housewares, health_beauty, furniture_decor, bed_bath_table, and so son



-- 7. Posiible Dormant Seller Rate
-- The proportion of sellers who haven't made any sales for a long period since their last sale.

WITH last_sales AS (
  SELECT
    seller_id,
    MAX(DATE(order_purchase_timestamp)) AS last_sale_date
  FROM delivered_order_items_full
  GROUP BY seller_id
),
dormant_flagged AS (
  SELECT
    ls.seller_id,
    cs.seller_type,
    ls.last_sale_date,
    DATEDIFF('2018-10-17', ls.last_sale_date) AS days_since_last_sale,
    CASE 
      WHEN DATEDIFF('2018-10-17', ls.last_sale_date) > 180 THEN 1
      ELSE 0
    END AS is_dormant
  FROM last_sales ls
  JOIN cleaned_sellers cs ON ls.seller_id = cs.seller_id
)
SELECT
  seller_type,
  COUNT(*) AS total_sellers,
  SUM(is_dormant) AS dormant_sellers,
  ROUND(SUM(is_dormant) * 100.0 / COUNT(*), 2) AS dormant_rate_percent
FROM dormant_flagged
GROUP BY seller_type
ORDER BY dormant_rate_percent DESC;

-- Regular -> Total Sellers:2813, dormant sellers:958, dormant_rate_percent: 34.06
-- Highend -> Total Sellers:78, dormant sellers:6, dormant_rate_percent: 7.69
-- volume -> Total Sellers:77, dormant sellers:3, dormant_rate_percent: 3.9
-- Clearly, there are fewer dormant or long-inactive sellers among premium sellers.
-- However, among regular sellers, the rate is as high as 34% — about one-third. This needs to be reduced.
-- Offer commission discounts, opportunities to participate in promotions, and provide a sales reactivation guide targeting regular sellers (e.g., suggesting popular product categories).

-- 8. Consistent Selling Rate by Type 
-- Based on the last purchase date in the dataset, which is 2018-10-17, a 12-month period is considered.
-- Sellers are considered consistent if they made at least one sale in 6 out of those 12 months.

-- YEAR() and MONTH() functions are used together to group data by month.

WITH filtered_orders AS (
  SELECT
    seller_id,
    seller_type,
    CONCAT(YEAR(order_purchase_timestamp), '-', LPAD(MONTH(order_purchase_timestamp), 2, '0')) AS order_month
  FROM delivered_order_items_full
  WHERE order_purchase_timestamp BETWEEN '2017-10-17' AND '2018-10-17'
  GROUP BY seller_id, seller_type, YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
),

monthly_sales_count AS (
  SELECT
    seller_id,
    seller_type,
    COUNT(DISTINCT order_month) AS active_months
  FROM filtered_orders
  GROUP BY seller_id, seller_type
),

consistency_flagged AS (
  SELECT
    seller_type,
    COUNT(*) AS total_sellers,
    SUM(CASE WHEN active_months >= 6 THEN 1 ELSE 0 END) AS consistent_sellers
  FROM monthly_sales_count
  GROUP BY seller_type
)

SELECT
  seller_type,
  total_sellers,
  consistent_sellers,
  ROUND(consistent_sellers * 100.0 / total_sellers, 2) AS consistent_rate_percent
FROM consistency_flagged
ORDER BY consistent_rate_percent DESC;

-- Regular -> total sellers:2375, consistent sellers:650, consistent rate percent: 27.37
-- Highend -> total sellers:76, consistent sellers:66, consistent rate percent: 86.84
-- Volume -> total sellers:77, consistent sellers:76, consistent rate percent: 98.7
-- High-end and volume sellers show high consistency in monthly sales. It would be ideal if the consistency rate for high-end sellers were even higher.
-- Regular sellers have noticeably lower consistency. This reflects Olist’s business model that supports small and medium-sized sellers, many of whom might be running their store as a side business.
-- Still, increasing their consistency rate would definitely be beneficial.
-- Regular sellers who maintain consistent sales have the potential to become premium sellers — time to promote growth strategies.
-- Offer growth incentive programs: support for shipping costs, exposure via promotional campaigns, and performance reports (e.g., “You’re in the top X%”) to boost activity.
-- Continuous monitoring is required for high-end and volume sellers.











-----------------------------------------
-- CUSTOMERS
-----------------------------------------


----------------------------
-- Customer Segmentation
----------------------------

-- Using the top 5% by spending, like we did with sellers, is not ideal for customers because the spending cutoff was only 410.
-- We need a different strategy.
-- The segmentation should be: High-End Premium, Volume Premium, Heavy Regular, One-Time High-End, and Regular.


-- So many customers only order once. So it is necessary to know their ratio 
SELECT
  COUNT(CASE WHEN cbm.total_orders = 1 THEN 1 END) AS one_time_customers,
  COUNT(*) AS total_customers,
  ROUND(COUNT(CASE WHEN cbm.total_orders = 1 THEN 1 END) / COUNT(*) * 100, 2) AS one_time_customer_ratio
FROM customer_base_metrics cbm;
-- 97퍼

-- Total Sales Between Top 5% Customer and the Rest

WITH customer_spending AS (
  SELECT
    c.customer_unique_id,
    SUM(oi.price) AS total_spending
  FROM cleaned_orders o
  JOIN cleaned_order_items oi ON o.order_id = oi.order_id
  JOIN cleaned_customers c ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id
),

ranked_spending AS (
  SELECT
    customer_unique_id,
    total_spending,
    ROW_NUMBER() OVER (ORDER BY total_spending DESC) AS row_num,
    COUNT(*) OVER () AS total_customers
  FROM customer_spending
)

SELECT
  CASE 
    WHEN row_num <= total_customers * 0.05 THEN 'Top 5%'
    ELSE 'Bottom 95%'
  END AS customer_group,
  COUNT(customer_unique_id) AS customer_count,
  ROUND(SUM(total_spending), 2) AS total_spending,
  ROUND(AVG(total_spending), 2) AS avg_spending_per_customer
FROM ranked_spending
GROUP BY customer_group
ORDER BY total_spending DESC;

-- Top 5%: 3,849,943.83
-- Bottom 95%: 9,364,806.73
-- Top 5% customers take 29.13% 



-- Customer_base_metrics 

CREATE TABLE customer_base_metrics (
    customer_unique_id VARCHAR(50),
    total_orders INT,
    total_spending FLOAT,
    aov FLOAT,
    highend_seller_ratio_order FLOAT,
    highend_seller_ratio_spending FLOAT
);

INSERT INTO customer_base_metrics
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id),
    SUM(oi.price),
    AVG(oi.price),

    -- Ratio of highend seller (COUNT-wise)
    SUM(CASE WHEN s.seller_type = 'highend_premium' THEN 1 ELSE 0 END) / COUNT(oi.order_id) * 100,

    -- Ratio of highend seller (Price-wise)
    SUM(CASE WHEN s.seller_type = 'highend_premium' THEN oi.price ELSE 0 END) / SUM(oi.price) * 100

FROM cleaned_orders o
JOIN cleaned_customers c ON o.customer_id = c.customer_id
JOIN cleaned_order_items oi ON o.order_id = oi.order_id
JOIN cleaned_sellers s ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id;





-- Basic Statistic Analysis for Setting bars of segmentation


SELECT
  MIN(total_orders) AS min_orders,
  MAX(total_orders) AS max_orders,
  ROUND(AVG(total_orders), 2) AS avg_orders,
  COUNT(*) AS total_customers
FROM customer_base_metrics;
-- Min orders: 1, Max orders: 15, Avg orders: 1.03, Total_customers:93,317

SELECT
  MIN(total_spending) AS min_spending,
  MAX(total_spending) AS max_spending,
  ROUND(AVG(total_spending), 2) AS avg_spending
FROM customer_base_metrics;
-- Min spending: 0.85, Max_spending: 13,440, Avg_spending: 141.61

SELECT
  MIN(aov) AS min_aov,
  MAX(aov) AS max_aov,
  ROUND(AVG(aov), 2) AS avg_aov
FROM customer_base_metrics;
-- Min AOV: 0.85, Max AOV: 6,735, Avg_AOV: 125.84

SELECT
  ROUND(AVG(highend_seller_ratio_order), 2) AS avg_ratio_order,
  ROUND(MIN(highend_seller_ratio_order), 2) AS min_ratio_order,
  ROUND(MAX(highend_seller_ratio_order), 2) AS max_ratio_order,
  
  ROUND(AVG(highend_seller_ratio_spending), 2) AS avg_ratio_spending,
  ROUND(MIN(highend_seller_ratio_spending), 2) AS min_ratio_spending,
  ROUND(MAX(highend_seller_ratio_spending), 2) AS max_ratio_spending
FROM customer_base_metrics;
-- Avg_ratio_order: 11.58, Min ratio order: 0, Max ratio order:100, Avg_ratio_spending: 11.65, Min ratio spending: 0, Max_ratio spending: 100 


-- Update Cleaned_customers Table with customer_type


-- Create Customer_type column
ALTER TABLE cleaned_customers
ADD COLUMN customer_type VARCHAR(20);


-- Create Index

-- cleaned_customers
CREATE INDEX idx_customer_uid ON cleaned_customers(customer_unique_id(32));
CREATE INDEX idx_customer_type ON cleaned_customers(customer_type);

-- customer_base_metrics
CREATE INDEX idx_cbm_uid ON customer_base_metrics(customer_unique_id(32));
CREATE INDEX idx_cbm_orders ON customer_base_metrics(total_orders);
CREATE INDEX idx_cbm_spending ON customer_base_metrics(total_spending);
CREATE INDEX idx_cbm_aov ON customer_base_metrics(aov);
CREATE INDEX idx_cbm_highend_order ON customer_base_metrics(highend_seller_ratio_order);
CREATE INDEX idx_cbm_highend_spend ON customer_base_metrics(highend_seller_ratio_spending);

-- FINIALLY UPDATE customer_type 

-- 1. highend_premium
UPDATE cleaned_customers c
JOIN customer_base_metrics cbm ON c.customer_unique_id = cbm.customer_unique_id
SET c.customer_type = 'highend_premium'
WHERE cbm.total_orders >= 2
  AND cbm.total_spending >= 1000
  AND cbm.aov >= 251.68
  AND (cbm.highend_seller_ratio_order >= 70 OR cbm.highend_seller_ratio_spending >= 70);

-- 2. volume_premium
UPDATE cleaned_customers c
JOIN customer_base_metrics cbm ON c.customer_unique_id = cbm.customer_unique_id
SET c.customer_type = 'volume_premium'
WHERE cbm.total_orders >= 2
  AND cbm.total_spending >= 700
  AND (cbm.aov < 251.68 AND cbm.highend_seller_ratio_order < 70 AND cbm.highend_seller_ratio_spending < 70)
  AND c.customer_type IS NULL;

-- 3. heavy_regular
UPDATE cleaned_customers c
JOIN customer_base_metrics cbm ON c.customer_unique_id = cbm.customer_unique_id
SET c.customer_type = 'heavy_regular'
WHERE (cbm.total_orders >= 5 OR cbm.total_spending >= 500)
  AND cbm.highend_seller_ratio_order < 30
  AND c.customer_type IS NULL;

-- 4. one_time_highend
UPDATE cleaned_customers c
JOIN customer_base_metrics cbm ON c.customer_unique_id = cbm.customer_unique_id
SET c.customer_type = 'one_time_highend'
WHERE cbm.total_orders = 1
  AND cbm.total_spending >= 1000
  AND cbm.aov >= 251.68
  AND (cbm.highend_seller_ratio_order >= 70 OR cbm.highend_seller_ratio_spending >= 70)
  AND c.customer_type IS NULL;

-- 5. regular
UPDATE cleaned_customers
SET customer_type = 'regular'
WHERE customer_type IS NULL;


-- Based on the current segmentation, all customer types except "regular" account for only 2.4% of total users, but they contribute 18.91% of the total revenue.
-- We need to analyze who these valuable users are.

-- 97% of customers make only one purchase and then leave. This means that out of every 100 new users, 97 churn and only 3 remain with potential for repurchase.
-- Acquiring new customers is expensive.
-- Retaining existing customers is much more cost-effective and powerful.
-- While most regular users leave after a single purchase, premium and heavy users tend to make continuous contributions to revenue.



------------------------------------
-- KPI
------------------------------------


-- 1. Total Customers

SELECT customer_type, COUNT(DISTINCT customer_unique_id) AS customer_count
FROM cleaned_customers
GROUP BY customer_type;

-- 96,054 in total

SELECT
  customer_type,
  COUNT(*) AS customer_count,
  ROUND(SUM(cbm.total_spending), 2) AS total_spending,
  ROUND(AVG(cbm.total_spending), 2) AS avg_spending_per_customer
FROM cleaned_customers c
JOIN customer_base_metrics cbm ON c.customer_unique_id = cbm.customer_unique_id
GROUP BY customer_type
ORDER BY total_spending DESC;


-- 2. AOV by customer_type

SELECT
  ROUND(SUM(oi.price) / COUNT(DISTINCT c.customer_unique_id), 2) AS overall_aov
FROM cleaned_orders o
JOIN cleaned_order_items oi ON o.order_id = oi.order_id
JOIN cleaned_customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';

-- AOV: 141.61 -> 한명당 평균 주문액이 137.04

SELECT
  c.customer_type,
  ROUND(SUM(oi.price) / COUNT(DISTINCT c.customer_unique_id), 2) AS avg_aov
FROM cleaned_orders o
JOIN cleaned_order_items oi ON o.order_id = oi.order_id
JOIN cleaned_customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_type
ORDER BY avg_aov DESC;

-- Highend_premium: 1,868.53
-- Volume_premium: 987.81
-- One_time_highend: 1,597.22
-- Heavy_regular: 923.26
-- Regular: 115.31 


-- 3. Avg Number of Categories

SELECT
  ROUND(AVG(category_count), 2) AS avg_categories_per_customer
FROM (
  SELECT
    c.customer_unique_id,
    COUNT(DISTINCT p.product_category_eng) AS category_count
  FROM cleaned_orders o
  JOIN cleaned_customers c ON o.customer_id = c.customer_id
  JOIN cleaned_order_items oi ON o.order_id = oi.order_id
  JOIN cleaned_products p ON oi.product_id = p.product_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id
) AS category_per_customer;

-- 1.03 


SELECT
  customer_type,
  ROUND(AVG(category_count), 2) AS avg_categories_per_customer
FROM (
  SELECT
    c.customer_unique_id,
    c.customer_type,
    COUNT(DISTINCT p.product_category_eng) AS category_count
  FROM cleaned_orders o
  JOIN cleaned_customers c ON o.customer_id = c.customer_id
  JOIN cleaned_order_items oi ON o.order_id = oi.order_id
  JOIN cleaned_products p ON oi.product_id = p.product_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id, c.customer_type
) AS categorized_customers
GROUP BY customer_type
ORDER BY avg_categories_per_customer DESC;

-- mostly around 1. volume_premium -> 2.06
-- USELESS INSIGHT -> GOING INTO A TRASH BIN


-- 4. Trend of Number of Customers (Who paid)

SELECT
  DATE_FORMAT(o.order_approved_at, '%Y-%m') AS order_month,
  COUNT(DISTINCT c.customer_unique_id) AS active_customers
FROM cleaned_orders o
JOIN cleaned_customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_approved_at IS NOT NULL
GROUP BY order_month
ORDER BY order_month;
-- 2016: Very low
-- After 2016, it starts growing and it's natural since there are few data in 2016. 


-- 5. Customer Distribution by Region

SELECT
  c.customer_state,
  COUNT(DISTINCT c.customer_unique_id) AS customer_count
FROM cleaned_customers c
GROUP BY c.customer_state
ORDER BY customer_count DESC;
-- 대부분 SP
-- SP, RJ, MG, RS, PR, SC, BA, DF, ES, GO

SELECT
  c.customer_state,
  c.customer_type,
  COUNT(DISTINCT c.customer_unique_id) AS customer_count
FROM cleaned_customers c
GROUP BY c.customer_state, c.customer_type
ORDER BY customer_state, customer_type;


-- 6. Category Preference by Segment

SELECT
  c.customer_type,
  p.product_category_eng,
  COUNT(*) AS purchase_count
FROM cleaned_orders o
JOIN cleaned_order_items oi ON o.order_id = oi.order_id
JOIN cleaned_products p ON oi.product_id = p.product_id
JOIN cleaned_customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_type, p.product_category_eng
ORDER BY c.customer_type, purchase_count DESC;


-- 7. Payment Preference

SELECT
  payment_type,
  COUNT(*) AS payment_count
FROM cleaned_order_payments
GROUP BY payment_type
ORDER BY payment_count DESC;

SELECT
  payment_type,
  COUNT(DISTINCT c.customer_unique_id) AS customer_count
FROM cleaned_order_payments p
JOIN cleaned_orders o ON p.order_id = o.order_id
JOIN cleaned_customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY payment_type
ORDER BY customer_count DESC;



SELECT
  c.customer_type,
  p.payment_type,
  COUNT(*) AS payment_count
FROM cleaned_order_payments p
JOIN cleaned_orders o ON p.order_id = o.order_id
JOIN cleaned_customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_type, p.payment_type
ORDER BY c.customer_type, payment_count DESC;




-- 8. Repurchase Rate

SELECT
  COUNT(CASE WHEN total_orders >= 2 THEN 1 END) AS repeat_customers,
  COUNT(*) AS total_customers,
  ROUND(COUNT(CASE WHEN total_orders >= 2 THEN 1 END) / COUNT(*) * 100, 2) AS repurchase_rate_percent
FROM customer_base_metrics;
-- 3%

SELECT
  c.customer_type,
  COUNT(DISTINCT c.customer_unique_id) AS total_customers,
  COUNT(DISTINCT CASE WHEN cbm.total_orders >= 2 THEN c.customer_unique_id END) AS repeat_customers,
  ROUND(
    COUNT(DISTINCT CASE WHEN cbm.total_orders >= 2 THEN c.customer_unique_id END) 
    / COUNT(DISTINCT c.customer_unique_id) * 100, 
    2
  ) AS repurchase_rate_percent
FROM cleaned_customers c
JOIN customer_base_metrics cbm ON c.customer_unique_id = cbm.customer_unique_id
GROUP BY c.customer_type
ORDER BY repurchase_rate_percent DESC;

-- Regular: 2.85%
-- Heavy_regular: 8.66%

-- Must increase those rates


-- 9. Repurchase Rate between Reviewed Customers and Unreviewed Customers

WITH customer_reviews AS (
  SELECT DISTINCT c.customer_unique_id
  FROM cleaned_order_reviews r
  JOIN cleaned_orders o ON r.order_id = o.order_id
  JOIN cleaned_customers c ON o.customer_id = c.customer_id
  WHERE r.review_comment_message IS NOT NULL
)

SELECT
  CASE
    WHEN cr.customer_unique_id IS NOT NULL THEN 'left_review'
    ELSE 'no_review'
  END AS review_status,
  COUNT(*) AS total_customers,
  COUNT(CASE WHEN cbm.total_orders >= 2 THEN 1 END) AS repeat_customers,
  ROUND(COUNT(CASE WHEN cbm.total_orders >= 2 THEN 1 END) / COUNT(*) * 100, 2) AS repurchase_rate_percent
FROM customer_base_metrics cbm
LEFT JOIN customer_reviews cr ON cbm.customer_unique_id = cr.customer_unique_id
GROUP BY review_status;
-- Left review's repurchase rate:3.82%
-- No review's repurchase rate: 2.43%
-- Overall figures are low, but the repurchase rate of customers who left a review is over 1.4 times higher than those who didn’t.
-- Customers who leave reviews tend to be more loyal and show a willingness to provide feedback to the marketplace.



-- 9. Ratio of reviewed people.

-- Count-wise
WITH customer_reviews AS (
  SELECT DISTINCT c.customer_unique_id
  FROM cleaned_order_reviews r
  JOIN cleaned_orders o ON r.order_id = o.order_id
  JOIN cleaned_customers c ON o.customer_id = c.customer_id
  WHERE r.review_comment_message IS NOT NULL
)

SELECT
  CASE
    WHEN cr.customer_unique_id IS NOT NULL THEN 'left_review'
    ELSE 'no_review'
  END AS review_status,
  COUNT(*) AS customer_count
FROM cleaned_customers c
LEFT JOIN customer_reviews cr ON c.customer_unique_id = cr.customer_unique_id
GROUP BY review_status;

-- Review: 41,534
-- No review: 57,861

-- Ratio

WITH customer_reviews AS (
  SELECT DISTINCT c.customer_unique_id
  FROM cleaned_order_reviews r
  JOIN cleaned_orders o ON r.order_id = o.order_id
  JOIN cleaned_customers c ON o.customer_id = c.customer_id
  WHERE r.review_comment_message IS NOT NULL
    AND o.order_status = 'delivered'  -- 여기 추가
)

SELECT
  COUNT(CASE WHEN cr.customer_unique_id IS NOT NULL THEN 1 END) AS reviewed_customers,
  COUNT(CASE WHEN cr.customer_unique_id IS NULL THEN 1 END) AS no_review_customers,
  ROUND(COUNT(CASE WHEN cr.customer_unique_id IS NOT NULL THEN 1 END) / COUNT(*) * 100, 2) AS review_ratio
FROM cleaned_customers c
LEFT JOIN customer_reviews cr ON c.customer_unique_id = cr.customer_unique_id;
-- 39.93% left reviews


-- Ratio by Segment

WITH customer_reviews AS (
  SELECT DISTINCT c.customer_unique_id
  FROM cleaned_order_reviews r
  JOIN cleaned_orders o ON r.order_id = o.order_id
  JOIN cleaned_customers c ON o.customer_id = c.customer_id
  WHERE r.review_comment_message IS NOT NULL
    AND o.order_status = 'delivered' 
)

SELECT
  c.customer_type,
  COUNT(DISTINCT c.customer_unique_id) AS total_customers,  -- Total number OF actual customers BY type
  COUNT(DISTINCT cr.customer_unique_id) AS reviewed_customers,  -- Total number of actual customers who left reviews by type
  ROUND(COUNT(DISTINCT cr.customer_unique_id) / COUNT(DISTINCT c.customer_unique_id) * 100, 2) AS review_response_rate  
FROM cleaned_customers c
LEFT JOIN customer_reviews cr ON c.customer_unique_id = cr.customer_unique_id
GROUP BY c.customer_type;




-- 10. Avg Review Score by Segment

SELECT
  c.customer_type,
  AVG(r.review_score) AS avg_review_score
FROM cleaned_order_reviews r
JOIN cleaned_orders o ON r.order_id = o.order_id
JOIN cleaned_customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_type
ORDER BY avg_review_score DESC;

-- All average scores are above 4.09, hovering around 4.1.
-- The products reviewed by customers willing to give feedback to Olist are generally of good quality.
-- Volume premium customers have the highest average score → This suggests they are more likely to repurchase compared to other segments.
-- High-end premium customers are also among the top scorers, indicating that the product quality meets the high expectations typical of this segment.
-- One-time high-end customers have a lower average (4.09) compared to others, which may suggest the need for strategies focused on long-term engagement and customer satisfaction improvement rather than just one-off purchases.




