"""Load the processed CSV datasets into the PostgreSQL tables.

Tables are loaded in dependency order (customers and products before
orders, orders before payments) so that foreign keys are always satisfied.
"""

from pathlib import Path

import pandas as pd
from sqlalchemy import text
from sqlalchemy.engine import Engine

PROJECT_ROOT = Path(__file__).resolve().parents[2]
PROCESSED_DATA_PATH = PROJECT_ROOT / "data" / "processed"

# Maps each table to its source file and the CSV -> SQL column renames.
TABLE_CONFIG = {
    "customers": {
        "file": "customers_processed.csv",
        "columns": {
            "CustomerID": "customer_id",
            "Age": "age",
            "City": "city",
            "SignupDate": "signup_date",
            "CustomerSegment": "customer_segment",
        },
        "date_columns": ["signup_date"],
    },
    "products": {
        "file": "products_processed.csv",
        "columns": {
            "ProductID": "product_id",
            "ProductName": "product_name",
            "Category": "category",
            "UnitPrice": "unit_price",
        },
        "date_columns": [],
    },
    "orders": {
        "file": "orders_processed.csv",
        "columns": {
            "OrderID": "order_id",
            "CustomerID": "customer_id",
            "OrderDate": "order_date",
            "ProductID": "product_id",
            "Quantity": "quantity",
            "Discount": "discount",
            "PaymentMethod": "payment_method",
            "Status": "status",
            "OrderYear": "order_year",
            "OrderMonth": "order_month",
            "OrderMonthName": "order_month_name",
        },
        "date_columns": ["order_date"],
    },
    "payments": {
        "file": "payments_processed.csv",
        "columns": {
            "PaymentID": "payment_id",
            "OrderID": "order_id",
            "PaymentDate": "payment_date",
            "PaymentStatus": "payment_status",
        },
        "date_columns": ["payment_date"],
    },
}

# Load order respects the foreign keys defined in sql/001_create_schema.sql.
LOAD_ORDER = ["customers", "products", "orders", "payments"]


def _read_table_csv(table_name: str) -> pd.DataFrame:
    config = TABLE_CONFIG[table_name]
    dataframe = pd.read_csv(PROCESSED_DATA_PATH / config["file"])
    dataframe = dataframe.rename(columns=config["columns"])
    dataframe = dataframe[list(config["columns"].values())]

    for column in config["date_columns"]:
        dataframe[column] = pd.to_datetime(dataframe[column], errors="coerce")

    return dataframe


def load_processed_data(engine: Engine) -> dict[str, int]:
    """Load every processed dataset into its PostgreSQL table.

    Existing rows are removed first, so this function can be re-run without
    duplicating data.
    """
    row_counts: dict[str, int] = {}

    with engine.begin() as connection:
        connection.execute(
            text(
                "TRUNCATE TABLE payments, orders, products, customers "
                "RESTART IDENTITY CASCADE"
            )
        )

        for table_name in LOAD_ORDER:
            dataframe = _read_table_csv(table_name)
            dataframe.to_sql(
                table_name, connection, if_exists="append", index=False
            )
            row_counts[table_name] = len(dataframe)

    return row_counts
