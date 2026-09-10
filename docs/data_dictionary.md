# Data Dictionary

## Overview

This document describes the datasets used in the E-Commerce Business Analytics project.

## Customers

| Column | Description | Initial Data Type |
|---|---|---|
| CustomerID | Unique identifier for each customer. | Integer |
| Age | Age of the customer. | Numeric |
| City | City associated with the customer. | Categorical |
| SignupDate | Date when the customer registered. | Date |
| CustomerSegment | Customer classification or segment. | Categorical |

## Orders

| Column | Description | Initial Data Type |
|---|---|---|
| OrderID | Unique identifier associated with an order. | Integer |
| CustomerID | Identifier associated with the customer who placed the order. | Integer |
| OrderDate | Date when the order was placed. | Date |
| ProductID | Identifier associated with the ordered product. | Integer |
| Quantity | Number of units included in the order. | Numeric |
| Discount | Discount associated with the order. | Numeric |
| PaymentMethod | Payment method selected for the order. | Categorical |
| Status | Current status of the order. | Categorical |

## Payments

| Column | Description | Initial Data Type |
|---|---|---|
| PaymentID | Unique identifier for each payment record. | Integer |
| OrderID | Identifier associated with the related order. | Integer |
| PaymentDate | Date when the payment was processed. | Date |
| PaymentStatus | Status associated with the payment. | Categorical |

## Products

| Column | Description | Initial Data Type |
|---|---|---|
| ProductID | Unique identifier for each product. | Integer |
| ProductName | Name of the product. | Text |
| Category | Product category. | Categorical |
| UnitPrice | Price of a single unit of the product. | Numeric |

## Dataset Relationships