# Power BI Dashboard Specification

## Purpose

This document defines the dashboard pages, visuals, and filters for the Power BI report. Every visual must connect to a business question from [`docs/business_questions.md`](business_questions.md) and use only measures defined in [`docs/powerbi_measures.md`](powerbi_measures.md). This satisfies the Issue #11 acceptance criteria: dashboard pages have a clear business purpose, filters do not produce contradictory results, and main visuals connect to documented business questions.

## Global Filters

Add these slicers to every page (as a synced slicer panel, `View -> Sync slicers`), so filter state is consistent across pages and cannot silently contradict itself:

- `Calendar[Year]` and `Calendar[Month Name]` (time filter).
- `Orders[status]` (order status filter), defaulted to all statuses selected.
- `Products[category]` (category filter).

Do not add a `Customers[customer_segment]` slicer synced globally: the Data Quality page must always show the unmatched-customer count regardless of segment filter, so segment filtering is scoped locally to the Customer Analysis page only.

## Page 1: Sales Performance

**Business questions covered:** Q1, Q2, Q3.

| Visual | Type | Fields | Question |
| --- | --- | --- | --- |
| KPI cards | Card (x4) | `[Distinct Orders]`, `[Units Sold]`, `[Net Order Value]`, `[Average Order Value]` | Q1 |
| Sales trend | Line chart | Axis: `Calendar[Year-Month]`; Values: `[Net Order Value]`, `[Distinct Orders]` (secondary axis) | Q2 |
| AOV trend | Line chart | Axis: `Calendar[Year-Month]`; Values: `[Average Order Value]` | Q2 |
| Ranked months | Table | `Calendar[Year-Month]`, `[Net Order Value]`, `[Sales Share by Period]`, `[Order Share by Period]`, `[Month Sales Rank]`, sorted by `[Month Sales Rank]` | Q3 |

**Filters:** Global filters only. `[Month Sales Rank]` must be computed with `ALL(Calendar)` (already defined in the measure) so that selecting a single year does not silently change the ranking basis without indication; add a page-level note text box stating "Ranks are calculated across the full loaded period."

## Page 2: Product Performance

**Business questions covered:** Q4, Q5, Q6.

| Visual | Type | Fields | Question |
| --- | --- | --- | --- |
| Category contribution | Bar chart | Axis: `Products[category]`; Values: `[Net Order Value]`; sorted descending | Q4 |
| Product ranking table | Table | `Products[product_name]`, `Products[category]`, `[Net Order Value]`, `[Units Sold]`, `[Product Sales Rank]`, `[Product Units Rank]`, `[Product Rank Difference]` | Q4, Q5 |
| Volume vs. value | Scatter chart | X: `[Units Sold]`; Y: `[Net Order Value]`; Details: `Products[product_name]`; Legend: `Products[category]` | Q5 |
| Discount band comparison | Clustered bar chart | Axis: `Orders[Discount Band]`; Values: `[Net Order Value]`, `[Average Order Value]` | Q6 |
| Discount scatter | Scatter chart | X: `Orders[discount]`; Y: `Orders[Order Value]` (binned) | Q6 |

**Filters:** Global filters, plus a local `Products[product_name]` search slicer on the ranking table only.

## Page 3: Customer Analysis

**Business questions covered:** Q7, Q8, Q9.

| Visual | Type | Fields | Question |
| --- | --- | --- | --- |
| KPI cards | Card (x4) | `[Purchasing Customers]`, `[Repeat Customers]`, `[Repeat Customer Rate]`, `[Top 10 Customers Sales Share]` | Q7 |
| Customer type comparison | Clustered bar chart | Axis: `Customers[Customer Type]`; Values: `[Customer Distinct Orders]` (as a customer-level average), `[Net Order Value]` | Q8 |
| Segment performance | Bar chart | Axis: `Customers[customer_segment]`; Values: `[Net Order Value]`; Secondary: sales share | Q9 |
| Top 10 cities | Table | `Customers[city]`, `[Net Order Value]`, `DISTINCTCOUNT(Customers[customer_id])`, sorted descending, top N filter = 10 | Q9 |

**Filters:** Global filters, plus a page-local `Customers[customer_segment]` slicer (not synced globally, see "Global Filters"). Add a page note: "Customer visuals exclude the orders with no matching customer record; see the Data Quality page for that count."

## Page 4: Operations and Payments

**Business questions covered:** Q10, Q11, Q12.

| Visual | Type | Fields | Question |
| --- | --- | --- | --- |
| Status distribution | Donut chart | Legend: `Orders[status]`; Values: `[Distinct Orders]` | Q10 |
| Cancellation/return KPIs | Card (x2) | `[Cancellation Rate]`, `[Returned Status Share]` | Q10 |
| Payment method comparison | Bar chart | Axis: `Orders[payment_method]`; Values: `[Distinct Orders]`, `[Cancellation Rate]` | Q11 |
| Reconciliation KPIs | Card (x3) | `[Payment Coverage]`, `[Unmatched Payments]`, `[Orders Without Payment]` | Q12 |
| Payment status distribution | Bar chart | Axis: `Payments[payment_status]`; Values: `[Payment Status Share]` | Q12 |

**Filters:** Global filters apply to status and payment-method visuals. The reconciliation KPIs (`[Unmatched Payments]`, `[Orders Without Payment]`) must **not** be filtered by `Orders[status]`, since reconciliation is a data-quality check independent of order outcome; place them visually separated from the status-filtered visuals and add a note text box: "Reconciliation KPIs always reflect the full dataset."

## Page 5: Data Quality

**Business purpose:** Make every documented data-quality exception visible instead of silently excluded, consistent with the project's cleaning principle in `docs/data_dictionary.md`.

| Visual | Type | Fields | Source of truth |
| --- | --- | --- | --- |
| Unmatched customer orders | Card | `[Unmatched Customer Orders]` (expected: 30) | `docs/data_dictionary.md`, "Referential Integrity Decisions" |
| Excluded financial rows | Card | `COUNTROWS(Orders) - [Distinct Orders]` filtered to blank `Order Value` | `docs/analytical_metrics.md`, "Financial Scope" |
| Missing order date | Card | `COUNTROWS(FILTER(Orders, ISBLANK(Orders[order_date])))` | `docs/analytical_metrics.md`, "Dated Sales Scope" |
| Payment reconciliation | Reuse from Page 4 | `[Unmatched Payments]`, `[Orders Without Payment]` | Q12 |

This page has no slicers besides the global time filter, so counts are comparable to the documented totals in `docs/data_dictionary.md` and `scripts/validate_metrics.py` output.

## Contradiction-Avoidance Rules

To satisfy "filters do not produce contradictory results":

1. Every ranking measure (`Month Sales Rank`, `Product Sales Rank`, `Product Units Rank`) uses `ALL()` over its own dimension, so a rank number never changes meaning based on unrelated slicers (category, status) without being explicitly recalculated for that scope.
2. Reconciliation and data-quality measures are never filtered by `Orders[status]` or `Products[category]`, and this is documented directly on the relevant pages via note text boxes.
3. `[Purchasing Customers]` and `[Repeat Customer Rate]` always use the full operational scope filter (`TREATAS` against `Customers`), so switching category or status filters cannot silently make an order count a "customer," and vice versa.
4. No page mixes `Gross Sales` and `Net Order Value` in the same chart without both being labeled explicitly in the legend, since gross and net values must never be visually implied as the same metric.

## Screenshot Checklist for Final Documentation

Once the report is built, capture one screenshot per page for [`docs/business_questions.md`](business_questions.md) cross-referencing and for the final portfolio documentation (Issue #13):

- [ ] Sales Performance
- [ ] Product Performance
- [ ] Customer Analysis
- [ ] Operations and Payments
- [ ] Data Quality

## TODO

- Confirm final color palette and page theme once the report is built (deferred to implementation, not part of the specification).
- Add a bookmark-based "Executive Summary" landing page once all five pages are validated, if time allows.
