-- 002_business_queries.sql
--
-- SQL implementation of the business questions documented in
-- docs/business_questions.md, using the formulas and scopes defined in
-- docs/analytical_metrics.md. Each query is commented line by line.
--
-- Scope covered in this file: Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12.
-- All twelve business questions from docs/business_questions.md now have a
-- SQL implementation.
--
-- Scope precision note (Q7/Q8): customer-counting metrics (purchasing_customers,
-- repeat_customers, repeat_customer_rate) use the full operational scope, so
-- they count every matched order regardless of a missing order_value. Revenue
-- metrics (order_value, top_10_sales_share) use the financial scope, applied
-- automatically because SUM() ignores NULL order_value rows. Mixing these two
-- scopes previously caused a 1-customer mismatch against the Pandas validation
-- (see docs/data_dictionary.md, "Scope precision lesson").


-- =============================================================
-- Q1. What is the overall sales performance of the business?
-- =============================================================
SELECT
    COUNT(DISTINCT order_id)                    AS distinct_orders,      -- unique orders, not rows
    SUM(quantity)                                AS units_sold,           -- total units across valid rows
    SUM(sales)                                   AS gross_sales,          -- revenue before discount
    SUM(order_value)                             AS net_order_value,      -- revenue after discount
    SUM(order_value) / COUNT(DISTINCT order_id)  AS average_order_value   -- AOV: same scope numerator/denominator
FROM orders_analytical                                                   -- enriched view (order + customer + product + financials)
WHERE order_value IS NOT NULL;                                           -- financial scope: exclude rows missing quantity/unit_price/discount


-- =============================================================
-- Q2. How did sales value, order volume, and AOV evolve over time?
-- =============================================================
SELECT
    order_year,                                                          -- calendar year extracted during cleaning
    order_month,                                                         -- calendar month number, used for ordering
    order_month_name,                                                    -- calendar month name, used for display
    COUNT(DISTINCT order_id)                    AS distinct_orders,      -- orders placed in that month
    SUM(order_value)                             AS net_order_value,      -- monthly revenue after discount
    SUM(order_value) / COUNT(DISTINCT order_id)  AS average_order_value   -- monthly AOV
FROM orders_analytical
WHERE order_value IS NOT NULL                                           -- financial scope
  AND order_date IS NOT NULL                                             -- dated sales scope: a valid date is required to group by month
GROUP BY order_year, order_month, order_month_name                       -- one row per calendar month
ORDER BY order_year, order_month;                                        -- chronological order, not alphabetical


-- =============================================================
-- Q3. Which periods contributed most to sales, and what explains it?
-- =============================================================
WITH monthly_performance AS (                                            -- CTE: one row per calendar month with all comparison metrics
    SELECT
        order_year,
        order_month,
        order_month_name,
        COUNT(DISTINCT order_id)                        AS distinct_orders,      -- orders placed in that month
        SUM(quantity)                                    AS units_sold,           -- units sold in that month
        SUM(quantity) / COUNT(DISTINCT order_id)         AS units_per_order,       -- basket size for that month
        AVG(discount)                                    AS average_discount,     -- average discount applied that month
        SUM(order_value)                                 AS net_order_value,      -- monthly revenue after discount
        SUM(order_value) / COUNT(DISTINCT order_id)      AS average_order_value   -- monthly AOV
    FROM orders_analytical
    WHERE order_value IS NOT NULL                                                 -- financial scope
      AND order_date IS NOT NULL                                                  -- dated sales scope
    GROUP BY order_year, order_month, order_month_name
),
ranked_months AS (                                                        -- CTE: rank months by revenue and compute each month's share
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY net_order_value DESC)              AS sales_rank,   -- 1 = best month; DENSE_RANK avoids gaps on ties
        net_order_value / SUM(net_order_value) OVER ()                 AS sales_share,  -- this month's revenue / total revenue
        distinct_orders::NUMERIC / SUM(distinct_orders) OVER ()        AS order_share   -- this month's orders / total orders
    FROM monthly_performance
)
SELECT *
FROM ranked_months
WHERE sales_rank <= 3                                                     -- the 3 strongest months
   OR sales_rank > (SELECT MAX(sales_rank) FROM ranked_months) - 3        -- the 3 weakest months
ORDER BY sales_rank;                                                      -- best months first, worst months last


-- =============================================================
-- Q4. Which categories generate the most sales value?
-- =============================================================
SELECT
    category,                                                            -- product category
    COUNT(DISTINCT order_id)                    AS distinct_orders,      -- orders that include this category
    SUM(quantity)                                AS units_sold,           -- units sold in this category
    SUM(order_value)                             AS category_order_value, -- category revenue after discount
    SUM(order_value) / SUM(SUM(order_value)) OVER () AS sales_share       -- window function: category value / grand total across all categories
FROM orders_analytical
WHERE order_value IS NOT NULL                                           -- financial scope
GROUP BY category
ORDER BY category_order_value DESC;                                      -- highest-value categories first


-- =============================================================
-- Q5. Which products sell the most units, and does volume translate
--     into sales value?
-- =============================================================
WITH product_value AS (                                                   -- CTE: product revenue (financial scope)
    SELECT
        product_id,
        product_name,
        category,
        SUM(order_value) AS order_value
    FROM orders_analytical
    WHERE order_value IS NOT NULL
    GROUP BY product_id, product_name, category
),
product_units AS (                                                        -- CTE: product volume (quantity scope, independent of order_value)
    SELECT
        product_id,
        SUM(quantity) AS units_sold
    FROM orders_analytical
    WHERE quantity IS NOT NULL
    GROUP BY product_id
),
ranked_products AS (                                                      -- CTE: rank each product twice, by value and by volume
    SELECT
        v.product_id,
        v.product_name,
        v.category,
        v.order_value,
        u.units_sold,
        RANK() OVER (ORDER BY v.order_value DESC) AS sales_rank,          -- 1 = highest revenue
        RANK() OVER (ORDER BY u.units_sold DESC)  AS volume_rank          -- 1 = highest unit volume
    FROM product_value v
    JOIN product_units u ON v.product_id = u.product_id                  -- inner join: every product has both a value and a volume
)
SELECT
    *,
    (volume_rank - sales_rank) AS rank_difference                        -- positive: sells more than its revenue rank suggests; negative: the opposite
FROM ranked_products
ORDER BY sales_rank;


-- =============================================================
-- Q6. How do discounts relate to sales performance?
-- =============================================================
WITH discount_bands AS (                                                  -- CTE: label every order with a discount band
    SELECT
        order_id,
        quantity,
        discount,
        order_value,
        CASE
            WHEN discount = 0    THEN '0% (no discount)'                 -- no discount applied
            WHEN discount <= 0.10 THEN '0-10%'                           -- small discount
            WHEN discount <= 0.20 THEN '10-20%'                          -- moderate discount
            ELSE '20%+'                                                  -- large discount
        END AS discount_band
    FROM orders_analytical
    WHERE order_value IS NOT NULL                                        -- financial scope
      AND discount IS NOT NULL                                           -- discount must be known to assign a band
)
SELECT
    discount_band,
    COUNT(DISTINCT order_id)                    AS distinct_orders,      -- orders in this discount band
    AVG(discount)                                AS average_discount,     -- average discount actually applied within the band
    SUM(quantity)                                AS units_sold,           -- units sold within the band
    SUM(order_value)                             AS net_order_value,      -- revenue within the band
    SUM(order_value) / COUNT(DISTINCT order_id)  AS average_order_value   -- AOV within the band
FROM discount_bands
GROUP BY discount_band
ORDER BY average_discount;                                                -- ordered from no discount to the largest discount


-- =============================================================
-- Q7. How many customers purchased, and how concentrated is the base?
-- =============================================================
WITH customer_orders AS (                                                -- CTE: aggregate orders to customer grain first
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS distinct_orders,                     -- orders placed by this customer (full operational scope: every cleaned order counts)
        SUM(order_value)         AS order_value                          -- total spend; SUM ignores NULL order_value rows, so this is financial scope automatically
    FROM orders_analytical
    WHERE EXISTS (                                                       -- keep only orders with a matching customer record
          SELECT 1 FROM customers c WHERE c.customer_id = orders_analytical.customer_id
      )                                                                  -- excludes the 30 documented unmatched orders (all sharing one invalid customer_id)
    GROUP BY customer_id
),
ranked_customers AS (                                                    -- CTE: rank customers by spend for the top-10 share
    SELECT
        *,
        RANK() OVER (ORDER BY order_value DESC) AS value_rank            -- 1 = highest-spending customer
    FROM customer_orders
)
SELECT
    COUNT(*)                                                     AS purchasing_customers,     -- distinct customers who bought (full operational scope)
    COUNT(*) FILTER (WHERE distinct_orders > 1)                  AS repeat_customers,          -- customers with more than one order
    COUNT(*) FILTER (WHERE distinct_orders > 1)::NUMERIC
        / COUNT(*)                                               AS repeat_customer_rate,      -- repeat customers / all purchasing customers
    SUM(order_value) FILTER (WHERE value_rank <= 10)
        / SUM(order_value)                                       AS top_10_sales_share         -- share of revenue from the 10 biggest customers (financial scope)
FROM ranked_customers;


-- =============================================================
-- Q8. What is the purchasing behavior of new versus repeat customers?
-- =============================================================
WITH customer_orders AS (                                                -- same customer-grain aggregation as Q7
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS distinct_orders,                     -- full operational scope
        SUM(order_value)         AS order_value                          -- financial scope, via SUM's automatic NULL-skipping
    FROM orders_analytical
    WHERE EXISTS (
          SELECT 1 FROM customers c WHERE c.customer_id = orders_analytical.customer_id
      )
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN distinct_orders > 1 THEN 'Repeat'                           -- more than one order places a customer in the repeat cohort
        ELSE 'One-time'                                                  -- exactly one order places a customer in the one-time cohort
    END                                                          AS customer_type,
    COUNT(*)                                                     AS customers,                -- customers in this cohort
    SUM(distinct_orders)                                         AS total_orders,              -- orders placed by this cohort
    SUM(order_value)                                             AS order_value,               -- revenue from this cohort
    SUM(order_value) / SUM(distinct_orders)                      AS average_order_value,        -- cohort AOV
    SUM(order_value) / SUM(SUM(order_value)) OVER ()             AS sales_share                 -- cohort share of total revenue
FROM customer_orders
GROUP BY customer_type;


-- =============================================================
-- Q9. Which customer segments and cities generate the most sales?
-- =============================================================

-- Segment performance
SELECT
    COALESCE(customer_segment, 'Unknown')       AS customer_segment,     -- keep missing segments visible instead of dropping rows
    COUNT(DISTINCT customer_id)                  AS customers,            -- customers in this segment
    COUNT(DISTINCT order_id)                     AS distinct_orders,      -- orders from this segment
    SUM(order_value)                             AS segment_order_value,  -- segment revenue after discount
    SUM(order_value) / SUM(SUM(order_value)) OVER () AS sales_share       -- segment share of total revenue
FROM orders_analytical
WHERE order_value IS NOT NULL
GROUP BY COALESCE(customer_segment, 'Unknown')
ORDER BY segment_order_value DESC;

-- Top 10 cities by order value
SELECT
    COALESCE(city, 'Unknown')                    AS city,                -- keep missing cities visible instead of dropping rows
    COUNT(DISTINCT customer_id)                  AS customers,
    COUNT(DISTINCT order_id)                     AS distinct_orders,
    SUM(order_value)                             AS city_order_value,
    SUM(order_value) / SUM(SUM(order_value)) OVER () AS sales_share
FROM orders_analytical
WHERE order_value IS NOT NULL
GROUP BY COALESCE(city, 'Unknown')
ORDER BY city_order_value DESC
LIMIT 10;                                                                 -- only the top 10 cities, matching the Pandas notebook


-- =============================================================
-- Q10. What is the order-status distribution and cancellation rate?
-- =============================================================

-- Status distribution
SELECT
    status,                                                              -- Completed, Cancelled, or Returned
    COUNT(*)                                     AS distinct_orders,     -- orders is already the order grain (one row per order)
    COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER ()    AS status_share         -- share of all orders in this status
FROM orders
GROUP BY status
ORDER BY distinct_orders DESC;

-- Cancellation rate and returned-status share
SELECT
    COUNT(*) FILTER (WHERE status = 'Cancelled')::NUMERIC
        / COUNT(*)                               AS cancellation_rate,   -- cancelled orders / all orders
    COUNT(*) FILTER (WHERE status = 'Returned')::NUMERIC
        / COUNT(*)                               AS returned_status_share -- proxy metric, not a true return rate (see docs)
FROM orders;


-- =============================================================
-- Q11. Which payment methods are most used, and how do they perform?
-- =============================================================
SELECT
    payment_method,                                                       -- payment method chosen at checkout
    COUNT(*)                                     AS distinct_orders,      -- orders using this payment method
    COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER ()    AS order_share,          -- share of all orders using this method
    COUNT(*) FILTER (WHERE status = 'Cancelled')::NUMERIC
        / COUNT(*)                               AS cancellation_rate     -- cancellation rate within this payment method
FROM orders
GROUP BY payment_method
ORDER BY distinct_orders DESC;


-- =============================================================
-- Q12. Are payment records consistent with orders?
-- =============================================================

-- Reconciliation: unmatched records in either direction
SELECT
    (SELECT COUNT(*)                                                     -- payments whose order_id has no matching order
     FROM payments p
     LEFT JOIN orders o ON p.order_id = o.order_id
     WHERE o.order_id IS NULL)                   AS unmatched_payments,
    (SELECT COUNT(*)                                                     -- orders that have no matching payment record
     FROM orders o
     LEFT JOIN payments p ON o.order_id = p.order_id
     WHERE p.order_id IS NULL)                   AS orders_without_payment;

-- Payment status distribution
SELECT
    payment_status,                                                       -- Paid, Failed, or Refunded
    COUNT(*)                                     AS payment_records,      -- payment records with this status
    COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER ()    AS status_share          -- share of all payment records
FROM payments
GROUP BY payment_status
ORDER BY payment_records DESC;
