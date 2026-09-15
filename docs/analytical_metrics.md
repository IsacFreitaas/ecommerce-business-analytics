# Analytical Metrics

## Purpose

This document defines the authoritative metric contract for the e-commerce analytics project. The same definitions must be used by Pandas, PostgreSQL, SQLAlchemy-based execution, and Power BI.

A metric is not considered finalized until its name, formula, grain, scope, exclusions, and interpretation are documented here.

## General Conventions

- `orders_analytical.csv` is the primary source for sales, product, and customer metrics.
- `orders_processed.csv` and `payments_processed.csv` are used for normalized relationship and payment analysis.
- The current dataset has one row per cleaned `OrderID`. This must be revalidated if the source grain changes.
- Order-level counts use `nunique(OrderID)` or `COUNT(DISTINCT OrderID)`.
- Customer-level metrics are calculated after aggregating by `CustomerID`.
- Product-level metrics are calculated after aggregating by `ProductID`.
- Monetary metrics exclude rows where the required monetary field is missing and must report the excluded count.
- Missing values are not silently converted to zero.
- All percentages are calculated within the same filter scope as their numerator and denominator.

## Analytical Scopes

### Full Operational Scope

The full operational scope includes all cleaned orders with a valid `OrderID`. It is appropriate for order volume, status distribution, payment reconciliation, and operational quality metrics.

### Dated Sales Scope

The dated sales scope includes orders with a valid `OrderDate`. It is required for monthly and time-based analysis.

### Financial Scope

The financial scope includes rows with the required fields for the metric being calculated. For `OrderValue`, both `Sales` and `Discount` must be available. Financial results must include the number of excluded rows.

### Completed Sales Scope

The completed sales scope includes orders where `Status = 'Completed'` and the required financial fields are available. It is the preferred scope for realized-sales reporting when the question concerns completed business rather than operational demand.

Unless a question states otherwise, exploratory results must display the scope used instead of assuming that all statuses represent realized revenue.

## Core Sales Metrics

| Metric | Definition | Grain | Default scope |
| --- | --- | --- | --- |
| Distinct orders | Number of unique `OrderID` values. | Order | Full operational scope |
| Units sold | Sum of non-missing `Quantity`. | Order | Full operational scope |
| Gross sales value | Sum of `Sales`. | Order | Financial scope |
| Net order value | Sum of `OrderValue`. | Order | Financial scope |
| Average order value (AOV) | Total `OrderValue` divided by distinct orders included in the same financial scope. | Order | Financial scope |
| Orders per customer | Distinct orders divided by purchasing customers. | Customer | Full operational scope |
| Units per order | Units sold divided by distinct orders in the same scope. | Order | Full operational scope |

`Sales` is the gross transaction value before discount. `OrderValue` is the net transaction value after discount. Neither metric represents profit.

## Time Metrics

| Metric | Definition | Grain | Exclusions |
| --- | --- | --- | --- |
| Monthly order value | Sum of `OrderValue` grouped by calendar month from `OrderDate`. | Month | Missing `OrderDate` or `OrderValue` |
| Monthly distinct orders | Unique `OrderID` values grouped by calendar month. | Month | Missing `OrderDate` |
| Monthly AOV | Monthly `OrderValue` divided by monthly distinct orders in the same scope. | Month | Missing `OrderDate` or `OrderValue` |
| Period-over-period change | Current period metric minus previous period metric, divided by previous period metric. | Month or year | Previous period must be non-zero |
| Sales share by period | Period `OrderValue` divided by total `OrderValue` in the selected scope. | Month or year | Missing `OrderValue` |

## Product Metrics

| Metric | Definition | Grain | Default scope |
| --- | --- | --- | --- |
| Product order value | Sum of `OrderValue` grouped by `ProductID`. | Product | Financial scope |
| Product sales share | Product `OrderValue` divided by total product `OrderValue`. | Product | Financial scope |
| Product units sold | Sum of `Quantity` grouped by `ProductID`. | Product | Quantity scope |
| Product distinct orders | Unique `OrderID` values grouped by `ProductID`. | Product | Full operational scope |
| Category order value | Sum of `OrderValue` grouped by `Category`. | Category | Financial scope |
| Product AOV | Product `OrderValue` divided by distinct product orders. | Product | Financial scope |

Product rankings by order value and units sold are different views. A high-volume product is not automatically the highest-value product.

## Customer Metrics

| Metric | Definition | Grain | Default scope |
| --- | --- | --- | --- |
| Purchasing customers | Unique `CustomerID` values associated with orders. | Customer | Full operational scope |
| Repeat customer | Customer with more than one distinct `OrderID`. | Customer | Full operational scope |
| Repeat-customer rate | Repeat customers divided by purchasing customers. | Customer | Full operational scope |
| Customer order value | Sum of `OrderValue` grouped by `CustomerID`. | Customer | Financial scope |
| Customer AOV | Customer `OrderValue` divided by distinct customer orders. | Customer | Financial scope |
| Top-customer sales share | Order value from the top N customers divided by total order value. | Customer | Financial scope |
| Segment sales share | Segment `OrderValue` divided by total `OrderValue` in the same scope. | Segment | Financial scope |

Orders without a matching customer record are excluded from customer-attribute analysis and reported separately. They remain valid order records for order-level analysis.

## Operational Metrics

| Metric | Definition | Grain | Default scope |
| --- | --- | --- | --- |
| Order status share | Orders with a given `Status` divided by all operational orders. | Order | Full operational scope |
| Cancellation rate | Orders where `Status = 'Cancelled'` divided by all operational orders. | Order | Full operational scope |
| Returned-status share | Orders where `Status = 'Returned'` divided by all operational orders. | Order | Full operational scope |
| Payment status share | Payment records with a given `PaymentStatus` divided by all payment records. | Payment | Full operational scope |
| Payment coverage | Orders with at least one payment record divided by all orders. | Order | Full operational scope |
| Unmatched payment records | Payment records whose `OrderID` is absent from orders. | Payment | Full operational scope |

`Returned` is a status proxy, not a complete return event. A true return rate requires return or refund event data.

## Discount Metrics

| Metric | Definition | Grain | Default scope |
| --- | --- | --- | --- |
| Average discount | Mean of non-missing `Discount` values. | Order | Financial scope |
| Discount amount | Sum of `DiscountAmount`. | Order | Financial scope |
| Discount rate by group | Group discount amount divided by group gross `Sales`. | Group | Financial scope |

Discount metrics describe association with sales outcomes. They do not establish that discounts caused higher or lower demand.

## Validation Rules

Before a metric is reported:

1. Confirm that the source dataset and column names match the data dictionary.
2. Confirm the analytical grain and use distinct keys where required.
3. Report the selected analytical scope.
4. Count excluded records for required fields.
5. Check that denominators are non-zero.
6. Compare equivalent Pandas and SQL results using the same filters.
7. Preserve the difference between observation and recommendation.

## Cross-Tool Mapping

| Layer | Responsibility |
| --- | --- |
| Pandas | Exploratory calculation, validation, and initial interpretation. |
| PostgreSQL | Reproducible relational aggregation and SQL learning. |
| SQLAlchemy | Database connection, table loading, query execution, and result retrieval. |
| Power BI | Semantic model, DAX measures, filters, and business communication. |

SQLAlchemy does not replace SQL. The project will use explicit SQL queries executed through SQLAlchemy so that the database logic remains visible and transferable.

## TODO

- Add metric-level Pandas validation outputs to the exploratory notebook.
- Implement equivalent PostgreSQL queries for the core metrics.
- Create Power BI measures using these definitions.
- Add automated cross-tool comparison checks.
