# E-Commerce Business Analytics

## Project Overview

* This project focuses on transforming raw e-commerce data into meaningful business insights.

* The dataset contains information about customers, orders, products, and payments. The goal is to analyze the data, identify relevant patterns, and answer business questions related to sales performance, customer behavior, product performance, and payment operations.

* The project will follow an end-to-end data analytics workflow, covering data understanding, data quality assessment, data cleaning, data modeling, SQL analysis, exploratory data analysis, and business intelligence visualization.

## Business Problem

* E-commerce companies generate large amounts of operational data. However, having access to data alone is not enough to support decision-making.

* This project aims to explore how customer, order, product, and payment data can be transformed into actionable insights that support a better understanding of business performance.

## Project Objectives

The main objectives of this project are:

- Assess the quality and structure of the raw data.
- Clean and prepare the data for analysis.
- Model the data using a relational database.
- Answer business questions using SQL.
- Perform exploratory data analysis using Python.
- Create visualizations to communicate the main findings.
- Develop a business intelligence dashboard.

## Planned **Pipeline**

```text
Raw Data
    ↓
Data Understanding
    ↓
Data Quality Assessment
    ↓
Data Cleaning and Transformation
    ↓
Relational Database
    ↓
SQL Analysis
    ↓
Exploratory Data Analysis
    ↓
Business Intelligence Visualization
    ↓
Business Insights
```

```
                    ┌─────────────┐
                    │ RAW DATA    │
                    │ CSV FILES   │
                    └──────┬──────┘
                           │
                           ▼
                  ┌────────────────┐
                  │ DATA ANALYSIS  │
                  │ PYTHON         │
                  └───────┬────────┘
                          │
                          ▼
                  ┌────────────────┐
                  │ POSTGRESQL     │
                  │ DATA MODEL     │
                  └───────┬────────┘
                          │
                 ┌────────┴────────┐
                 ▼                 ▼
        ┌─────────────────┐  ┌─────────────┐
        │ SQL ANALYSIS    │  │ POWER BI    │
        │ BUSINESS QUERIES│  │ DASHBOARD   │
        └─────────────────┘  └─────────────┘
```

## **Technologies**
```
Python
├── Pandas / Polars
├── SQLAlchemy
├── Matplotlib
└── Jupyter NOtebook

PostgreSQL
├── Modelagem de dados
├── JOINs
├── CTEs
└── Consultas analíticas

Power BI
├── Modelagem
├── DAX
├── KPIs
└── Dashboard
```

## **Repository Structure**

```
ecommerce-business-analytics/
├── data/
│   ├── raw/                       # Original dataset files
│   │   ├── customers.csv
│   │   ├── orders.csv
│   │   ├── payments.csv
│   │   └── products.csv
│   └── processed/                 # Processed datasets
│       ├── clean_final_data.csv
│       ├── customers_processed.csv
│       ├── orders_processed.csv
│       ├── payments_processed.csv
│       └── products_processed.csv
├── docs/                          # Project documentation
│   ├── business_questions.md
│   └── data_dictionary.md
├── notebooks/                     # Data analysis notebooks
│   ├── 01_data_understanding.ipynb
│   └── 02_data_cleaning.ipynb
├── .gitattributes
├── .gitignore
├── README.md
└── requirements.txt
```

## **Dataset**

### The dataset contains four main tables:
* Customers
* Orders
* Payments
* Products

An additional processed dataset is also included for reference and validation purposes.

The raw data is preserved separately from processed data to ensure the original source remains unchanged throughout the project.

## **Project Status**
* 🚧 **In Progress**