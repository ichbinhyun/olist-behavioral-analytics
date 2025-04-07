# Behavioral Analytics Across Users on Olist E-Commerce Platform

## 📑 Table of Contents
- [Summary](#summary)
- [Problem Statement](#problem-statement)
- [Tools Used](#tools-used)
- [About Business](#about-business)
- [About Dataset](#about-dataset)
- [Audience](#audience)
- [Working Process](#working-process)
- [User Segmentation](#user-segmentation)
- [KPI Definition](#kpi-definition)
- [Findings](#findings)
- [Actionable Suggestions](#actionable-suggestions)
- [Conclusion](#conclusion)

---

## Summary
This project analyzes user behavior on the Olist e-commerce platform by segmenting both customers and sellers, calculating key performance indicators (KPIs), and uncovering actionable insights to address major business challenges. Using SQL, Python, and Power BI, the analysis identifies low repurchase rates, high seller dormancy, and category performance imbalances as core issues. Through a structured data-driven approach, the report proposes targeted CRM and marketing strategies such as review-triggered loyalty campaigns and seller reactivation programs to enhance retention, drive sales, and optimize platform efficiency.

---

## Problem Statement
This project’s problem statement focuses on **analyzing the behavioral patterns** of Olist’s **core users (customers and sellers)** and segmenting them in a meaningful way. Furthermore, it aims to identify actionable insights that support long-term platform growth by enhancing seller engagement, increasing customer retention, and optimizing product variety to meet both supply and demand effectively.

- Who are the customers and sellers?
- How are their behaviors?
- How can we increase the number of active sellers on the platform?
- How can we increase sellers' consistent activity and customer retention?
- How can we help sellers increase their sales performance?
- How can we ensure product variety that benefits both sellers and customers, without pushing products that don’t sell?

---

## Tools Used
- **MySQL** – Main tool for data wrangling, exploratory analysis, and KPI calculation  
- **Python (Pandas, Matplotlib, Seaborn)** – Used for initial data understanding and visual exploration (e.g., missing values, distribution plots, correlation heatmap)  
- **Power BI** – Used for interactive dashboard development and presenting key insights

---

## About Business
Olist is a Brazilian e-commerce platform that connects small and medium-sized sellers to major online marketplaces, such as Mercado Livre, B2W, and others. By offering a unified storefront and operational support, including logistics, payments, and customer service, Olist lowers the entry barrier for local merchants and helps them scale efficiently. Rather than selling products directly, Olist operates as a marketplace enabler, earning revenue through commissions, seller subscription fees, and service fees on each transaction. Its business model thrives on the success of its sellers, making platform growth and seller performance critical to its profitability. This dual-sided ecosystem, which contains buyers and sellers, forms the foundation of Olist’s value proposition in the competitive e-commerce landscape.

---

## About Dataset
This **real-world dataset**, collected from a large-scale e-commerce platform between 2016 and 2018, contains over 100,000 orders and provides rich insights into consumer behavior, seller performance, and operational dynamics. It serves as a strong foundation for behavioral analytics, user segmentation, and performance benchmarking on a dual-sided marketplace.

👉 [Original dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

Unused tables such as geolocation were excluded for clarity. The product_category_name_translation table was not used as a separate entity, but its data was fully merged into the products table to include English category names.
Additionally, the order_reviews table was cleaned to remove duplicated or incomplete entries, and its primary key was redefined from a composite of review_id and order_id to a single unique key: review_id.


![ERD](./assets/ERD.png)

---

## Audience
This analysis is primarily intended for the **Marketing and Customer Relationship Management (CRM) teams** at Olist.

By uncovering behavioral patterns across customers and sellers, the project offers actionable insights that can support strategic decision-making in areas such as:

- Targeted marketing campaigns
- Customer segmentation and retention strategies
- Seller engagement and activity management
- Product category optimization

---

## Working Process
This project followed a structured approach to explore, clean, and analyze the Brazilian e-commerce dataset from Olist. The overall process was divided into four major phases:

**1. Data Understanding**
I began by examining the nine tables provided, analyzing their relationships and business context. An Entity-Relationship Diagram (ERD) was created to visualize key connections among orders, customers, sellers, products, and payments. This helped clarify how each user group (customers and sellers) interacts with the platform and with each other.

**2. Exploratory Data Analysis (EDA)**
Using Python (Pandas, Matplotlib, Seaborn) and MySQL, I conducted an **in-depth analysis of trends** such as sales distribution over time, popular product categories, and payment behavior. EDA also helped in identifying patterns and potential segmentation opportunities across both sellers and customers.

**3. Data Wrangling**
To ensure data reliability and consistency, I performed various cleaning steps such as **handling missing values, removing time-sequence anomalies and records violating business logic, merging related tables, and standardizing product categories**. This stage was critical to prepare the data for accurate KPI calculations and further analysis.


👉 [View notebooks here](https://github.com/ichbinhyun/olist-behavioral-analytics/tree/main)

Each of these steps laid the foundation for defining KPIs, deriving behavioral insights, and formulating actionable recommendations for both customer engagement and seller performance enhancement.

---

## User Segmentation
### 1. Customer Segmentation
Customers were segmented into five distinct groups using rule-based thresholds derived from the data. The segmentation criteria considered **order frequency, total spending, average order value (AOV), and purchasing concentration toward high-performing sellers**. These indicators were selected to reflect purchasing power, loyalty, and product affinity.


| Segment Name         | Criteria                                                                                       | Reasoning                                                                                                           |
|----------------------|------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| **High-End Premium**     | ≥ 2 purchases, ≥ $1000 total spend, AOV ≥ $251.68, ≥ 70% from purchases from premium sellers   | Represents loyal and high-spending customers who prefer premium-quality products and consistently shop from top-tier sellers. |
| **Volume Premium**       | ≥ 2 purchases, ≥ $700 total spend, lower AOV or < 70% from premium seller purchases            | Frequent buyers with considerable spending, but less focus on premium sellers or high-end items.                   |
| **Heavy Regular**        | ≥ 5 purchases or ≥ $500 spend, < 30% from premium seller purchases                             | Highly active customers, but mainly engaged with general or budget sellers — possibly deal-seekers.               |
| **One-Time High-End**    | 1 purchase, ≥ $1000 spend, AOV ≥ $251.68, ≥ 70% premium seller purchases                       | First-time buyers with high-value transactions; potential for conversion into loyal high-end customers.           |
| **Regular**              | Everyone else not matching the above segments                                                  | General customer base with varied but less consistent or high-value behavior.                                      |

The thresholds (e.g., AOV = $251.68) were based on statistical benchmarks such as the average AOV (×2), total spend percentiles, and purchase distribution across premium vs. general sellers


### 2. Seller Segmentation
Sellers were categorized into three groups based on their total sales performance and average order value. **The top 5% of sellers by total sales** were first identified, then further **divided by their average order value** to distinguish between **high-end and volume-based business strategies**.


| Segment Name       | Criteria                                                                 | Reasoning                                                                                                         |
|--------------------|--------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| **High-End Premium**   | Among top 5% sellers by total sales; upper half by average order value   | Sellers who generate large revenue through high-ticket items, often targeting niche, premium markets.            |
| **Volume Premium**     | Among top 5% sellers by total sales; lower half by average order value   | Sellers who rely on high volume and lower-priced products to drive performance.                                  |
| **Regular**            | All other sellers not in the top 5%                                      | Standard performance group, including newer sellers, niche product sellers, or less active ones.                  |

This seller segmentation helps uncover how different seller types contribute to platform revenue and allows the company to tailor support, promotions, or recommendations accordingly.


---


## KPI Definition
To evaluate user behavior and platform performance, I established a set of Key Performance Indicators (KPIs) aligned with the problem statements. These KPIs are categorized into three areas: **Sales, Sellers, and Customers.**
Each metric was designed to offer actionable insights for platform growth, user engagement, and business optimization.

### Sales KPIs
| KPI Name                         | Description                                                                 |
|----------------------------------|-----------------------------------------------------------------------------|
| **Average Order Value (AOV)**        | Measures the average amount spent per order, indicating revenue efficiency.|
| **Order Fulfillment Rate**           | Share of delivered orders among all orders, measuring operational reliability.|
| **Number of Sold Products**          | Total number of product units sold across the platform.                    |
| **Total Sales by Year & Region**     | Revenue distribution over time and across geographies.                     |
| **Growth Rate of Product Categories**| Changes between the latest 3 months and the previous 3 months in sales volume by category. |
| **Sales Trend per Category**         | Time-series performance of each product category.                          |
| **Annual Sales Trend**               | Macro-level sales trend over years                 |


### Seller KPIs
| KPI Name                          | Description                                                                 |
|-----------------------------------|-----------------------------------------------------------------------------|
| **Total Number of Sellers**           | Platform-wide seller count.                                                |
| **Average Order Value (Seller-Level)**| Average sales per order by seller.                                       |
| **Product Category Breadth**          | Number of orders by the most ordered product categories.                   |
| **Seller Distribution by Region**     | Geographic breakdown of sellers.                                    |
| **Top Product Category per Seller**   | Most sold product category per seller.                                     |
| **Dormant Seller Rate**               | Proportion of sellers who haven’t made sales in the recent months.        |
| **Consistent Selling Rate**           | Share of sellers with monthly activity in at least 9 of the past 12 months.|


### Customer KPIs
| KPI Name                                 | Description                                                                  |
|------------------------------------------|------------------------------------------------------------------------------|
| **Total Number of Customers**                | Count of unique customers across the platform.                              |
| **Average Order Value (Customer-Level)**     | Average spend per order per customer.                                       |
| **Repurchase Rate**                          | Share of customers who placed more than one order.                          |
| **Active Customers Over Time**               | Trend of customers making purchases each year.                              |
| **Category Preference**                      | Top product categories by customer segment.                                 |
| **Customer Distribution by Region**          | Geographic breakdown of customer.                                      |
| **Payment Preference**                       | Most used payment methods.                                 |
| **Repurchase Rate by Review Behavior**       | Correlation between review scores and repeat purchase likelihood.           |



---

## Findings
![Sales Dashboard](./assets/sales_dashboard.PNG)  
![Seller Dashboard](./assets/seller_dashboard.PNG)  
![Customer Dashboard](./assets/customer_dashboard.PNG)

> Due to a publishing restriction, the interactive version is not available.  
> However, you can explore the entire dashboard below:

📄 [Download Report (PDF)](./Behavioral_Analytics_Olist_Dashboards.pdf)
  

## 📊 Findings

## 📦 Sales Performance: How do we increase sales and ensure product variety?

- Between **Sep 2016 and Aug 2018**, Olist recorded a total of **R$15,414,349** in sales across **110,125 product units**.
- The platform achieved a solid **Average Order Value (AOV)** of **R$159.85** and an excellent **Order Fulfillment Rate** of **97.02%**.
- ⚠️ The number of orders in **2016** was significantly lower (**280 orders**) compared to **45,683 in 2017** and **54,739 in 2018**, suggesting possible ETL issues or data limitations.
- Sales steadily increased and remained above **R$820K/month** throughout 2018.
- The most significant sales spike occurred in **November 2017**, reaching nearly **R$980K**, likely driven by **Black Friday campaigns**.
- Sales were geographically concentrated:
  - **SP, RJ, and MG** combined generated **R$9.63M** in sales — approximately **62.5%** of the total.
  - **São Paulo city** alone contributed **R$2.1M**, followed by **Rio de Janeiro** with **R$1.1M**, showing a high sales concentration in SP.
- Out of **74 product categories**, the top-selling ones were:
  - **Bed Bath Table**
  - **Computer Accessories**
  - **Health & Beauty**
  - **Sports & Leisure**
  - **Watches for Gifts**
- Among them, **Health & Beauty** showed the most consistent upward trend, peaking at **R$119,391 in Aug 2018**.
- When comparing **Q3 2018 (Jun–Aug)** to **Q2 (Mar–May)**:
  - The **highest growth rate** was observed in **Arts & Craftsmanship** with over **1,371%** growth, albeit from a small base.
  - Other fast-growing categories included **Party Supplies, Construction Tools, Garden Tools, and Food**. These segments still represent a small portion of overall revenue but signal **early-stage consumer interest**.
  - **Telephony** stood out as the only category that combined **both high growth (8.9%) and strong volume (R$63K in Q3)**, making it a compelling area for further expansion.
  - Additional solid performers included **Lights for Construction, Living Room Furniture, Agro Industry & Commerce**, and **Fixed Telephony**.


---

## 🧾 Seller Overview: Seller Performance: Who drives sales, and how can we support consistent growth?

- A total of **3,095 sellers** were active on the platform:
  - **78 Highend Premium**
  - **77 Volume Premium**
  - **2,940 Regular sellers**
  
- The overall **Average Order Value (AOV)** across all sellers was **R$137.04**. When broken down by seller type:
  - **Highend Premium**: R$327.64
  - **Volume Premium**: R$102.12
  - **Regular**: R$117.41  
  → This suggests Highend Premium sellers focus on fewer but higher-priced items, while Volume Premium sellers sell low-cost items at scale. If Highend Premium sellers can increase their volume, they hold strong potential to contribute more significantly to overall revenue.

- Highend Premium sellers operated in **53 categories**, Volume Premium in **57**, and Regular sellers across **72 categories**.
  → Although Regular sellers cover the widest range, Premium sellers showed more strategic diversity. With high-quality products, they may unlock greater revenue growth across select categories.

- The **top-performing seller type** in terms of monthly revenue was Volume Premium, which peaked at **R$294,317 in November 2017**, aligning with the platform-wide Black Friday sales spike.

- Each seller type showed distinct category preferences based on total order count:
  - **Highend Premium**: Watches for Gifts, Office Furniture, Health & Beauty, Computer Accessories, Cool Stuff  
  - **Volume Premium**: Bed Bath Table, Furniture Decor, Computer Accessories, Garden Tools  
  - **Regular**: Sports & Leisure, Housewares, Health & Beauty, Furniture Decor, Bed Bath Table  
  → These differences highlight the varying customer bases per seller type. Cross-type categories like **Health & Beauty** and **Computer Accessories** show strong universal demand and are ideal candidates for focused promotion or quality enhancement strategies.

- Geographically, sellers were highly concentrated in **São Paulo (SP)**, which had **over 1,700 sellers**, followed by **Paraná (PR)** and **Minas Gerais (MG)**. At the city level, **São Paulo city alone** had more than **700 active sellers**, indicating strong supply-side centralization.

- The **dormancy rate** (inactive sellers) varied significantly:
  - **Highend Premium**: 7.69%
  - **Volume Premium**: 3.90%
  - **Regular**: 32.59%  
  → While Premium sellers show relatively stable activity, nearly **1 in 3 Regular sellers** are inactive, revealing a need for targeted reactivation programs. Reducing even a portion of this dormancy could significantly stabilize the platform's sales base.

- In terms of **consistency (ongoing sales activity)**:
  - **Volume Premium**: 98.70% (highest)
  - **Highend Premium**: 86.84%
  - **Regular**: only 27.37%  
  → Increasing the consistency of Regular sellers and strategically developing high-potential ones into **Volume Premium** status could offer strong long-term returns and reduce volatility.



---

## 👥 3. Customer Overview: Who are the customers, and how can we improve retention?

- A total of **99,395 unique customers** placed at least one order on the platform.

- Customers were segmented into five types based on order value and frequency:

| Customer Type       | Count   |
|---------------------|---------|
| Highend Premium     | 41      |
| Volume Premium      | 112     |
| One-time Highend    | 487     |
| Heavy Regular       | 1,907   |
| Regular             | 96,848  |

- The **overall Average Order Value (AOV)** per customer was **R$141.61**, but this varied widely by type:

| Customer Type       | AOV (R$)  |
|---------------------|-----------|
| Highend Premium     | 1,868.53  |
| Volume Premium      | 978.81    |
| One-time Highend    | 1,597.22  |
| Heavy Regular       | 923.26    |
| Regular             | 118.85    |

→ The majority of customers (Regular) tend to purchase lower-priced items. In contrast, **Highend Premium** and **One-time Highend** customers show strong preferences for high-value products.  
**Volume Premium** customers buy lower-priced items compared to Highend buyers but do so more frequently, contributing significantly to long-term revenue.  
The **R$800+ gap** between Regular and Heavy Regular customers suggests an opportunity to **elevate Regular customers** through targeted AOV-boosting strategies — ultimately guiding them toward Premium tiers.

- The **repurchase rate** across all customers is just **3.00%**, highlighting a critical retention challenge.  
Even among **Heavy Regulars**, the repurchase rate is **only 8.66%**, suggesting that most users treat Olist as a one-time shopping destination.  
Improving this metric requires positioning Olist as a **reliable and diverse platform** — not just for single purchases but for long-term shopping.

- **Monthly active customers** showed a steady upward trend, despite seasonal fluctuations.  
A major spike occurred in **November 2017** due to Black Friday, followed by a dip in December. However, activity recovered to similar levels in January 2018 and continued growing.

- **Regional customer distribution**:
  - **São Paulo (SP)**: 41,719  
  - **Rio de Janeiro (RJ)**: 12,849  
  - **Minas Gerais (MG)**: 11,627  
  → These three states account for **approximately 66.6%** of all customers.
  
  At the city level:
  - **São Paulo city** had **227 customers**, followed by **Rio de Janeiro** with **158**.

- **Preferred payment methods** across all customer types:
  - **Credit Card**: 78.34%
  - Followed by **Boleto**, **Voucher**, and **Debit Card**  
  → Payment preferences were consistent regardless of customer segment.

- Customers who left a review had a **repurchase rate of 3.82%**, compared to **2.43%** for those who didn’t — a **~1.5% gap**.  
This suggests that fostering positive reviews (e.g., through better seller experience and support) could **encourage more loyalty** via a virtuous feedback loop.



---

## Actionable Suggestions
### 1. **Boost Repurchase via Review-Based Loyalty Campaigns**
**Why it’s #1**: Directly solves **low retention (3%)** and is super low-cost to implement via CRM.

- Customers who **left a review were 57% more likely to return**
- Run a **“Review & Save”** email campaign: a small voucher or discount for those who leave feedback
- Automate this in CRM flows post-delivery

👉 **Impact**: Increases both **retention** and **review volume** without increasing **CAC**



### 2. **Reactivate Dormant Sellers with Incentivized Re-entry**
**Why it’s #2**: **1/3 of regular sellers are dormant**. They're already onboarded = cheap win.

- **32.59% dormancy rate** among regular sellers
- Launch a reactivation program:
  - **30-day zero commission**
  - Dashboard badge (e.g., “Returning Seller”)
  - Email nudges via seller CRM

👉 **Impact**: Converts silent sellers into **active inventory** without **new seller acquisition cost**



### 3. **Leverage Seasonal Trends like Black Friday with Targeted Category Promotions**
**Why it’s #3**: The highest platform sales ever (**R$1M+**) came from **November 2017** = proven ROI.

- Focus **Q4 campaigns** on top-converting categories (e.g., **Health & Beauty**, **Watches & Gifts**)
- Build **seasonal landing pages**, **bundles**, or **curated picks** with seller co-promotion

👉 **Impact**: Drives **predictable sales spikes** with minimal trial-and-error


---

## Conclusion
This project applied behavioral analytics to a real-world e-commerce dataset to uncover key insights around customer retention, seller performance, and sales dynamics. By aligning data-driven segmentation and KPIs with targeted business actions, the analysis provides a practical roadmap for improving engagement and growth on a dual-sided marketplace like Olist.
