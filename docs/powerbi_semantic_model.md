# Power BI Semantic Model

## Purpose

This document defines the Power BI data model: which tables are imported, how they relate, the grain of each table, and how the model handles the known data-quality exception (30 orders with no matching customer). It is the Power BI equivalent of [`sql/001_create_schema.sql`](../sql/001_create_schema.sql) and must stay consistent with [`docs/data_dictionary.md`](data_dictionary.md) and [`docs/analytical_metrics.md`](analytical_metrics.md).

## Data Source

Power BI connects to the local PostgreSQL database `ecommerce_analytics` using the PostgreSQL connector (`Get Data -> PostgreSQL database`), not to the processed CSV files directly.

Reasons for using PostgreSQL as the source instead of CSV:

- The relational schema and the `orders_analytical` view are already validated against Pandas (see `scripts/validate_postgres_data.py`).
- Foreign keys already enforce `orders.product_id` and `payments.order_id` consistency.
- A single source of truth avoids a second, divergent copy of the cleaning logic inside Power BI's Power Query.

The processed CSVs in `data/processed/` remain the documented fallback source if a reviewer cannot run PostgreSQL locally. This is noted in `docs/local_setup.md` and in the Power BI setup guide.

## Imported Tables

Import the four base tables directly. Do **not** import the `orders_analytical` view as a table; it is a denormalized convenience view for SQL/Pandas exploration, and importing it alongside the base tables would duplicate `orders`, `customers`, and `products` data inside the model (a classic star-schema mistake).

| Power BI table | Source | Grain | Role |
| --- | --- | --- | --- |
| `Orders` | `orders` | One row per `order_id` | Fact table |
| `Customers` | `customers` | One row per `customer_id` | Dimension |
| `Products` | `products` | One row per `product_id` | Dimension |
| `Payments` | `payments` | One row per `payment_id` | Fact table (secondary, for reconciliation) |
| `Calendar` | Generated in Power Query / DAX | One row per calendar date | Date dimension |

## Relationships

| From | To | Key | Cardinality | Cross-filter direction | Active |
| --- | --- | --- | --- | --- | --- |
| `Products` | `Orders` | `product_id` | One-to-many | Single (`Products` filters `Orders`) | Yes |
| `Customers` | `Orders` | `customer_id` | One-to-many | Single (`Customers` filters `Orders`) | Yes |
| `Orders` | `Payments` | `order_id` | One-to-many | Single (`Orders` filters `Payments`) | Yes |
| `Calendar` | `Orders` | `date` <-> `order_date` | One-to-many | Single (`Calendar` filters `Orders`) | Yes |

This is a star schema: `Orders` is the primary fact table, `Customers`, `Products`, and `Calendar` are dimensions, and `Payments` is a secondary fact table used only for reconciliation visuals (Q12), not for sales measures.

### Handling the `Customers -> Orders` relationship (30 unmatched orders)

The source data has 30 orders whose `customer_id` does not match any row in `customers` (documented in `docs/data_dictionary.md`, "Referential Integrity Decisions"). In Power BI:

- Keep the relationship as a **regular one-to-many relationship**, not an inactive one. Power BI relationships (unlike SQL foreign keys) do not reject unmatched rows at load time; unmatched orders simply will not match any `Customers` row.
- Do **not** filter these 30 orders out of the `Orders` table. They must remain visible for order-level and status metrics (Q1, Q2, Q10, Q11).
- They are automatically excluded from any visual that slices by a `Customers` column (city, segment, age), because a one-to-many relationship shows blanks or drops unmatched rows depending on the visual type. This matches the documented exclusion rule already used in Pandas and SQL for customer-attribute analysis.
- The Data Quality dashboard page (see `docs/powerbi_dashboard_specification.md`) must display this count explicitly using the `Unmatched Customer Orders` measure, so the exclusion is visible instead of silent.

## Calendar Table

`Orders.order_date` has missing values (see `docs/data_dictionary.md`, "Dated Sales Scope"), so the `Calendar` table must **not** be auto-generated from `Orders.order_date` alone; it must span the full observed range with no gaps, independent of missing dates.

Create the table in DAX (`Modeling -> New table`):

```dax
Calendar =
CALENDAR (
    DATE ( YEAR ( MIN ( Orders[order_date] ) ), 1, 1 ),
    DATE ( YEAR ( MAX ( Orders[order_date] ) ), 12, 31 )
)
```

Add these calculated columns to `Calendar`:

```dax
Calendar[Year] = YEAR ( Calendar[Date] )
Calendar[Month Number] = MONTH ( Calendar[Date] )
Calendar[Month Name] = FORMAT ( Calendar[Date], "MMMM" )
Calendar[Year-Month] = FORMAT ( Calendar[Date], "YYYY-MM" )
```

Mark `Calendar` as a **Date table** (`Table tools -> Mark as date table`, using the `Date` column). Orders with a missing `order_date` will not join to any row in `Calendar` and will be excluded from time-based visuals, consistent with the documented "Dated Sales Scope."

## Column Usage Notes

- `Orders[status]`: used for order-status and cancellation-rate visuals (Q10, Q11). Do not rename or recode values in Power Query; keep the same labels used in `docs/business_questions.md` (`Completed`, `Cancelled`, `Returned`).
- `Orders[discount]`: stored as a proportion (e.g., `0.10` = 10%), matching the SQL and Pandas convention. Do not multiply by 100 in Power Query; format as a percentage only at the visual level.
- `Payments[payment_status]`: used only in the reconciliation page. Do not use `Payments` to compute sales measures; monetary values live in `Orders` and `Products`.
- Hide foreign key columns that are only used for relationships (`Orders[customer_id]`, `Orders[product_id]`, `Payments[order_id]`) from the report view once relationships are created, to keep the field list clean for report building.

## Model Validation Checklist

Before building measures, confirm in Power BI:

1. `Orders` row count matches `50000` (see `scripts/validate_postgres_data.py` output).
2. `Customers` row count matches `10000`.
3. `Products` row count matches `20`.
4. `Payments` row count matches `50000`.
5. A visual with `Orders[order_id]` (distinct count) and no filters returns `50000`.
6. A visual with `Orders[order_id]` (distinct count) filtered to non-blank `Customers[customer_id]` returns `49970` (`50000 - 30` unmatched, matching the "Full Operational Scope" minus the documented exception before financial-scope exclusions apply).

## TODO

- Confirm whether the final report will connect live to PostgreSQL (`DirectQuery`) or import a snapshot (`Import` mode). Import mode is recommended for a portfolio project: faster visuals, no dependency on a running local database when the report file is shared.
- Document the refresh procedure if a reviewer needs to reload the model after changing the processed data.
