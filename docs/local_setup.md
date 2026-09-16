# Local Project Setup

This guide explains how to prepare the local environment and reproduce the current data pipeline.

## Prerequisites

Install the following tools:

- Python 3.11 or newer.
- Git.
- Visual Studio Code with the Python and Jupyter extensions.

PostgreSQL and Power BI are not required for the current Python and exploratory analysis stage. They will be added in the SQL and business intelligence stages.

## Clone the Repository

```bash
git clone https://github.com/IsacFreitaas/ecommerce-business-analytics.git
cd ecommerce-business-analytics
```

## Create a Virtual Environment

On macOS or Linux:

```bash
python3 -m venv venv
source venv/bin/activate
```

On Windows PowerShell:

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

The virtual environment isolates this project's Python packages from the system interpreter.

## Install Dependencies

```bash
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

## Select the Python Interpreter in VS Code

1. Open the repository folder in VS Code.
2. Open the Command Palette with `Cmd+Shift+P` on macOS or `Ctrl+Shift+P` on Windows and Linux.
3. Select `Python: Select Interpreter`.
4. Choose the interpreter inside the project's `venv` directory.
5. Open the notebook and select the same environment as its kernel.

## Run the Data Validation

From the repository root, run:

```bash
venv/bin/python scripts/validate_data.py
```

On Windows PowerShell, use:

```powershell
.\venv\Scripts\python.exe scripts\validate_data.py
```

The validator checks processed file presence, schemas, key uniqueness, relationships, and financial formulas. Known data-quality limitations are reported as warnings.

Validate the metric definitions and their aggregation invariants:

```bash
venv/bin/python scripts/validate_metrics.py
```

## Load Data into PostgreSQL

Create the schema (tables and the `orders_analytical` view):

```bash
psql -d ecommerce_analytics -f sql/001_create_schema.sql
```

Load the processed datasets into the tables:

```bash
venv/bin/python scripts/load_to_postgres.py
```

The load script truncates existing rows before inserting, so it can be run again safely after the processed CSVs change.

Validate that PostgreSQL matches the processed CSVs:

```bash
venv/bin/python scripts/validate_postgres_data.py
```

This compares row counts per table, confirms the 30 documented unmatched customer orders, and cross-checks the `orders_analytical` view totals against the Pandas metric validation.

## Run the Notebooks

Execute the notebooks in this order:

1. `01_data_understanding.ipynb`
2. `02_data_cleaning.ipynb`
3. `03_exploratory_data_analysis.ipynb`

The first notebook examines the raw data. The second applies cleaning and transformation rules and generates the processed datasets. The third uses `orders_analytical.csv` for exploratory analysis.

Run all cells from top to bottom after restarting the kernel. This prevents hidden state from previous executions from affecting the results.

## Notebook Outputs and Git

Executing a notebook may modify its `.ipynb` file by saving:

- Cell execution counts.
- Tables and chart outputs.
- Kernel metadata.

Before committing, inspect the changes:

```bash
git status --short
git diff --stat
git diff --check
```

Keep outputs when they improve the portfolio presentation. Remove outputs when they are temporary or unnecessarily large. Never commit personal credentials or environment-specific secrets.

## Reproducibility Checks

After running the cleaning notebook:

```bash
venv/bin/python scripts/validate_data.py
```

The expected current dataset snapshot includes approximately 10,000 customers, 50,000 cleaned orders, 50,000 payments, and 20 products. Exact results should be checked through the validation output rather than assumed.

## Deactivate the Environment

When finished:

```bash
deactivate
```

## Troubleshooting

### `python` is not available

Use `python3` on macOS and Linux, or confirm that Python is installed and available on the Windows PATH.

### The notebook cannot find the data

Open the notebook from the repository workspace and run it from the project environment. The notebooks search for the repository root by locating the `data/raw` directory.

### VS Code uses the wrong environment

Run `Python: Select Interpreter` again and choose the interpreter under `venv`. Then select the matching Jupyter kernel.

### Git blocks a branch switch after notebook execution

The notebook has unsaved execution changes. Either save and commit the intended outputs, clean the outputs, or temporarily preserve them:

```bash
git stash push -m "temporary notebook execution state"
git switch main
```

Use `git stash pop` only when the saved changes are needed again.
