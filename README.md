
# 🚀 Azure SQL to ADLS Data Migration Pipeline

## 📌 Overview

This repository contains an **Azure Data Factory (ADF)** pipeline designed to migrate **Orders data from Azure SQL Database to Azure Data Lake Storage (ADLS)** in **Parquet format**.

The pipeline supports both:

- 🔄 **Incremental data loading using Change Data Capture (CDC)**
- 📅 **Backdated data extraction**
- 🔐 **Secure Azure SQL authentication using Azure Key Vault**
- 📊 **Pipeline execution and data movement logging**
- ❌ **Error handling and pipeline failure management**
- 📁 **Hierarchical file organization in ADLS**
- 📈 **Rows read and rows written tracking**

The solution is designed to provide a secure, reusable, and auditable data ingestion framework for moving transactional Orders data from Azure SQL into a data lake.

---

# 🏗️ Architecture

```text
                    ┌─────────────────────┐
                    │    Azure SQL DB     │
                    │      Orders         │
                    └──────────┬──────────┘
                               │
                               │
                     ┌─────────▼─────────┐
                     │  Azure Key Vault  │
                     │                   │
                     │ SQL Credentials   │
                     │ Secret            │
                     └─────────┬─────────┘
                               │
                         Secure Access
                               │
                    ┌──────────▼──────────┐
                    │   Azure Data        │
                    │     Factory         │
                    │                     │
                    │  CDC / Backdate     │
                    │  Processing         │
                    └──────────┬──────────┘
                               │
                       Copy Activity
                               │
                    Preserve Hierarchy
                               │
                    ┌──────────▼──────────┐
                    │       ADLS          │
                    │                     │
                    │  Orders / Data      │
                    │      *.parquet      │
                    └──────────┬──────────┘
                               │
                               │
                    ┌──────────▼──────────┐
                    │   Execution Logs    │
                    │                     │
                    │ Pipeline Name       │
                    │ Run ID              │
                    │ Trigger Time        │
                    │ Duration            │
                    │ Status              │
                    │ Rows Read           │
                    │ Rows Written        │
                    │ Errors              │
                    └─────────────────────┘
````

---

# 🔄 Pipeline Flow

The pipeline implements a controlled data movement and logging process.

### High-Level Flow

```text
CDC Lookup
     │
     ▼
Determine Total Records
     │
     ▼
Check New Records
     │
     ├────────────── TRUE ──────────────┐
     │                                  │
     │                           Copy SQL Data
     │                                  │
     │                           Update CDC
     │                                  │
     │                           Pass End Time
     │                                  │
     │                         Pipeline Success
     │
     │
     └────────────── FALSE ─────────────┐
                                        │
                                  Fail End Time
                                        │
                                  Fail Pipeline
```

---

# 🔄 Incremental Loading Using CDC

The pipeline supports **incremental data loading using Change Data Capture (CDC)**.

Instead of extracting the complete Orders table during every execution, the pipeline identifies the records that have changed since the previous successful execution.

### CDC Process

1. Retrieve the previous CDC/end-time information using a **Lookup activity**.
2. Determine whether new or changed records are available.
3. Calculate the total number of records to be processed.
4. If new records exist:

   * Copy the incremental data from Azure SQL.
   * Write the data to ADLS in Parquet format.
   * Update the CDC control information.
   * Capture the pipeline end time.
   * Mark the pipeline execution as successful.
5. If no new records exist:

   * Capture the pipeline end time.
   * Mark the pipeline execution appropriately based on the pipeline design.

This approach minimizes unnecessary data movement and improves pipeline efficiency.

---

# 📅 Backdated Data Loading

The pipeline also supports **backdated data extraction**.

A backdate can be supplied to retrieve historical Orders data for a specific period.

This is useful for:

* Initial historical loads
* Reprocessing missing data
* Data recovery
* Business-requested historical extracts
* Rebuilding downstream datasets

The same pipeline framework can therefore be used for both **historical loads and incremental loads**.

---

# 🔐 Azure Key Vault Integration

Sensitive Azure SQL credentials are not hardcoded inside the ADF pipeline.

The pipeline uses **Azure Key Vault (AKV)** to securely manage connection secrets.

### Security Flow

```text
Azure Data Factory
        │
        │ Managed Identity
        ▼
Azure Key Vault
        │
        │ Get Secret
        ▼
Azure SQL Database
```

An appropriate **Access Policy** is configured in Azure Key Vault to allow the ADF identity to:

* `Get` secrets
* `List` secrets

This allows ADF to securely retrieve the required Azure SQL credentials at runtime.

### Benefits

* 🔒 No credentials stored in pipeline code
* 🔑 Centralized secret management
* ♻️ Easy credential rotation
* 🛡️ Improved security
* 🚫 Reduced risk of exposing database credentials

---

# 📦 Data Movement

The source data is stored in:

**Azure SQL Database**

The destination is:

**Azure Data Lake Storage (ADLS)**

The data is written in:

**Parquet format**

```text
Azure SQL
    │
    │ Copy Activity
    ▼
ADLS
    │
    └── Orders
          └── *.parquet
```

---

# 📁 Copy Behavior

The Copy Activity uses:

```text
Copy behavior: Preserve hierarchy
```

This allows the directory structure from the source/file organization to be maintained when data is written to ADLS.

The destination files are automatically generated using the configured/default file naming behavior of the Copy Activity.

This provides a consistent and organized folder structure within ADLS.

---

# 📊 Pipeline Logging

The pipeline contains a logging mechanism to capture important execution and data movement information.

The logging framework records information such as:

| Log Information   | Description                                  |
| ----------------- | -------------------------------------------- |
| Pipeline Name     | Name of the executed ADF pipeline            |
| Pipeline Run ID   | Unique identifier for the pipeline execution |
| Trigger Time      | Time at which the pipeline was triggered     |
| Start Time        | Pipeline execution start time                |
| End Time          | Pipeline execution completion time           |
| Duration          | Total pipeline execution duration            |
| Status            | Success / Failure status                     |
| Rows Read         | Number of records read from Azure SQL        |
| Rows Written      | Number of records written to ADLS            |
| Error Information | Details associated with failed executions    |

This provides an auditable record of every pipeline execution.

---

# ❌ Error Handling

The pipeline includes explicit error-handling logic.

If the data movement or another critical pipeline activity fails:

```text
Pipeline Failure
       │
       ▼
Capture End Time
       │
       ▼
Log Failure Information
       │
       ▼
Fail Pipeline
```

This allows operational teams to identify:

* Which pipeline failed
* When it failed
* Which pipeline run was affected
* How long the execution ran
* Whether records were processed
* Error details associated with the failure

---

# 📈 Monitoring & Observability

The logging mechanism provides visibility into pipeline execution and data movement.

Example:

```text
Pipeline Name : PL_SQL_TO_ADLS_ORDERS
Run ID        : 8f3c1a2b-xxxx-xxxx-xxxx-xxxxxxxx
Trigger Time  : 2026-08-09 10:00:00
Start Time    : 2026-08-09 10:00:05
End Time      : 2026-08-09 10:02:18
Duration      : 00:02:13
Status        : SUCCESS
Rows Read     : 25,430
Rows Written  : 25,430
```

This information can be used for operational monitoring, troubleshooting, and audit purposes.

---

# 🧩 Azure Data Factory Activities

The pipeline uses multiple ADF activities to implement the complete workflow.

### 1. Lookup — CDC Lookup

Retrieves the required CDC/control information used to determine the data extraction window.

### 2. Script — Total Records

Calculates or determines the number of records available for processing.

### 3. If Condition — NewRecordsExists

Determines whether new records are available for ingestion.

### 4. Copy Data

When new records are available, data is copied from Azure SQL to ADLS in Parquet format.

### 5. Update CDC

Updates the CDC/control information after successful data movement.

### 6. Pass EndTime

Captures the pipeline completion time for successful processing.

### 7. Fail EndTime

Captures the completion time when the pipeline follows the failure path.

### 8. Fail Pipeline

Explicitly marks the pipeline execution as failed when required.

---

# 🛠️ Technology Stack

| Technology                       | Purpose                           |
| -------------------------------- | --------------------------------- |
| **Azure Data Factory**           | ETL / orchestration               |
| **Azure SQL Database**           | Source system                     |
| **Azure Data Lake Storage Gen2** | Target data lake                  |
| **Azure Key Vault**              | Secure credential management      |
| **Parquet**                      | Target data format                |
| **CDC**                          | Incremental data processing       |
| **ADF Copy Activity**            | Data movement                     |
| **ADF Lookup**                   | CDC/control information retrieval |
| **ADF Script Activity**          | Record processing logic           |
| **ADF If Condition**             | Conditional workflow execution    |

---

# 🔐 Security

The solution follows Azure security best practices by separating credentials from pipeline configuration.

### Implemented Security Practices

* Azure Key Vault for secret management
* ADF Managed Identity for authentication
* Key Vault Access Policy
* No hardcoded database passwords
* Secure retrieval of SQL credentials at runtime
* Controlled access to Key Vault secrets

---

# ⚡ Key Features

### 🔄 Incremental Processing

Uses CDC to process only new or changed Orders data.

### 📅 Backdated Processing

Allows historical data to be loaded for a specified backdate/time period.

### 🔐 Secure Authentication

Azure Key Vault is used to securely manage Azure SQL credentials.

### 📦 Parquet Data Lake Storage

Orders data is stored in an efficient columnar Parquet format.

### 📁 Hierarchical Storage

Copy Activity uses **Preserve hierarchy** behavior for organized ADLS storage.

### 📊 Execution Logging

Captures pipeline execution and data movement metrics.

### ❌ Failure Handling

Explicit failure paths capture execution information and fail the pipeline when required.

### 📈 Operational Monitoring

Pipeline Run ID, duration, status, rows read, rows written, trigger time, and other execution details are captured for monitoring.

---

# 🎯 Use Case

This pipeline can be used as a reusable ingestion framework for organizations that need to move transactional data from operational Azure SQL databases into a centralized data lake.

A typical downstream architecture could be:

```text
              Azure SQL
                  │
                  │
          Azure Data Factory
                  │
        ┌─────────┴─────────┐
        │                   │
   Initial Load          CDC Load
        │                   │
        └─────────┬─────────┘
                  │
                  ▼
                ADLS
                  │
             Parquet Files
                  │
                  ▼
          Data Engineering /
          Analytics Platform
```

---

# 📂 Repository Structure

```text
.
├── README.md
│
├── adf/
│   ├── pipeline/
│   ├── datasets/
│   ├── linkedServices/
│   └── triggers/
│
├── sql/
│   ├── tables/
│   ├── storedProcedures/
│   └── scripts/
│
├── key-vault/
│   └── configuration.md
│
└── documentation/
    └── architecture.md
```

> The exact folder structure may vary depending on how the ADF artifacts are exported from the Azure environment.

---

# 🚀 Pipeline Execution Scenarios

## Scenario 1 — New Records Available

```text
CDC Lookup
    ↓
Check Record Count
    ↓
New Records Exist
    ↓
Copy Azure SQL → ADLS
    ↓
Update CDC
    ↓
Capture End Time
    ↓
SUCCESS
```

## Scenario 2 — No New Records

```text
CDC Lookup
    ↓
Check Record Count
    ↓
No New Records
    ↓
Handle End Time
    ↓
Pipeline Completion
```

## Scenario 3 — Pipeline Failure

```text
Pipeline Activity
       ↓
     ERROR
       ↓
Capture End Time
       ↓
Log Failure
       ↓
FAIL PIPELINE
```

---

# 📌 Design Highlights

This project demonstrates practical Azure Data Engineering concepts including:

* Azure Data Factory orchestration
* Incremental data ingestion
* Change Data Capture (CDC)
* Backdated data processing
* Azure SQL integration
* Azure Data Lake Storage
* Parquet data processing
* Azure Key Vault integration
* Managed Identity
* Access Policy configuration
* Conditional pipeline execution
* Pipeline error handling
* Execution logging
* Data movement metrics
* Pipeline monitoring and observability

---

# 👨‍💻 Author

**Azure Data Engineering Project**

Built using **Azure Data Factory, Azure SQL Database, ADLS Gen2, Azure Key Vault, CDC and Parquet**.

```

### One thing I'd improve from your current description

For a GitHub portfolio, I would **not describe the pipeline simply as "copying data from SQL to ADLS."** The stronger story is:

> **A secure, metadata-driven Azure Data Factory ingestion pipeline supporting both backdated and CDC-based incremental loading, with Key Vault-based authentication, Parquet-based ADLS storage, hierarchical file organization, and end-to-end execution logging.**

That wording makes the project sound much closer to an **actual production Data Engineering implementation** rather than a basic ADF Copy Activity demo.
```
