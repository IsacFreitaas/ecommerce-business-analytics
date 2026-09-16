# SQL Scripts

This directory contains the SQL used to build and query the PostgreSQL analytical model for this project.

## Execution Order

Run the files in numeric order against the `ecommerce_analytics` database:

```bash
psql -d ecommerce_analytics -f sql/001_create_schema.sql
```

| File | Purpose |
| --- | --- |
| `001_create_schema.sql` | Creates the four base tables and the `orders_analytical` view. |
| `002_business_queries.sql` | (planned) SQL queries that reproduce the business questions answered with Pandas. |

## Design Decisions

### Tables mirror the data dictionary

Every table and column in `001_create_schema.sql` corresponds directly to an entry in [`docs/data_dictionary.md`](../docs/data_dictionary.md). No column is introduced here that is not already documented there.

### Foreign keys reflect validated data quality, not assumptions

A foreign key is only added where the relationship has already been validated as fully consistent:

- `orders.product_id -> products.product_id`: every order references an existing product.
- `payments.order_id -> orders.order_id`: every payment references an existing order (see Issue #7 reconciliation).

`orders.customer_id` has **no** foreign key constraint. The source data contains 30 orders whose `customer_id` does not exist in the `customers` table. This is documented in [`docs/data_dictionary.md`](../docs/data_dictionary.md) as a known data-quality limitation, not a defect introduced by this project.

Two designs were considered:

- **Enforce the foreign key strictly.** This would cause the data-loading step to reject those 30 real orders, effectively deleting valid operational history to satisfy a database constraint.
- **Leave the column unconstrained and validate it at the application layer instead (the option used here).** The 30 unmatched orders remain loadable and queryable, exactly as they exist in the source system. Their referential completeness is checked in Python (`scripts/validate_postgres_data.py`), which reports the same `unmatched_customer_orders` count already produced by `scripts/validate_metrics.py`.

This mirrors the same principle already used during data cleaning: preserve information and document exceptions instead of silently discarding records to satisfy a technical rule.

### `orders_analytical` is a view, not a table

The view recomputes `sales`, `discount_amount`, and `order_value` using `LEFT JOIN`s, so it always reflects the current state of the base tables and never becomes a second, divergent copy of the data.
