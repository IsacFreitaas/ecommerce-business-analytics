"""Database connection utilities.

Credentials are read from environment variables, loaded from a local
`.env` file that is never committed to version control.
"""

from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import Engine, create_engine
import os

PROJECT_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_ROOT / ".env")


def get_database_url() -> str:
    """Build the PostgreSQL connection URL from environment variables."""
    host = os.environ.get("POSTGRES_HOST", "localhost")
    port = os.environ.get("POSTGRES_PORT", "5432")
    database = os.environ.get("POSTGRES_DB", "ecommerce_analytics")
    user = os.environ.get("POSTGRES_USER")
    password = os.environ.get("POSTGRES_PASSWORD", "")

    if not user:
        raise RuntimeError(
            "POSTGRES_USER is not set. Copy .env.example to .env and fill in "
            "your local PostgreSQL credentials."
        )

    return f"postgresql+psycopg://{user}:{password}@{host}:{port}/{database}"


def get_engine() -> Engine:
    """Create a SQLAlchemy engine for the project's PostgreSQL database."""
    return create_engine(get_database_url())
