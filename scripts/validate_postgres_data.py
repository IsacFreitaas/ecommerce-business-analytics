"""Validate that the PostgreSQL tables match the processed CSV datasets.

Usage:
    venv/bin/python scripts/validate_postgres_data.py
"""

import sys
from pathlib import Path

import pandas as pd
from sqlalchemy import text
from sqlalchemy.engine import Engine

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.ecommerce_analytics.database import get_engine

PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DATA_PATH = PROJECT_ROOT / "data" / "processed"

PROCESSED_FILES = {
    "customers": "customers_processed.csv",
    "products": "products_processed.csv",
    "orders": "orders_processed.csv",
    "payments": "payments_processed.csv",
}


def validate_row_counts(engine: Engine) -> None:
    with engine.connect() as connection:
        for table_name, filename in PROCESSED_FILES.items():
            expected = len(pd.read_csv(PROCESSED_DATA_PATH / filename))
            actual = connection.execute(
                text(f"SELECT COUNT(*) FROM {table_name}")
            ).scalar_one()
            if actual != expected:
                raise ValueError(
                    f"{table_name}: expected {expected} rows from "
                    f"{filename}, found {actual} in PostgreSQL"
                )
            print(f"{table_name}: {actual} rows (matches {filename})")


def validate_unmatched_customer_orders(engine: Engine) -> None:
    query = """
        SELECT COUNT(*)
        FROM orders o
        LEFT JOIN customers c ON o.customer_id = c.customer_id
        WHERE c.customer_id IS NULL
    """
    with engine.connect() as connection:
        unmatched = connection.execute(text(query)).scalar_one()

    if unmatched != 30:
        raise ValueError(
            f"Expected 30 unmatched customer orders (documented limitation), "
            f"found {unmatched}"
        )
    print(f"Unmatched customer orders: {unmatched} (documented data-quality limitation)")


def validate_analytical_view(engine: Engine) -> None:
    query = """
        SELECT
            COUNT(DISTINCT order_id) AS distinct_orders,
            SUM(order_value) AS total_order_value
        FROM orders_analytical
        WHERE order_value IS NOT NULL
    """
    with engine.connect() as connection:
        distinct_orders, total_order_value = connection.execute(text(query)).one()

    if distinct_orders <= 0:
        raise ValueError("orders_analytical returned no valid order_value rows")

    print(f"orders_analytical: {distinct_orders} distinct orders with a valid order_value")
    print(f"orders_analytical: total order_value = {total_order_value}")


def main() -> None:
    engine = get_engine()
    validate_row_counts(engine)
    validate_unmatched_customer_orders(engine)
    validate_analytical_view(engine)
    print("PostgreSQL data validation completed successfully")


if __name__ == "__main__":
    main()
