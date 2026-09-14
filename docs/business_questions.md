# Business Questions

## Purpose

This document defines the questions that will guide the exploratory analysis, SQL analysis, and Power BI dashboard. Each question must lead to a measurable result and a potential business decision.

The questions are intentionally limited to the information available in the dataset. New questions may be added when a clear business need or a reliable data source justifies them.

## Analytical Conventions

- The current processed transaction dataset has one row per cleaned order. If future source data contains multiple products per order, order-level metrics must use distinct `OrderID` values and an explicit order-level aggregation.
- Order-level metrics must use distinct `OrderID` values. Product and quantity metrics may use order-line rows.
- `OrderValue` and `Sales` are transaction-level monetary fields created during data transformation. Their exact definitions must remain consistent with the data dictionary.
- Unless stated otherwise, sales analyses use records with a valid `OrderDate` and report the period covered by the dataset.
- Financial results represent sales value, not profit. The dataset does not contain cost, shipping, tax, or margin fields.
- The dataset does not contain a return event or return date. A return rate must not be calculated from the current data.

## Question Framework

Each question follows this path:

`Business question -> metric -> source fields -> Pandas analysis -> SQL query -> Power BI view -> insight or recommendation`

## Priority 1: Sales Performance

### Q1. What is the overall sales performance of the business?

- **Purpose:** Establish the baseline used to evaluate every other result.
- **Metrics:** Distinct orders, total units sold, total sales value, and average order value (AOV).
- **Data:** `orders_analytical.csv`; `OrderID`, `Quantity`, `Sales`, `OrderValue`, `OrderDate`, `Status`.
- **Pandas:** Build a validated KPI summary using distinct orders and an explicitly documented order-status scope.
- **SQL:** Create an aggregate query with `COUNT(DISTINCT OrderID)`, `SUM(Quantity)`, `SUM(Sales or OrderValue)`, and AOV.
- **Power BI:** KPI cards with a date filter and status filter.
- **Expected decision:** Define the baseline for performance comparisons and validate that the financial metric is not double-counted.

### Q2. How did sales value, order volume, and AOV evolve over time?

- **Purpose:** Identify growth, decline, seasonality, and periods that require investigation.
- **Metrics:** Monthly sales value, distinct monthly orders, monthly units sold, and monthly AOV.
- **Data:** `orders_analytical.csv`; `OrderDate`, `OrderYear`, `OrderMonth`, `Sales`, `OrderValue`, `Quantity`.
- **Pandas:** Aggregate by month, preserve chronological order, and compare period-over-period changes.
- **SQL:** Use date truncation and window functions for monthly totals and growth rates.
- **Power BI:** Line chart for sales and orders, with a secondary view for AOV.
- **Expected decision:** Identify strong and weak periods and formulate hypotheses for later validation.

### Q3. Which periods contributed most to sales, and what explains the difference?

- **Purpose:** Move from a ranking of periods to an explanation based on volume, units, price, and discount.
- **Metrics:** Sales share, order share, units per order, average discount, and AOV by month or year.
- **Data:** `orders_analytical.csv`; `OrderDate`, `Quantity`, `Discount`, `UnitPrice`, `Sales`, `OrderValue`.
- **Pandas:** Compare the top and bottom periods using a common metric table.
- **SQL:** Rank periods with `DENSE_RANK` and calculate contribution percentages with window functions.
- **Power BI:** Ranked column chart with drill-down to month and category.
- **Expected decision:** Determine whether performance differences are driven mainly by demand, product mix, price, or discounting.

## Priority 1: Product Performance

### Q4. Which categories and products generate the most sales value?

- **Purpose:** Understand where sales are concentrated and which products deserve commercial attention.
- **Metrics:** Sales value, sales share, distinct orders, units sold, and AOV by category and product.
- **Data:** `orders_analytical.csv`; `ProductID`, `ProductName`, `Category`, `Quantity`, `Sales`, `OrderValue`.
- **Pandas:** Produce category and product rankings with minimum-volume context.
- **SQL:** Aggregate by category and product, then rank within the full dataset and by category.
- **Power BI:** Category contribution chart and a product ranking table with slicers.
- **Expected decision:** Prioritize products and categories for promotion, assortment review, or further investigation.

### Q5. Which products sell the most units, and does volume translate into sales value?

- **Purpose:** Separate high-demand products from high-price or high-value products.
- **Metrics:** Units sold, distinct orders, sales value, average unit price, and sales rank versus volume rank.
- **Data:** `orders_analytical.csv`; `ProductName`, `Category`, `Quantity`, `UnitPrice`, `Sales`.
- **Pandas:** Compare rank correlation and identify products with large differences between volume and sales rank.
- **SQL:** Use grouped aggregates and ranking functions.
- **Power BI:** Scatter plot of units versus sales, colored by category, plus a detail table.
- **Expected decision:** Identify volume drivers and products whose value is not explained by unit volume alone.

### Q6. How do discounts relate to sales performance?

- **Purpose:** Assess whether higher discounts are associated with higher order value or volume, without claiming causality.
- **Metrics:** Average discount, sales value, units sold, AOV, and order count by discount band or category.
- **Data:** `orders_analytical.csv`; `Discount`, `Quantity`, `Sales`, `OrderValue`, `Category`.
- **Pandas:** Create transparent discount bands and compare distributions and summary statistics.
- **SQL:** Aggregate by discount band and category.
- **Power BI:** Discount-band comparison and a scatter plot for discount versus order value.
- **Expected decision:** Identify discount patterns that merit controlled commercial testing.

## Priority 1: Customer Analysis

### Q7. How many customers purchased, and how concentrated is the customer base?

- **Purpose:** Measure reach and dependence on a small number of customers.
- **Metrics:** Unique purchasing customers, orders per customer, sales per customer, repeat-customer rate, and top-customer sales share.
- **Data:** `orders_analytical.csv`; `CustomerID`, `OrderID`, `Sales`, `OrderValue`.
- **Pandas:** Build a customer-level table and segment customers by purchase frequency.
- **SQL:** Aggregate to customer grain before calculating population-level metrics.
- **Power BI:** Customer KPI cards, frequency distribution, and Pareto chart.
- **Expected decision:** Evaluate customer concentration and the need for acquisition or retention actions.

### Q8. What is the purchasing behavior of new versus repeat customers?

- **Purpose:** Compare one-time and repeat purchasing behavior.
- **Metrics:** Customer count, orders per customer, sales per customer, AOV, and share of sales from repeat customers.
- **Data:** `orders_analytical.csv`; `CustomerID`, `OrderID`, `OrderDate`, `Sales`, `OrderValue`.
- **Pandas:** Classify customers by distinct order count and compare the groups.
- **SQL:** Use a customer-level CTE and aggregate the resulting cohorts.
- **Power BI:** Side-by-side comparison of one-time and repeat customers.
- **Expected decision:** Identify whether retention efforts could materially affect sales.

### Q9. Which customer segments and cities generate the most sales?

- **Purpose:** Understand geographic and segment-level differences in value and volume.
- **Metrics:** Customers, orders, sales value, AOV, and sales share by `CustomerSegment` and `City`.
- **Data:** `orders_analytical.csv`; `CustomerSegment`, `City`, `CustomerID`, `OrderID`, `Sales`, `OrderValue`.
- **Pandas:** Compare segment and city rankings while reporting missing geographic values separately.
- **SQL:** Join customer attributes at the correct grain and aggregate without duplicating orders.
- **Power BI:** Segment comparison and ranked city table. A map is optional only if geographic fields are reliable.
- **Expected decision:** Prioritize customer segments or locations for targeted campaigns and operational follow-up.

## Priority 2: Order and Payment Operations

### Q10. What is the order-status distribution and cancellation rate?

- **Purpose:** Assess the share of orders that are completed, cancelled, or in another operational state.
- **Metrics:** Distinct orders by status, status share, cancellation rate, and returned-order status share.
- **Data:** `orders_processed.csv`; `OrderID`, `Status`, `OrderDate`, `Sales`, `OrderValue`.
- **Pandas:** Normalize status labels, document the cancellation definition, and calculate rates using distinct orders.
- **SQL:** Use conditional aggregation by `Status`.
- **Power BI:** Status distribution with order count and sales value views.
- **Expected decision:** Identify operational leakage and quantify the value associated with cancelled orders.

### Q11. Which payment methods are most used, and how do they perform by order status?

- **Purpose:** Understand payment preference and whether method usage differs across outcomes.
- **Metrics:** Distinct orders, order share, sales value, AOV, and cancellation rate by payment method.
- **Data:** `orders_processed.csv`; `OrderID`, `PaymentMethod`, `Status`, `Sales`, `OrderValue`.
- **Pandas:** Compare payment methods using distinct-order metrics and report missing methods explicitly.
- **SQL:** Group by payment method and status, then calculate shares.
- **Power BI:** Payment-method comparison with a status breakdown.
- **Expected decision:** Identify payment methods that deserve availability, reliability, or experience investigation.

### Q12. Are payment records consistent with orders?

- **Purpose:** Validate the relationship between the payment and order datasets before using payment data in conclusions.
- **Metrics:** Matched orders, unmatched orders, payment records per order, and payment-status distribution.
- **Data:** `orders_processed.csv` and `payments_processed.csv`; `OrderID`, `PaymentID`, `PaymentStatus`.
- **Pandas:** Perform a reconciliation using left joins and duplicate-key checks.
- **SQL:** Use an anti-join and grouped relationship checks.
- **Power BI:** Data-quality page or reconciliation table, not a sales KPI page.
- **Expected decision:** Decide whether payment data is reliable enough for operational analysis.

## Explicit Data Limitations

### Return rate

The current dataset has an order status named `Returned`, so it can support a returned-order status share. This is only a proxy: the data has no return event, return date, return quantity, or refund amount. A true return rate and return-value analysis are deferred until a return or refund source is added.

### Profitability and margin

The current dataset contains sales price information but no product cost, shipping cost, tax, or margin fields. Profit and margin questions are out of scope for the current phase.

### Causality

These analyses describe associations and distributions. They do not prove that discounts, payment methods, or customer characteristics caused a change in sales.

## Definition of Done for Each Question

Before a question is considered answered, the project must contain:

1. A documented metric definition and grain.
2. A Pandas result with a validation check.
3. An equivalent SQL query or a documented reason it is not yet implemented.
4. A Power BI visual specification or dashboard implementation.
5. A concise insight that distinguishes observation from recommendation.
6. A note about data limitations, assumptions, and excluded records.