# Module: 4

### Intro to Data Modeling

- The Kimball methodology: "Dimensional Modeling" approach designed for business understanding and query performance.
- Fact tables:
    - Represent business processes or events (e.g., a taxi ride, a sale).
    - Contain quantitative metrics (measures) and foreign keys to dimension tables.
    - Think of these as the "Verbs".
- Dimension tables:
    - Provide context to the facts (e.g., customer details, location, time).
    - Contain descriptive attributes.
    - Think of these as the "Nouns".
- dbt workflow
    - **Version Control:** Everything is managed via Git.
    - **Testing:** Ensures data quality by checking for nulls, unique values, or accepted values before the data reaches the final user.
    - **Documentation:** Automatically generates documentation from the code, providing a "data lineage" (the path from raw data to final report).

### dbt Core

- The `profiles.yml` File (Critical)
    - Purpose: Unlike dbt Cloud which uses a UI, dbt Core uses a `profiles.yml` file (usually located in your `~/.dbt/` folder) to store database credentials.
    - Security: This file is kept outside of your project folder to prevent sensitive credentials (passwords, hosts) from being committed to Git.
    - Targets: You can define multiple "targets" (e.g., `dev` and `prod`) within the profile to switch between different database environments.
- The Configuration: `dbt_project.yml`
    - The Brain: This is the most important file in the project. It tells dbt where to look for models and how to build them.
    - Project Metadata: Contains the project name, version, and the profile it should use to connect to the database.
    - Model Configurations: You can define materializations here (e.g., whether a folder of SQL files should be built as `tables`, `views`, or `incremental` models).
- Core Development Folders
    - `models/`: The primary workspace. This is where you write the `.sql` files that define your data transformations.
    - `seeds/`: Used for static data (CSV files) that doesn't change often, such as country codes or taxi zone lookups. You can load these into your database using the `dbt seed` command.
    - `snapshots/`: Contains files to handle Slowly Changing Dimensions (SCD Type 2). This allows you to track how data changes over time (e.g., if a customer changes their address).
- Reusability and Logic
    - `macros/`: Stores reusable SQL snippets and logic, similar to functions in programming. These use Jinja (a templating language) to perform tasks like generating custom schemas or complex calculations across multiple models.
    - `analysis/`: A place for "analytical" SQL queries that you want to version control but do not want dbt to materialize as tables or views in the warehouse.
- Quality Control and Documentation
    - `tests/`: Contains SQL queries used to validate your data. If a test query returns a result, the test fails (e.g., checking that a `trip_id` is never null).
    - `target/`: (Generated automatically) This folder contains the "compiled" SQL. dbt takes your Jinja/SQL code and turns it into the raw SQL that BigQuery or Postgres actually executes. Note: This folder should usually be ignored by Git.
- Deployment and Dependencies
    - `packages.yml`: (Optional, but common) Used to install dbt "libraries" (like `dbt_utils`) created by the community to perform common data tasks without writing code from scratch.
    - `dbt_packages/`: Where the external code from your `packages.yml` is stored once downloaded.

### dbt Sources

- Defining Sources (`sources.yml`)
    - **Purpose:** Acts as a configuration layer that maps dbt to your raw data.
    - **Structure:** Requires `version: 2` and a `sources:` list.
    - **Matching:** The `database`, `schema`, and `tables` names must **exactly** match your warehouse (BigQuery Project ID/Dataset or DuckDB/Postgres names).
    - **The `source()` Function:** Use `{{ source('source_name', 'table_name') }}` in SQL files instead of hard-coding table names. This enables **data lineage** and environment switching.
- The Staging Layer (`stg_`)
    - **Convention:** Files should be stored in `models/staging/` and prefixed with `stg_`.
    - **Goal:** Create a "clean" version of raw data. It should stay as close to a **1:1 copy** as possible while standardizing the format.
- Essential Staging Transformations
    - **Explicit Selection:** List every column individually (avoid `SELECT *`).
    - **Renaming (Aliasing):** Convert cryptic source names to clear, consistent names (e.g., `tpep_pickup_datetime` → `pickup_datetime`).
    - **Type Casting:** Use `CAST(col AS type)` to ensure timestamps, integers, and numerics are correctly defined for downstream math.
    - **Column Grouping:** Organize SQL by grouping Identifiers, Timestamps, and Measures for readability.
- Workflow Command
    - **`dbt preview`:** Essential for testing your `source()` references and casts before running the full model.

### dbt Models

- **Data Exploration:** Successful analytics engineering requires exhaustive querying to identify data quality issues, normal trends, and the "why" behind exceptions.
- **Business Context:** You must understand the real-world meaning of the data (e.g., Green taxis serve NYC outskirts, while Yellow taxis serve the city center) to accurately encode business logic into SQL.
- **Fact Tables (`fact_`):** These represent business processes with one row per event (e.g., a trip or a sale).
- **Dimension Tables (`dim_`):** These represent business entities and their attributes (e.g., vendors or locations).
- **Star Schema:** A well-modeled dimensional structure should make complex questions simple enough to answer with a basic `COUNT` or `SUM`.
- **The `ref()` Function:** Use `{{ ref('model_name') }}` to reference other dbt models; this is distinct from `{{ source() }}`, which is strictly for raw data.
- **Intermediate Layer (`int_`):** Use this layer for "behind-the-scenes" transformations, such as joining or unioning models, before they reach the final Mart layer.
- **Handling Schema Mismatches:** When unioning different datasets (like Green and Yellow taxi data), you must manually create missing columns in the SQL to ensure both sets have the same number and type of columns.
- **Placeholder Strategy:** Create simple `SELECT 1` placeholder files to map out your project architecture before writing complex transformation logic.
- **Encoding Rules:** Use the transformation layer to standardize discrepancies, such as hard-coding a "Street Hail" trip type for Yellow taxis because it is legally the only way they can be hailed.

### dbt Seeds & Macros

- **Vendor and Location Data:** Raw taxi data often contains cryptic codes (e.g., Vendor ID 1, 2, 4 or Location IDs 1–265) that require enrichment with human-readable names and attributes to be useful for analysis.
- **dbt Seeds:** This feature allows you to load static CSV files (like a taxi zone lookup) into the data warehouse by placing them in the `seeds/` folder and running `dbt seed`.
- **Seed Use Cases:** Seeds are ideal for small lookup tables but should not be used for large datasets or sensitive/confidential information since they are committed to version control (Git).
- **Referencing Seeds:** Once seeded, these files are accessible in your models using the `{{ ref('seed_name') }}` function, treating the CSV as a table.
- **dbt Macros:** Macros are reusable snippets of SQL code that act like functions. They allow you to define logic once (e.g., a `CASE WHEN` statement for vendor names) and call it in multiple models.
- **Macro Syntax:** Macros are written in `.sql` files within the `macros/` directory using Jinja syntax, starting with `{% macro %}` and ending with `{% endmacro %}`.
- **DRY Principle:** Macros help keep your code "Don't Repeat Yourself" compliant; updating a single macro automatically updates all models that reference it, ensuring consistency across the project.
- **Compiled SQL:** While you write the macro call in your model, dbt compiles it into raw SQL at execution time, which can be verified in the dbt target folder or Cloud IDE.
- **Dimension Table Enrichment:** Using seeds and macros enables the creation of polished dimension tables (like `dim_zones` or `dim_vendors`) that provide the "nouns" and context for the central fact tables.
- **Fact Table Complexity:** Building `fact_trips` involves unioning datasets, handling duplicates in the source data, and ensuring a unique primary key exists for every row.

### Documentation

- **Documentation via YAML:** dbt uses `.yml` files to store metadata and descriptions for sources, models, seeds, and macros. While often named `schema.yml`, you can use custom names to keep files organized and manageable.
- **Granular Descriptions:** You can add descriptions at the project, table, or individual column level to provide context for business stakeholders and technical teams.
- **YAML Pipe Operator (`|`):** Use the pipe character in YAML to create multi-line descriptions, which is useful for long definitions or complex business logic explanations.
- **Metadata Tags (`meta`):** The `meta` key allows you to attach custom properties to columns, such as flagging PII (Personally Identifiable Information), identifying data owners, or setting data importance levels.
- **Documentation as Collaboration:** Writing documentation is ideally a collaborative process with business stakeholders to ensure technical definitions match real-world business rules.
- **`dbt docs generate`:** This command parses your project to create a `catalog.json` file, which is a machine-readable representation of your entire data pipeline, including lineage and descriptions.
- **`dbt docs serve`:** For dbt Core users, this command hosts a local web server (typically at `localhost:8080`) to visualize the documentation; dbt Cloud handles this hosting automatically.
- **Compiled vs. Source Code:** The documentation site allows users to toggle between the Jinja-templated source code and the "Compiled SQL" that is actually executed in the data warehouse.
- **Lineage Graph:** A visual map of your data flow that shows how sources transform into staging models and eventually into final marts.
- **Impact Analysis:** The lineage graph is a critical tool for identifying downstream dependencies, helping developers understand which reports or models will break if a specific table is changed.

### dbt Tests

- **Accountability in Data:** Data errors stem from either poor underlying data (quality issues) or logic bugs in the transformation SQL (joins, filters, edge cases); as an analytics engineer, testing helps you proactively identify and fix both.
- **Singular Tests:** These are custom SQL queries stored in the `tests/` folder. A test is considered "failed" if the query returns one or more rows (e.g., checking if a column value exceeds a logical limit like 24 hours in a day).
- **Source Freshness Tests:** Configured in the `sources.yml` file, these monitor how recently your data was loaded by checking a specific timestamp field against defined warning and error thresholds (e.g., `warn_after: {count: 6, period: hour}`).
- **Generic Tests:** Built-in, reusable tests defined directly under column names in YAML files. dbt includes four standard types:
    - **`unique`:** Ensures no duplicate values exist.
    - **`not_null`:** Ensures every row has a value.
    - **`accepted_values`:** Validates that data matches a specific list (e.g., `['credit_card', 'cash']`).
    - **`relationships`:** Checks referential integrity by ensuring values in one model exist in another.
- **Custom Generic Tests:** You can create your own reusable tests by writing a SQL snippet with Jinja placeholders in a `macros/` or `tests/generic/` folder, allowing you to apply complex, proprietary logic across many columns.
- **Unit Tests (v1.8+):** These allow you to test specific logic (like complex regex or window functions) using static "fixtures" (mock input data) and expected outputs. This ensures your SQL logic is correct even before real-world data arrives.
- **Model Contracts:** By adding `contract: {enforced: true}` to a model’s configuration, dbt will strictly enforce that the generated table matches the exact data types and constraints defined in your YAML file.
- **Data Contracts:** Contracts facilitate a "negotiation" between data producers and consumers, ensuring that if an input dataset changes its schema or types, the pipeline fails immediately rather than passing "silent" errors to a dashboard.
- **Proactive Defense:** In a mature data environment, testing is the primary tool for detecting errors before they reach stakeholders, clearly distinguishing between infrastructure failures and logic errors.

### Packages

- **dbt Packages Overview:** Packages are essentially standalone dbt projects—containing their own models, macros, and tests—that you can import into your project to use like Python libraries.
- **dbt Hub:** The official registry ([hub.getdbt.com](https://hub.getdbt.com/)) for finding verified packages. While you can install packages directly from GitHub, Hub-verified packages are vetted for safety and quality.
- **Essential Package: dbt-utils:** The most widely used package; it provides "cross-database" macros for common SQL tasks (e.g., deduplication, pivoting, surrogate key generation), ensuring your code works on BigQuery, Snowflake, or Postgres without modification.
- **Productivity: Codegen:** A massive timesaver that automates the creation of `YAML` files from existing tables or generates boilerplate `SQL` (including CTEs) from `YAML` definitions.
- **Data Quality: dbt-expectations:** Inspired by the "Great Expectations" Python library, this package offers a comprehensive suite of pre-built tests (e.g., checking for regex matches, row count ranges, or consistent casing) that far exceed dbt’s standard four tests.
- **Refactoring: Audit Helper:** Useful for migration or refactoring projects; it allows you to compare two versions of a model to ensure that row counts, column values, and relationships remain identical.
- **Governance: Project Evaluator:** Automatically audits your dbt project against best practices and provides a score, helping you maintain high-quality code and proper project structure.
- **Installation via `packages.yml`:** To add a package, you must create a `packages.yml` file in your project root, list the package name and version, and then run the command `dbt deps`.
- **The `dbt_packages/` Directory:** Running `dbt deps` downloads the source code of your dependencies into this folder, making their macros and models globally accessible to your project.
- **Using Package Macros:** Once installed, you call package functions using the syntax `{{ dbt_utils.function_name(...) }}`. This is common for generating primary keys or complex mathematical transformations.

### dbt Commands

- Fundamental dbt Commands
    - **`dbt init`:** Initializes a new project by creating the standardized directory structure (models, seeds, tests, etc.). Run this only once at the start.
    - **`dbt debug`:** Validates your connection. It checks your `profiles.yml` to ensure dbt can successfully communicate with your data warehouse (e.g., BigQuery, DuckDB).
    - **`dbt deps`:** Short for "dependencies." It downloads and installs external libraries listed in your `packages.yml` file.
    - **`dbt compile`:** Translates Jinja-templated SQL into raw SQL. This is a "free" way (it doesn't run on the warehouse) to check for syntax or logic errors in your code.
    - **`dbt clean`:** Deletes the `target/` and `dbt_packages/` folders, ensuring your next build starts from a completely fresh state.
- Core Execution Workflow
    - **`dbt run`:** Executes your models and materializes them as tables or views in the warehouse.
    - **`dbt test`:** Runs all data tests (generic, singular, and unit tests) to ensure data integrity.
    - **`dbt build`:** The "super command." It combines **run + test + seed + snapshot** into one execution. It is smart enough to skip downstream models if an upstream dependency or test fails.
    - **`dbt retry`:** A massive time-saver for large projects. If a `dbt build` fails halfway through, `retry` picks up exactly where the error occurred, skipping everything that already succeeded.
- Essential Command Flags
    - **`s` or `-select`:** Limits the scope of your command.
        - `dbt run -s my_model`: Runs only that specific model.
        - `dbt run -s +my_model`: Runs the model **and all its upstream parents**.
        - `dbt run -s my_model+`: Runs the model **and all its downstream children**.
    - **`-full-refresh`:** Used primarily with incremental models. It forces dbt to drop the existing table and rebuild it from scratch rather than just appending new data.
    - **`t` or `-target`:** Switches environments. By default, dbt uses your `dev` profile. Use `dbt build -t prod` to point your transformations at the production database.
    - **`-fail-fast`:** Causes dbt to stop the entire execution the moment a single model or test fails, rather than continuing with unrelated models.
- Advanced State-Based Deployments
    - dbt generates "artifacts" (JSON files like `manifest.json`) in the `target/` folder after every run.
    - **`-state`:** By pointing dbt to a "state" file from a previous successful run, you can use the selection `dbt run -s state:modified`.
    - **Impact:** This allows dbt to identify and run **only the files that have changed** since the last deployment, dramatically reducing compute costs and execution time in large environments.