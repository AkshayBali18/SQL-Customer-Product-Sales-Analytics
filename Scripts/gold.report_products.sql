/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================
create view gold.report_products  as 
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
with basic_query as(
select f.order_number,
f.order_date,
f.customer_key,
f.sales,
f.quantity,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost
from gold.fact_sales f
left join gold.dim_products p
on p.product_key=f.product_key
where order_date is not null
),

product_aggregation as(
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/

select product_key,
product_name,
category,
subcategory,
cost,
datediff(month,min(order_date),max(order_date)) as lifespan,
max(distinct order_date) as last_order_date,
count(order_number) total_orders,
sum(sales) total_sales,
sum(quantity) total_quantity,
count(distinct customer_key) total_customer,
round(avg(cast(sales as float)/nullif(quantity,0)),1) avg_sales_cost
from basic_query
group by product_key,
product_name,
category,
subcategory,
cost
)
/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/
select product_key,
product_name,
category,
subcategory,
cost,
lifespan,
datediff(month,last_order_date,getdate()) recency,
last_order_date,
case
when total_sales>50000 then'High Performance'
when total_sales>=10000 then'mid-range'
else 'Low Performance'
end sales_segment,
 total_orders,
 total_sales,
 total_quantity,
 total_customer,
 avg_sales_cost,
 -- Average Order Revenue (AOR)
 case
 when total_orders =0 then 0
 else total_sales/total_orders
 end avg_order_sales,
 
	-- Average Monthly Revenue
 case
 when lifespan =0 then total_sales
 else total_sales/lifespan
 end avg_month_sales
from product_aggregation
