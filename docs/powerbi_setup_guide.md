# Power BI Setup and Build Guide

## Purpose

Step-by-step instructions to build the report described in [`docs/powerbi_semantic_model.md`](powerbi_semantic_model.md), [`docs/powerbi_measures.md`](powerbi_measures.md), and [`docs/powerbi_dashboard_specification.md`](powerbi_dashboard_specification.md), for a first-time Power BI user running Windows through Parallels Desktop on macOS.

This project cannot generate the `.pbix` file directly: it is a binary format, not a text file, so it must be built manually inside Power BI Desktop following this guide.

## 1. Install Power BI Desktop (inside the Windows VM)

1. Start the Windows virtual machine in Parallels Desktop.
2. Open the Microsoft Store inside Windows and search for "Power BI Desktop", or download it from `https://www.microsoft.com/en-us/power-platform/products/power-bi/downloads`.
3. Install and open Power BI Desktop. Close the initial sign-in prompt if it appears; a Microsoft account is not required to build a local report.

## 2. Make PostgreSQL reachable from the Windows VM

The PostgreSQL database currently runs on macOS (the Parallels host), not inside the Windows VM. Two options:

**Option A (recommended): Shared network access**

1. In Parallels, confirm the VM's network mode is `Shared Network` (default). This lets Windows reach the Mac host.
2. On macOS, confirm PostgreSQL is listening for connections, not just local sockets. Check `postgresql.conf` (`brew --prefix postgresql@16` to find the path) for `listen_addresses = 'localhost'` and confirm `pg_hba.conf` allows connections from the Parallels virtual network range.
3. From Windows, use the Mac host's IP address as seen from the VM (in Windows, `ipconfig` and look at the default gateway, which is usually the Mac host) instead of `localhost`.

**Option B (simpler for a first attempt): Export a snapshot**

If configuring cross-VM PostgreSQL access is too much friction for a first Power BI session, use the processed CSVs instead:

1. Use `data/processed/orders_processed.csv`, `customers_processed.csv`, `products_processed.csv`, `payments_processed.csv` as the Power BI source (`Get Data -> Text/CSV`) instead of `Get Data -> PostgreSQL database`.
2. Share the folder from macOS to the Windows VM (Parallels does this automatically for `/Users/<you>` under `Z:\` or a similar mapped drive by default).
3. Document in the report which source was used; this project treats PostgreSQL as the primary source and CSV as the documented fallback (see `docs/powerbi_semantic_model.md`).

Tell me which option you want to use, and I will give you the exact connection dialog values.

## 3. Import the tables

1. `Home -> Get Data -> PostgreSQL database` (or `Text/CSV` if using Option B).
2. If using PostgreSQL: enter the server address and database name `ecommerce_analytics`; choose `Import` mode (not `DirectQuery`) when prompted.
3. Select these four tables only: `customers`, `orders`, `payments`, `products`. Do **not** import `orders_analytical` (see `docs/powerbi_semantic_model.md` for why).
4. Click `Transform Data` before loading, to open Power Query.

## 4. Rename tables in Power Query

Power BI report visuals read better with capitalized names. In Power Query (`Home -> Transform Data`):

1. Rename `customers` -> `Customers`, `orders` -> `Orders`, `payments` -> `Payments`, `products` -> `Products` (right-click each query in the left panel -> `Rename`).
2. Do not rename individual columns; keep the lowercase `snake_case` column names (`customer_id`, `order_date`, etc.) so they match the DAX formulas in `docs/powerbi_measures.md` exactly.
3. Click `Close & Apply`.

## 5. Build the relationships

1. Go to the `Model` view (left sidebar icon that looks like connected boxes).
2. Drag `Products[product_id]` onto `Orders[product_id]`.
3. Drag `Customers[customer_id]` onto `Orders[customer_id]`.
4. Drag `Orders[order_id]` onto `Payments[order_id]`.
5. Double-click each new relationship line and confirm cardinality is `One to many` and cross-filter direction is `Single`, matching the table in `docs/powerbi_semantic_model.md`.

## 6. Create the Calendar table

1. `Modeling -> New table`, paste the `Calendar` DAX formula from `docs/powerbi_semantic_model.md`.
2. Add the four calculated columns (`Year`, `Month Number`, `Month Name`, `Year-Month`) using `Modeling -> New column` while the `Calendar` table is selected.
3. Right-click `Calendar` -> `Mark as date table`, select the `Date` column.
4. In `Model` view, drag `Calendar[Date]` onto `Orders[order_date]`. Confirm cardinality `One to many`, direction `Single`.

## 7. Add calculated columns and the measure table

1. Select `Orders` table, `Modeling -> New column`, paste `Sales` and `Order Value` from `docs/powerbi_measures.md`.
2. Select `Orders` table again, add the `Discount Band` calculated column.
3. Select `Customers` table, add the `Customer Type` calculated column (uses the `Customer Distinct Orders` measure, so create the measures first, then come back for this column).
4. `Home -> Enter Data`, create an empty table named `_Measures` with one throwaway column, load it, then delete that column afterward (this is the standard Power BI pattern for a measure-only table).
5. Select `_Measures`, and for each formula in `docs/powerbi_measures.md`, use `Modeling -> New Measure`, paste the DAX, and press Enter.

## 8. Validate the model

Follow the "Model Validation Checklist" in `docs/powerbi_semantic_model.md` and the "Validation Rules" in `docs/powerbi_measures.md`:

1. Add a blank card visual with `[Distinct Orders]`, no filters: expect `50000`.
2. Add a card with `[Unmatched Customer Orders]`: expect `30`.
3. Add a card with `[Net Order Value]`: expect `3480613.75`.
4. Add a card with `[Purchasing Customers]`: expect `9939`.

If any of these do not match, stop and check the relationship cardinality and the calculated-column formulas before building any dashboard page.

## 9. Build the dashboard pages

Follow `docs/powerbi_dashboard_specification.md` page by page (Sales Performance, Product Performance, Customer Analysis, Operations and Payments, Data Quality), adding one page at a time and validating the numbers against the "Validation Rules" after each page.

## 10. Save the file

1. `File -> Save As`, save as `powerbi/ecommerce_business_analytics.pbix` inside the repository (create the `powerbi/` folder first).
2. This binary file should be committed to Git as-is; it cannot be reviewed as a text diff, so keep commit messages descriptive about what changed inside the report.

## When You Get Stuck

If a step does not match what you see in Power BI Desktop (menu names differ slightly across versions), tell me exactly what you see and I will adjust the instructions for your version.

## TODO

- Add instructions for publishing to Power BI Service if online sharing is needed later.
- Add a troubleshooting section once the report has been built at least once, documenting any real issue encountered.
