/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================
 create view gold.report_customers as

 /*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
---------------------------------------------------------------------------*/
with base_query as(
select   f.order_number,
f.product_key,
f.order_date,
f.sales,
f.quantity,
c.customer_key,
c.customer_number,
concat(c.first_name,'-',c.last_name) customer_name,
DATEDIFF(year,2018-01-01,birth_date) age
from gold.fact_sales f
left join gold.dim_customer c
on c.customer_key=f.customer_key
where order_number is not null and  c.customer_id is not null
),
customer_aggregation as(
/*---------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------*/
select
customer_key,
customer_number,
customer_name,
age,
count(distinct order_number) total_order,
sum(sales) total_sales,
sum(quantity)total_quantity,
count(distinct product_key) total_product,
max(order_date) last_order_date,
datediff(month,min(order_date),max(order_date)) lifespan
from base_query
group by customer_key,
customer_number,
customer_name,
age
)
select distinct
 customer_number,
customer_name,
age,
case 
when age<20 then'below 20' 
when age<=20 or age<30  then'20-29'
when age<=30 or age<40  then'30-39'
when age<=40 or age<50  then'40-49'
else 'above 50'
end age_group,
 total_order,
 total_sales,
 total_product,
 last_order_date,
lifespan,
case
when lifespan >=12 and total_sales >=5000 then 'VIP'
when lifespan >=12 and total_sales <5000 then 'Regular'
else 'New'
end customer_segment,
datediff(month,last_order_date,getdate()) recency,
-- Compuate average order value (AVO)
case
when total_order =0 then total_sales
else 
total_sales/total_order 
end as avg_order_value,
-- Compuate average monthly spend
case
when lifespan=0 then total_sales
else total_sales/lifespan
end as avg_monthly_spend
from customer_aggregation
