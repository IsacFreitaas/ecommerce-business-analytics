"""Load the processed datasets into the local PostgreSQL database.

Usage:
    venv/bin/python scripts/load_to_postgres.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.ecommerce_analytics.database import get_engine
from src.ecommerce_analytics.load_data import load_processed_data


def main() -> None:
    engine = get_engine()
    row_counts = load_processed_data(engine)

    for table_name, count in row_counts.items():
        print(f"Loaded {count} rows into {table_name}")
    print("Data load completed successfully")


if __name__ == "__main__":
    main()
