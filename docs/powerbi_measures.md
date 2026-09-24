# Power BI DAX Measures

## Purpose

This document defines the DAX measures for the Power BI model described in [`docs/powerbi_semantic_model.md`](powerbi_semantic_model.md). Every measure formula, grain, and scope must match [`docs/analytical_metrics.md`](analytical_metrics.md) exactly. This is the Power BI equivalent of `sql/002_business_queries.sql`.

All measures below assume the relationships and table names defined in the semantic model. Create them in a dedicated measure table named `_Measures` (an empty table added only to hold measures, a common Power BI convention to avoid attaching business logic to a physical data table).

## Scope Helper Table and Columns

These reproduce the analytical scopes defined in `docs/analytical_metrics.md`. `Financial Rows` is an optional calculated table; `Sales` and `Order Value` are calculated columns on `Orders`.

```dax
Financial Rows =
CALCULATETABLE (
    Orders,
    NOT ISBLANK ( Orders[quantity] ),
    NOT ISBLANK ( Orders[discount] )
)
```

```dax
Order Value =
VAR Sales = Orders[quantity] * RELATED ( Products[unit_price] )
RETURN
    IF (
        NOT ISBLANK ( Orders[quantity] ) && NOT ISBLANK ( Orders[discount] ),
        Sales * ( 1 - Orders[discount] )
    )
```

`Order Value` is a **calculated column** on `Orders`, not a measure, because it must exist at order grain before it can be summed or filtered by other measures. It reproduces the `OrderValue` formula from `docs/data_dictionary.md` (`Sales * (1 - Discount)`), keeping Power BI's financial scope identical to Pandas and SQL: a row is excluded (blank) when `quantity` or `discount` is missing.

Add a matching `Sales` calculated column for the gross value:

```dax
Sales =
IF (
    NOT ISBLANK ( Orders[quantity] ),
    Orders[quantity] * RELATED ( Products[unit_price] )
)
```

## Core Sales Measures

```dax
Distinct Orders = DISTINCTCOUNT ( Orders[order_id] )
```

```dax
Units Sold = SUM ( Orders[quantity] )
```

```dax
Gross Sales = SUM ( Orders[Sales] )
```

```dax
Net Order Value = SUM ( Orders[Order Value] )
```

```dax
Average Order Value =
DIVIDE ( [Net Order Value], [Distinct Orders] )
```

```dax
Units Per Order =
DIVIDE ( [Units Sold], [Distinct Orders] )
```

These five measures reproduce Q1 exactly. `AOV` and `Units Per Order` use `DIVIDE` instead of `/` so the measure returns a blank instead of an error when a filter context has zero orders (for example, an empty slicer selection).

## Time Measures (Q2, Q3)

```dax
Sales Share by Period =
DIVIDE ( [Net Order Value], CALCULATE ( [Net Order Value], ALL ( Calendar ) ) )
```

```dax
Order Share by Period =
DIVIDE ( [Distinct Orders], CALCULATE ( [Distinct Orders], ALL ( Calendar ) ) )
```

```dax
Previous Month Net Order Value =
CALCULATE ( [Net Order Value], DATEADD ( Calendar[Date], -1, MONTH ) )
```

```dax
Month over Month Change =
DIVIDE (
    [Net Order Value] - [Previous Month Net Order Value],
    [Previous Month Net Order Value]
)
```

Use `Sales Share by Period` and `Order Share by Period` inside a table visual sorted by month to reproduce Q3's ranked-months view (`sql/002_business_queries.sql`, `sales_rank`/`sales_share`). Power BI's built-in ranking visuals (or a `RANKX` measure, see below) replace the SQL `DENSE_RANK`.

```dax
Month Sales Rank =
RANKX ( ALL ( Calendar[Year-Month] ), [Net Order Value], , DESC, Dense )
```

## Product Measures (Q4, Q5, Q6)

```dax
Product Sales Share =
DIVIDE ( [Net Order Value], CALCULATE ( [Net Order Value], ALL ( Products ) ) )
```

```dax
Product Units Rank =
RANKX ( ALL ( Products[product_id] ), [Units Sold], , DESC )
```

```dax
Product Sales Rank =
RANKX ( ALL ( Products[product_id] ), [Net Order Value], , DESC )
```

```dax
Product Rank Difference = [Product Units Rank] - [Product Sales Rank]
```

`Product Rank Difference` reproduces the `rank_difference` column from Q5: a positive value means a product sells more units than its revenue rank would suggest.

```dax
Average Discount = AVERAGE ( Orders[discount] )
```

```dax
Discount Band =
SWITCH (
    TRUE (),
    Orders[discount] = 0, "0% (no discount)",
    Orders[discount] <= 0.10, "0-10%",
    Orders[discount] <= 0.20, "10-20%",
    "20%+"
)
```

`Discount Band` is a **calculated column** on `Orders`, matching the `CASE` expression in Q6 exactly (same thresholds, same labels), so it can be used as a slicer and axis field.

## Customer Measures (Q7, Q8, Q9)

```dax
Purchasing Customers =
CALCULATE (
    DISTINCTCOUNT ( Orders[customer_id] ),
    NOT ISBLANK ( Orders[customer_id] ),
    Orders[customer_id] <> BLANK ()
)
```

Power BI already excludes unmatched `customer_id` values from any visual that also uses a `Customers` column (see the semantic model doc), but `Purchasing Customers` must return the correct total even in visuals with **no** `Customers` field present. Use this explicit filter, reproducing the SQL `EXISTS` check from Q7:

```dax
Purchasing Customers =
CALCULATE (
    DISTINCTCOUNT ( Orders[customer_id] ),
    TREATAS ( VALUES ( Customers[customer_id] ), Orders[customer_id] )
)
```

```dax
Customer Distinct Orders =
CALCULATE ( [Distinct Orders], ALLEXCEPT ( Orders, Orders[customer_id] ) )
```

```dax
Repeat Customers =
SUMX (
    VALUES ( Orders[customer_id] ),
    IF ( [Customer Distinct Orders] > 1, 1, 0 )
)
```

```dax
Repeat Customer Rate =
DIVIDE ( [Repeat Customers], [Purchasing Customers] )
```

```dax
Top 10 Customers Sales Share =
VAR CustomerRank =
    RANKX ( ALL ( Customers[customer_id] ), CALCULATE ( [Net Order Value] ) )
VAR Top10Value =
    CALCULATE ( [Net Order Value], FILTER ( ALL ( Customers ), CustomerRank <= 10 ) )
RETURN
    DIVIDE ( Top10Value, CALCULATE ( [Net Order Value], ALL ( Customers ) ) )
```

```dax
Customer Type =
IF ( [Customer Distinct Orders] > 1, "Repeat", "One-time" )
```

`Customer Type` should be used as a **calculated column on `Customers`** for slicers (Q8), computed with the same `Customer Distinct Orders` logic but evaluated per customer row context.

## Operational Measures (Q10, Q11, Q12)

```dax
Order Status Share =
DIVIDE ( [Distinct Orders], CALCULATE ( [Distinct Orders], ALL ( Orders[status] ) ) )
```

```dax
Cancellation Rate =
DIVIDE (
    CALCULATE ( [Distinct Orders], Orders[status] = "Cancelled" ),
    CALCULATE ( [Distinct Orders], ALL ( Orders[status] ) )
)
```

```dax
Returned Status Share =
DIVIDE (
    CALCULATE ( [Distinct Orders], Orders[status] = "Returned" ),
    CALCULATE ( [Distinct Orders], ALL ( Orders[status] ) )
)
```

```dax
Payment Coverage =
DIVIDE ( DISTINCTCOUNT ( Payments[order_id] ), [Distinct Orders] )
```

```dax
Unmatched Payments =
CALCULATE (
    COUNTROWS ( Payments ),
    FILTER ( Payments, ISBLANK ( RELATED ( Orders[order_id] ) ) )
)
```

```dax
Orders Without Payment =
VAR OrdersWithPayment = DISTINCTCOUNT ( Payments[order_id] )
RETURN [Distinct Orders] - OrdersWithPayment
```

```dax
Payment Status Share =
DIVIDE (
    COUNTROWS ( Payments ),
    CALCULATE ( COUNTROWS ( Payments ), ALL ( Payments[payment_status] ) )
)
```

```dax
Unmatched Customer Orders =
CALCULATE (
    [Distinct Orders],
    FILTER ( Orders, ISBLANK ( RELATED ( Customers[customer_id] ) ) )
)
```

`Unmatched Customer Orders` must equal `30` with no filters applied; it is the Power BI equivalent of the SQL anti-join used to confirm this count in `docs/data_dictionary.md`.

## Validation Rules

Before using any measure in a visual:

1. Compare the unfiltered value against the corresponding SQL result in `sql/002_business_queries.sql` and the Pandas result from `scripts/validate_metrics.py`.
2. Confirm `Unmatched Customer Orders` returns `30`.
3. Confirm `Distinct Orders` (no filters) returns `50000`.
4. Confirm `Net Order Value` (no filters) returns `3480613.75`.
5. Confirm `Average Order Value` (no filters) returns approximately `70.03`.
6. Confirm `Purchasing Customers` (no filters) returns `9939` and `Repeat Customer Rate` returns approximately `0.9680`.

## TODO

- Add measures for the segment and city breakdowns in Q9 once `Customers[customer_segment]` and `Customers[city]` are confirmed as report-ready columns.
- Add a `Selected KPI` disconnected-table pattern if the dashboard needs a single dynamic KPI card (deferred until the dashboard specification is implemented).
