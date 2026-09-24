# Power BI Setup and Build Guide

## Purpose

Step-by-step instructions to build the report described in [`docs/powerbi_semantic_model.md`](powerbi_semantic_model.md), [`docs/powerbi_measures.md`](powerbi_measures.md), and [`docs/powerbi_dashboard_specification.md`](powerbi_dashboard_specification.md) in Power BI Desktop.

The `.pbix` report is built manually in Power BI Desktop from the versioned processed datasets and the specifications in this repository.

## 1. Install Power BI Desktop

1. Download Power BI Desktop from the Microsoft Store or from `https://www.microsoft.com/en-us/power-platform/products/power-bi/downloads`.
2. Install and open Power BI Desktop. A Microsoft account is not required to build and save a local report.

## 2. Locate the processed datasets

This build uses the processed CSV files committed under `data/processed/`. Using these files makes the report reproducible without requiring PostgreSQL or a live database connection.

1. Download or clone the repository.
2. Open the repository's `data/processed/` folder in File Explorer.
3. Use these four files as the Power BI sources: `customers_processed.csv`, `orders_processed.csv`, `payments_processed.csv`, and `products_processed.csv`.

Do not use `clean_final_data.csv`; it is an external reference file and is not part of the pipeline output.

## 3. Import the tables

1. `Home -> Get Data -> Text/CSV`.
2. Browse to `data/processed/` and select `customers_processed.csv`. Repeat `Get Data -> Text/CSV` for `orders_processed.csv`, `payments_processed.csv`, and `products_processed.csv`, one file at a time.
3. For each file, confirm the column data types Power Query auto-detects look correct (dates as `Date`, ids/quantities as whole numbers, prices/discounts as decimal numbers) before clicking `Load`. Fix any mismatched type in the Power Query column header dropdown if needed.
4. Do **not** import `clean_final_data.csv` (it is an external reference file, not part of the pipeline output; see `docs/powerbi_semantic_model.md`).
5. Click `Transform Data` instead of `Load` directly, to open Power Query and rename the tables before the model is built.

## 4. Rename tables and columns in Power Query

The processed CSV headers use compact export names, while the semantic model and DAX use the documented lowercase `snake_case` names. Apply this mapping in Power Query (`Home -> Transform Data`) before clicking `Close & Apply`.

1. Rename the queries: `customers_processed` -> `Customers`, `orders_processed` -> `Orders`, `payments_processed` -> `Payments`, `products_processed` -> `Products` (right-click each query in the left panel -> `Rename`).
2. In `Customers`, rename `CustomerID` -> `customer_id`, `Age` -> `age`, `City` -> `city`, `SignupDate` -> `signup_date`, and `CustomerSegment` -> `customer_segment`.
3. In `Orders`, rename `OrderID` -> `order_id`, `CustomerID` -> `customer_id`, `OrderDate` -> `order_date`, `ProductID` -> `product_id`, `Quantity` -> `quantity`, `Discount` -> `discount`, `PaymentMethod` -> `payment_method`, `Status` -> `status`, `OrderYear` -> `order_year`, `OrderMonth` -> `order_month`, and `OrderMonthName` -> `order_month_name`.
4. In `Payments`, rename `PaymentID` -> `payment_id`, `OrderID` -> `order_id`, `PaymentDate` -> `payment_date`, and `PaymentStatus` -> `payment_status`.
5. In `Products`, rename `ProductID` -> `product_id`, `ProductName` -> `product_name`, `Category` -> `category`, and `UnitPrice` -> `unit_price`.
6. Confirm these data types before loading: IDs and quantities as `Whole number`; `age` as `Whole number`; `discount` and `unit_price` as `Decimal number`; `order_date`, `signup_date`, and `payment_date` as `Date`; and year/month helper fields as `Whole number` or `Text` according to their names.
7. Click `Close & Apply`.

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
