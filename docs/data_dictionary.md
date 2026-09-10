# Data Dictionary

## Overview

This document describes the structure, meaning, and role of the datasets used in the e-commerce business analytics project.

The project contains four main datasets:

- `Customers`: customer-level information.
- `Orders`: transaction-level information.
- `Payments`: payment records associated with orders.
- `Products`: product-level information.

The processed `Orders` dataset also contains product attributes and derived temporal and financial variables created during the data cleaning and transformation stage.

## Customers

The `Customers` dataset contains one record per customer and provides demographic, geographic, and segmentation information.

| Column | Description | Data Type |
| --- | --- | --- |
| `CustomerID` | Unique identifier of the customer. | Integer |
| `Age` | Age of the customer. | Numeric |
| `City` | City associated with the customer. | String |
| `SignupDate` | Date when the customer registered. | Datetime |
| `CustomerSegment` | Customer segment classification. | String |

## Orders

The `Orders` dataset contains one record per order and represents the main transaction-level dataset used in the project.

### Original Variables

| Column | Description | Data Type |
| --- | --- | --- |
| `OrderID` | Unique identifier of the order. | Integer |
| `CustomerID` | Identifier of the customer associated with the order. | Integer |
| `OrderDate` | Date when the order was placed. | Datetime |
| `ProductID` | Identifier of the product associated with the order. | Integer |
| `Quantity` | Number of units purchased. | Numeric |
| `Discount` | Discount applied to the order, represented as a decimal proportion. | Numeric |
| `PaymentMethod` | Payment method associated with the order. | String |
| `Status` | Current status of the order. | String |

### Derived Variables

| Column | Description | Data Type |
| --- | --- | --- |
| `OrderYear` | Year extracted from `OrderDate`. | Integer |
| `OrderMonth` | Month number extracted from `OrderDate`. | Integer |
| `OrderMonthName` | Month name extracted from `OrderDate`. | String |
| `ProductName` | Name of the product associated with the order. | String |
| `Category` | Product category associated with the order. | String |
| `UnitPrice` | Unit price of the product at the transaction level. | Numeric |
| `GrossAmount` | Total order value before applying the discount. | Numeric |
| `DiscountAmount` | Monetary value of the discount. | Numeric |
| `NetAmount` | Order value after applying the discount. | Numeric |

* `Discount` is represented as a decimal proportion. For example, `0.10` represents a 10% discount.

## Payments

The `Payments` dataset contains payment records associated with orders.

| Column | Description | Data Type |
| --- | --- | --- |
| `PaymentID` | Unique identifier of the payment record. | Integer |
| `OrderID` | Identifier of the order associated with the payment. | Integer |
| `PaymentDate` | Date when the payment was recorded. | Datetime |
| `PaymentStatus` | Status of the payment. | String |

* The `Payments` dataset does not contain a monetary amount. Financial transaction values are calculated from `Quantity`, `UnitPrice`, and `Discount` in the processed `Orders` dataset.

## Products

The `Products` dataset contains one record per product and provides product-level information.

| Column | Description | Data Type |
| --- | --- | --- |
| `ProductID` | Unique identifier of the product. | Integer |
| `ProductName` | Name of the product. | String |
| `Category` | Product category. | String |
| `UnitPrice` | Price of one unit of the product. | Numeric |

## Dataset Relationships

The datasets are connected through the following identifiers:

| Relationship | Key | Description |
| --- | --- | --- |
| Customers → Orders | `CustomerID` | A customer can be associated with multiple orders. |
| Products → Orders | `ProductID` | A product can be associated with multiple orders. |
| Orders → Payments | `OrderID` | An order can be associated with a payment record. |

The `Orders` dataset serves as the central transaction-level dataset, connecting customer, product, order, and payment-related information through their respective identifiers.

The processed `Orders` dataset also contains product attributes and transaction-level derived variables, making it suitable for subsequent exploratory and business analysis.