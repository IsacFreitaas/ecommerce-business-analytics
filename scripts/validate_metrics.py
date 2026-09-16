from pathlib import Path

import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DATA_PATH = PROJECT_ROOT / "data" / "processed"


def load_data() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    analytical = pd.read_csv(PROCESSED_DATA_PATH / "orders_analytical.csv")
    orders = pd.read_csv(PROCESSED_DATA_PATH / "orders_processed.csv")
    payments = pd.read_csv(PROCESSED_DATA_PATH / "payments_processed.csv")
    customers = pd.read_csv(PROCESSED_DATA_PATH / "customers_processed.csv")
    return analytical, orders, payments, customers


def validate_sales_metrics(analytical: pd.DataFrame) -> dict[str, float]:
    financial = analytical.dropna(subset=["Sales", "OrderValue"]).copy()
    distinct_orders = financial["OrderID"].nunique()
    order_value = financial["OrderValue"].sum()
    aov = order_value / distinct_orders

    grouped_order_value = financial.groupby("Category")["OrderValue"].sum()
    category_share = grouped_order_value / order_value

    assert distinct_orders > 0
    assert np.isclose(aov, financial.groupby("OrderID")["OrderValue"].sum().mean())
    assert np.isclose(category_share.sum(), 1.0)
    assert (category_share >= 0).all()

    return {
        "financial_rows": len(financial),
        "excluded_financial_rows": len(analytical) - len(financial),
        "distinct_orders": distinct_orders,
        "gross_sales": financial["Sales"].sum(),
        "net_order_value": order_value,
        "aov": aov,
    }


def validate_customer_metrics(
    analytical: pd.DataFrame, customers: pd.DataFrame
) -> dict[str, float]:
    # Full operational scope for customer counting: every cleaned order,
    # excluding only the orders whose CustomerID has no matching customer
    # record (see docs/data_dictionary.md, "Referential Integrity Decisions").
    matched_orders = analytical[
        analytical["CustomerID"].isin(customers["CustomerID"])
    ].copy()
    customer_summary = matched_orders.groupby("CustomerID").agg(
        distinct_orders=("OrderID", "nunique"),
        order_value=("OrderValue", "sum"),  # sum() skips NaN: financial scope applied automatically
    )
    repeat_customers = customer_summary["distinct_orders"] > 1
    customer_share = customer_summary["order_value"] / customer_summary["order_value"].sum()

    assert customer_summary.index.is_unique
    assert np.isclose(customer_share.dropna().sum(), 1.0)
    assert repeat_customers.sum() <= len(customer_summary)

    return {
        "purchasing_customers": len(customer_summary),
        "repeat_customers": int(repeat_customers.sum()),
        "repeat_customer_rate": repeat_customers.mean(),
        "unmatched_customer_orders": int(
            (~analytical["CustomerID"].isin(customers["CustomerID"])).sum()
        ),
    }


def validate_operational_metrics(
    orders: pd.DataFrame, payments: pd.DataFrame
) -> dict[str, float]:
    order_status_share = orders["Status"].value_counts(normalize=True, dropna=False)
    payment_status_share = payments["PaymentStatus"].value_counts(
        normalize=True, dropna=False
    )
    payment_coverage = payments["OrderID"].nunique() / orders["OrderID"].nunique()

    assert np.isclose(order_status_share.sum(), 1.0)
    assert np.isclose(payment_status_share.sum(), 1.0)
    assert 0 <= payment_coverage <= 1
    assert payments["PaymentID"].is_unique

    return {
        "order_status_count": len(order_status_share),
        "payment_status_count": len(payment_status_share),
        "payment_coverage": payment_coverage,
        "unmatched_payments": int(
            (~payments["OrderID"].isin(orders["OrderID"])).sum()
        ),
        "orders_without_payment": int(
            (~orders["OrderID"].isin(payments["OrderID"])).sum()
        ),
    }


def main() -> None:
    analytical, orders, payments, customers = load_data()
    results = {
        "sales": validate_sales_metrics(analytical),
        "customers": validate_customer_metrics(analytical, customers),
        "operations": validate_operational_metrics(orders, payments),
    }

    for section, metrics in results.items():
        print(f"[{section}]")
        for name, value in metrics.items():
            print(f"{name}: {value}")
    print("Analytical metric validation completed successfully")


if __name__ == "__main__":
    main()
