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
**MySQL** – Main tool for data wrangling, exploratory analysis, and KPI calculation  
**Python (Pandas, Matplotlib, Seaborn)** – Used for initial data understanding and visual exploration (e.g., missing values, distribution plots, correlation heatmap)  
**Power BI** – Used for interactive dashboard development and presenting key insights

---

## About Business
Olist is a Brazilian e-commerce platform that connects small and medium-sized sellers to major online marketplaces, such as Mercado Livre, B2W, and others. By offering a unified storefront and operational support, including logistics, payments, and customer service, Olist lowers the entry barrier for local merchants and helps them scale efficiently. Rather than selling products directly, Olist operates as a marketplace enabler, earning revenue through commissions, seller subscription fees, and service fees on each transaction. Its business model thrives on the success of its sellers, making platform growth and seller performance critical to its profitability. This dual-sided ecosystem, which contains buyers and sellers, forms the foundation of Olist’s value proposition in the competitive e-commerce landscape.

---

## About Dataset
This **real-world dataset**, collected from a large-scale e-commerce platform between 2016 and 2018, contains over 100,000 orders and provides rich insights into consumer behavior, seller performance, and operational dynamics. It serves as a strong foundation for behavioral analytics, user segmentation, and performance benchmarking on a dual-sided marketplace.

👉 [Original dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

Below is the Entity Relationship Diagram (ERD) of the cleaned dataset used in this project. Unused tables like geolocation were excluded, and category translations were merged into the products table.

![ERD](./assets/erd.png)

---

## Audience
This analysis is primarily intended for the Marketing and Customer Relationship Management (CRM) teams at Olist.

By uncovering behavioral patterns across customers and sellers, the project offers actionable insights that can support strategic decision-making in areas such as:

- Targeted marketing campaigns
- Customer segmentation and retention strategies
- Seller engagement and activity management
- Product category optimization

---

## Working Process
This project followed a structured approach:

1. **Data Understanding**: Relationship analysis, ERD creation
2. **Exploratory Data Analysis**: Behavioral trend tracking (SQL, Python)
3. **Data Wrangling**: Anomaly removal, value standardization
4. **Insight Generation**: KPI design, segmentation, and dashboards

👉 [View notebooks here](https://github.com/ichbinhyun/olist-behavioral-analytics/tree/main)

---

## User Segmentation
### Customer Segments
| Segment              | Criteria Summary                                                                                 |
|----------------------|--------------------------------------------------------------------------------------------------|
| High-End Premium     | ≥2 purchases, ≥$1000 total spend, AOV ≥ $251.68, ≥70% from premium sellers                       |
| Volume Premium       | ≥2 purchases, ≥$700 total spend, less AOV or <70% premium sellers                                 |
| Heavy Regular        | ≥5 purchases or ≥$500 spend, <30% premium seller concentration                                    |
| One-Time High-End    | 1 purchase, ≥$1000 spend, AOV ≥ $251.68, ≥70% premium sellers                                     |
| Regular              | All others                                                                                       |

### Seller Segments
| Segment           | Criteria Summary                                                               |
|-------------------|----------------------------------------------------------------------------------|
| High-End Premium  | Top 5% by total sales and upper half by AOV                                     |
| Volume Premium    | Top 5% by total sales and lower half by AOV                                     |
| Regular Sellers   | All other sellers                                                               |

---

## KPI Definition
| Category     | KPI Description                                           |
|--------------|-----------------------------------------------------------|
| Sales        | AOV, Order Fulfillment Rate, Regional Trends, Category Growth |
| Sellers      | Consistency Rate, Dormancy Rate, Top Categories per Seller   |
| Customers    | Repurchase Rate, Review Repurchase Gap, Payment Behavior     |
| Operational  | Total Products Sold, Review Response Time                    |

---

## Findings
![Sales Dashboard](./assets/sales_dashboard.png)  
![Seller Dashboard](./assets/seller_dashboard.png)  
![Customer Dashboard](./assets/customer_dashboard.png)

👉 [View interactive dashboards here](https://app.powerbi.com/)  *(replace with your public Power BI link)*

(Include your full findings here, as written in your report.)

---

## Actionable Suggestions
1. **Boost Repurchase via Review-Based Loyalty Campaigns**
   - CRM campaign for reviewers → 57% higher retention rate
   - Small incentive = high return with low CAC

2. **Reactivate Dormant Sellers with Incentives**
   - Target 32.59% dormant sellers
   - 0% commission for 30 days + dashboard badge + email flow

3. **Seasonal Campaigns on Top Categories**
   - Black Friday = R$1M+ month
   - Repeat strategy with curated Q4 category bundles

---

## Conclusion
This project applied behavioral analytics to a real-world e-commerce dataset to uncover key insights around customer retention, seller performance, and sales dynamics. By aligning data-driven segmentation and KPIs with targeted business actions, the analysis provides a practical roadmap for improving engagement and growth on a dual-sided marketplace like Olist.

