from pathlib import Path

import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DATA_PATH = PROJECT_ROOT / "data" / "processed"

EXPECTED_SCHEMAS = {
    "customers_processed.csv": [
        "CustomerID",
        "Age",
        "City",
        "SignupDate",
        "CustomerSegment",
    ],
    "orders_processed.csv": [
        "OrderID",
        "CustomerID",
        "OrderDate",
        "ProductID",
        "Quantity",
        "Discount",
        "PaymentMethod",
        "Status",
        "OrderYear",
        "OrderMonth",
        "OrderMonthName",
    ],
    "payments_processed.csv": [
        "PaymentID",
        "OrderID",
        "PaymentDate",
        "PaymentStatus",
    ],
    "products_processed.csv": [
        "ProductID",
        "ProductName",
        "Category",
        "UnitPrice",
    ],
    "orders_analytical.csv": [
        "OrderID",
        "CustomerID",
        "OrderDate",
        "ProductID",
        "Quantity",
        "Discount",
        "PaymentMethod",
        "Status",
        "OrderYear",
        "OrderMonth",
        "OrderMonthName",
        "ProductName",
        "Category",
        "UnitPrice",
        "Sales",
        "DiscountAmount",
        "OrderValue",
        "Age",
        "City",
        "SignupDate",
        "CustomerSegment",
    ],
}

UNIQUE_KEYS = {
    "customers_processed.csv": "CustomerID",
    "orders_processed.csv": "OrderID",
    "payments_processed.csv": "PaymentID",
    "products_processed.csv": "ProductID",
    "orders_analytical.csv": "OrderID",
}


def load_processed_data() -> dict[str, pd.DataFrame]:
    datasets = {}
    for filename in EXPECTED_SCHEMAS:
        path = PROCESSED_DATA_PATH / filename
        if not path.exists():
            raise FileNotFoundError(f"Missing processed dataset: {path}")
        datasets[filename] = pd.read_csv(path)
    return datasets


def validate_schemas(datasets: dict[str, pd.DataFrame]) -> None:
    for filename, expected_columns in EXPECTED_SCHEMAS.items():
        actual_columns = datasets[filename].columns.tolist()
        if actual_columns != expected_columns:
            raise ValueError(
                f"{filename} has an unexpected schema.\n"
                f"Expected: {expected_columns}\n"
                f"Actual: {actual_columns}"
            )


def validate_unique_keys(datasets: dict[str, pd.DataFrame]) -> None:
    for filename, key in UNIQUE_KEYS.items():
        key_series = datasets[filename][key]
        if key_series.isna().any():
            raise ValueError(f"{filename} contains missing values in {key}")
        if key_series.duplicated().any():
            raise ValueError(f"{filename} contains duplicate values in {key}")


def validate_relationships(datasets: dict[str, pd.DataFrame]) -> list[str]:
    customers = datasets["customers_processed.csv"]
    orders = datasets["orders_processed.csv"]
    payments = datasets["payments_processed.csv"]
    products = datasets["products_processed.csv"]

    warnings = []
    missing_customers = (~orders["CustomerID"].isin(customers["CustomerID"])).sum()
    if missing_customers:
        warnings.append(
            f"{missing_customers} orders have no matching customer record"
        )

    missing_products = (~orders["ProductID"].isin(products["ProductID"])).sum()
    if missing_products:
        raise ValueError(
            f"{missing_products} orders have no matching product record"
        )

    missing_orders = (~payments["OrderID"].isin(orders["OrderID"])).sum()
    if missing_orders:
        raise ValueError(
            f"{missing_orders} payments have no matching order record"
        )

    return warnings


def validate_financial_formulas(analytical: pd.DataFrame) -> None:
    sales_rows = analytical[["Quantity", "UnitPrice", "Sales"]].dropna()
    if not np.isclose(
        sales_rows["Sales"],
        sales_rows["Quantity"] * sales_rows["UnitPrice"],
    ).all():
        raise ValueError("Sales does not match Quantity * UnitPrice")

    order_value_rows = analytical[["Sales", "Discount", "OrderValue"]].dropna()
    if not np.isclose(
        order_value_rows["OrderValue"],
        order_value_rows["Sales"] * (1 - order_value_rows["Discount"]),
    ).all():
        raise ValueError("OrderValue does not match the documented formula")


def main() -> None:
    datasets = load_processed_data()
    validate_schemas(datasets)
    validate_unique_keys(datasets)
    warnings = validate_relationships(datasets)
    validate_financial_formulas(datasets["orders_analytical.csv"])

    for filename, dataframe in datasets.items():
        print(f"Validated {filename}: {len(dataframe)} rows")
    for warning in warnings:
        print(f"WARNING: {warning}")
    print("Data validation completed successfully")


if __name__ == "__main__":
    main()