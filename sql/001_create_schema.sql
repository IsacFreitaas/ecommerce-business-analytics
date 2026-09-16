-- 001_create_schema.sql
--
-- Creates the relational schema for the e-commerce analytics project.
--
-- Design decisions:
--
-- 1. Table structure mirrors docs/data_dictionary.md exactly. No column is
--    invented here; this file only translates the documented dictionary into
--    SQL DDL.
--
-- 2. Foreign keys are added only where the data has already been validated
--    to be fully consistent (see docs/data_dictionary.md, "Referential
--    Integrity Decisions"):
--      - orders.product_id -> products.product_id   (0 unmatched rows)
--      - payments.order_id -> orders.order_id        (0 unmatched rows)
--
--    orders.customer_id intentionally has NO foreign key constraint.
--    30 orders in the source data reference a customer_id that does not
--    exist in the customers table. This is a known, documented data-quality
--    issue (see docs/data_dictionary.md). Enforcing a strict foreign key
--    here would reject those 30 real orders during data loading, which
--    contradicts the project's cleaning principle of preserving information
--    instead of silently discarding it. Referential completeness for
--    customer_id is instead validated at the application layer
--    (scripts/validate_postgres_data.py), consistent with
--    scripts/validate_metrics.py, which already reports this exact
--    "unmatched_customer_orders" count.
--
-- 3. orders_analytical is implemented as a VIEW, not a table. It is a
--    derived, denormalized projection of the four base tables. Storing it as
--    a second physical table would duplicate data and create two sources of
--    truth. The view recomputes Sales, DiscountAmount, and OrderValue using
--    the same formulas documented in docs/data_dictionary.md.

DROP VIEW IF EXISTS orders_analytical;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id      INTEGER PRIMARY KEY,
    age              NUMERIC,
    city             TEXT,
    signup_date      DATE,
    customer_segment TEXT
);

CREATE TABLE products (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT,
    category     TEXT,
    unit_price   NUMERIC
);

CREATE TABLE orders (
    order_id         INTEGER PRIMARY KEY,
    customer_id      INTEGER,  -- no FK: see Option B decision documented above
    order_date       DATE,
    product_id       INTEGER REFERENCES products (product_id),
    quantity         NUMERIC,
    discount         NUMERIC,
    payment_method   TEXT,
    status           TEXT,
    order_year       INTEGER,
    order_month      INTEGER,
    order_month_name TEXT
);

CREATE TABLE payments (
    payment_id     INTEGER PRIMARY KEY,
    order_id       INTEGER REFERENCES orders (order_id),
    payment_date   DATE,
    payment_status TEXT
);

CREATE VIEW orders_analytical AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.product_id,
    o.quantity,
    o.discount,
    o.payment_method,
    o.status,
    o.order_year,
    o.order_month,
    o.order_month_name,
    c.age,
    c.city,
    c.signup_date,
    c.customer_segment,
    p.product_name,
    p.category,
    p.unit_price,
    (o.quantity * p.unit_price)                       AS sales,
    (o.quantity * p.unit_price * o.discount)           AS discount_amount,
    (o.quantity * p.unit_price) * (1 - o.discount)     AS order_value
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN products  p ON o.product_id  = p.product_id;
