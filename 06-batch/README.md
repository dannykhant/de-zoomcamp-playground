# Module: 6

### Batch

- **Week focus: Batch Processing**
    - Main tool covered: **Spark** (primarily PySpark).
    - Topics:
        - What Spark is and why it’s needed.
        - Installation (Linux / GCP VM).
        - DataFrames, SQL, joins.
        - RDDs (Resilient Distributed Datasets) and internals.
        - Running Spark locally with Docker.
        - Deploying Spark to the cloud.
        - Connecting Spark to a data warehouse.
- **Batch vs Streaming**
    - **Batch**: process large chunks of accumulated data at fixed intervals.
        - Example: process all taxi trips for a full day in one job.
    - **Streaming**: process events in real time as they arrive.
        - Example: taxi ride event processed immediately.
    - This week = batch. Streaming covered separately.
- **Typical batch intervals**
    - Daily (most common)
    - Hourly
    - Weekly
    - Smaller intervals possible but less typical.
- **Common batch technologies**
    - Python scripts
    - SQL transformations
    - Spark
    - Others (e.g., Flink)
    - Orchestration tools like Apache Airflow manage workflows.
- **Typical batch workflow**
    - Data lake (e.g., CSV files)
    - Python job
    - SQL/dbt transformations
    - Spark job
    - Orchestrated via workflow manager
- **Advantages of batch**
    - Easy to manage and orchestrate.
    - Easy retries (safe, not real-time).
    - Easy to scale (bigger machine or cluster).
    - Operationally simpler than streaming.
    - Majority of industry workloads (~80–90%) are batch.
- **Disadvantage of batch**
    - Latency (data delay).
    - Must wait for interval to finish.
    - Pipeline execution adds additional delay.
    - Not suitable for real-time needs.

### Spark

- **Apache Spark = distributed data processing engine**
    - Engine = pulls data in, processes it, writes results out.
    - Designed for **large-scale data processing**.
    - Runs on a **cluster of machines** (distributed executors).
- **Multi-language support**
    - Native language: Scala (Spark written in Scala).
    - Common APIs:
        - PySpark (Python wrapper, very popular)
        - Java
        - R (less common)
    - In many companies, PySpark is the default for data engineers.
- **Primary use case**
    - Batch processing (focus here).
    - Can also handle streaming (not covered here).
- **Typical architecture**
    - Data stored in **data lake** (e.g., S3, GCS, Parquet files).
    - Spark:
        - Reads from lake
        - Processes data
        - Writes back to lake or warehouse
- **When to use Spark**
    - When working directly with files in a data lake.
    - When SQL is insufficient or too complex.
    - When logic requires:
        - Advanced transformations
        - Modular code
        - Unit testing
        - Machine learning workflows
- **Common ML workflow with Spark**
    - Raw data → data lake.
    - SQL transforms
    - Spark job for:
        - Complex feature engineering.
        - Training ML models.
    - Separate Spark job for:
        - Applying trained model.
    - Results written back to lake → warehouse.

### PySpark

- **PySpark entry point**
    - `SparkSession` = main interface to Spark (read/write, create DataFrames).
    - Spark Master UI runs on port **4040** → used to monitor jobs, stages, tasks.
- **Reading large CSV**
    - Loaded ~700MB NYC high-volume taxi dataset (~12M rows).
    - By default, Spark reads all columns as **string** unless schema is provided.
    - `df.schema` shows inferred types (all string if not specified).
- **Schema enforcement**
    - Use `pyspark.sql.types` (`StructType`, `StructField`, `IntegerType`, `TimestampType`, etc.).
    - Explicit schema:
        - Correct numeric types (e.g., use `IntegerType` instead of `LongType` to reduce memory).
        - Parse timestamps properly.
        - Define nullable fields.
    - Pass schema to `spark.read.csv(..., schema=schema)`.
- **Using Pandas for type inference (small sample only)**
    - Extract small subset of rows.
    - Use Pandas to inspect `dtypes`.
    - Manually translate to Spark schema.
    - Do NOT load large file fully into Pandas.
- **Partitions (core distributed concept)**
    - Partition ≈ unit of parallelism in Spark.
    - Executors process partitions in parallel.
    - If only one large file/partition → only one executor works → poor parallelism.
    - Multiple partitions → multiple executors work concurrently.
- **Repartitioning**
    - `df.repartition(n)` changes number of partitions.
    - It is **lazy** (no execution until action like `.write()`).
    - Repartitioning is expensive (causes shuffle).
- **Writing to Parquet**
    - `df.write.parquet(path)`
    - Writing triggers execution.
    - Output:
        - Multiple `part-xxxxx.snappy.parquet` files (one per partition).
        - `_SUCCESS` file indicates successful completion.
    - If path exists → error unless `mode("overwrite")`.
- **Execution model**
    - Spark operations are **lazy transformations**.
    - Actions (e.g., `show`, `write`) trigger jobs.
    - Jobs → stages → tasks (visible in Spark UI).
    - Repartition causes shuffle stage.
- **Parquet advantages**
    - Columnar format.
    - Compressed (e.g., Snappy).
    - Much smaller than CSV (~4× reduction in example).
    - Better for analytics workloads.

### Spark Dataframe

- **Spark DataFrame**
    - Main abstraction for structured data in Spark (`df`).
    - Similar to Pandas DataFrame, but distributed.
    - Backed by partitions across executors.
- **Reading Parquet**
    - `spark.read.parquet(path)`
    - Schema is stored in Parquet → no need to manually define it.
    - Parquet is:
        - Columnar
        - Schema-aware
        - More compressed and efficient than CSV
- **Basic DataFrame operations**
    - `select(columns)` → choose specific columns.
    - `filter(condition)` → filter rows.
    - `groupBy()` → aggregations (similar to SQL).
    - These resemble SQL operations.
- **Transformations vs Actions (core concept)**
    
    **Transformations (lazy):**
    
    - `select`
    - `filter`
    - `withColumn`
    - `groupBy`
    - `repartition`
    - They build a logical plan.
    - Not executed immediately.
    
    **Actions (trigger execution):**
    
    - `show`
    - `head`
    - `take`
    - `write.parquet`
    - These execute the entire transformation DAG.
    
    Mental model:
    
    ```
    df → select → filter → withColumn → ...
                                  ↓
                               action
                             (execution)
    ```
    
- **Spark SQL Functions**
    - Available via `pyspark.sql.functions` (commonly imported as `F`).
    - Large set of built-in functions.
    - Example: `to_date()` → extract date from timestamp.
    - Used inside `withColumn()` to create/modify columns.
    - If column name already exists → it gets overwritten.
- **withColumn**
    - `df.withColumn("new_col", expression)`
    - Adds or replaces a column.
    - Still a transformation (lazy).
- **User Defined Functions (UDFs)**
    
    Purpose:
    
    - Implement complex business logic not easily expressed in SQL.
    - Especially useful for ML-style or rule-heavy logic.
    
    Steps:
    
    1. Write normal Python function.
    2. Wrap with `F.udf(function, return_type)`.
    3. Use inside `withColumn()`.
    
    Characteristics:
    
    - Executed across distributed partitions.
    - Allows arbitrary Python logic.
    - Testable (unit tests, version control).
    - More flexible than SQL `CASE WHEN`.
- **Why DataFrame API over pure SQL?**
    - Supports:
        - Custom Python logic (UDFs).
        - Modular code.
        - Better testability.
        - Integration with ML workflows.
    - You can mix:
        - SQL for standard transformations.
        - DataFrame API + UDFs for complex logic.

### Spark SQL

- Create `SparkSession` to use Spark SQL
- Read Parquet files using `spark.read.parquet()`
    - Use `/` patterns for nested folders
- Inspect schema with `printSchema()`
- Access columns via `df.columns`
- Align schemas before union
    - Rename mismatched columns with `withColumnRenamed()`
    - Ensure same column order
    - Select common columns only
- Preserve column order manually (iterate + intersect)
- Add constant column using `withColumn()` + `lit()`
    - Used to label source (`service_type`)
- Combine datasets using `unionAll()`
- Spark transformations are lazy
    - Actions like `show()` trigger execution
- Use `groupBy().count()` for aggregation
- To run SQL on DataFrame:
    - Register temp table (`registerTempTable()` / temp view)
    - Use `spark.sql("SELECT ...")`
- SQL supports `GROUP BY`, `AVG`, aggregations, positional grouping
- Save results with `write.parquet(path)`
- Spark creates multiple partition files by default
- Use `coalesce(n)` to reduce number of output partitions
- Use `.mode("overwrite")` when path exists
- Spark UI shows stages, tasks, shuffles, execution plan
- Spark can execute SQL directly on data lake files (no data warehouse required)

### Anatomy of Spark Cluster

- `local[*]` → driver + executors run on single machine (dev mode).
- Real cluster → **Driver, Master, Executors** are separated roles.
- **Driver**
    - Creates SparkSession
    - Builds DAG
    - Submits job via `spark-submit`
    - Requests resources
- **Master (Cluster Manager)**
    - Allocates executors
    - Tracks health
    - Reassigns failed tasks
    - Coordinates cluster resources
- **Executors**
    - Run tasks
    - Process partitions
    - Perform transformations/actions
    - Read/write data
- DataFrame = collection of **partitions**
- Task = computation on **one partition**
- Parallelism = number of cores across executors
- Scheduler assigns partitions → tasks → executors
- If executor fails → tasks are rescheduled
- Old model: **HDFS** (data locality, move compute to data)
- Modern model: cloud object storage (S3/GCS), compute pulls data
- Spark cluster = compute layer
- Cloud storage = data lake
- Always reason in:
    
    **Partitions → Tasks → Executors → Stages**
    

### Spark GroupBy

- `groupBy` = **2-stage aggregation**
    - Stage 1: per-partition aggregation (local reduce)
    - Stage 2: global aggregation (after shuffle)
- **Stage 1 (Map-side aggregation)**
    - Filter applied first
    - Each executor processes one partition
    - Groups within partition only
    - Produces partial aggregates (subresults)
- **Shuffle (Exchange)**
    - Triggered between Stage 1 and Stage 2
    - Redistributes data by grouping key
    - All identical keys → same partition
    - Expensive (network + disk I/O)
- Implemented using:
    - **External Merge Sort**
    - Records sorted by key inside partitions
- **Stage 2 (Reduce-side aggregation)**
    - Combine partial aggregates
    - Final reduce per key
    - Output final grouped result
- `orderBy` adds:
    - Extra shuffle stage
    - Global sorting
- `repartition(n)`:
    - Changes number of output partitions
    - Causes another shuffle
    - Used to control output file size
- Shuffle metrics:
    - `shuffle read`
    - `shuffle write`
    - Minimize shuffle for performance
- Default shuffle partitions often = 200

---

**Mental Model**

`Filter → Local GroupBy → Shuffle → Global Reduce → (Optional Sort) → Write`

---

**Key Insight**

- `groupBy` = **partial aggregation + reshuffle + final aggregation**
- Shuffle is the most expensive part
- Always design pipelines to reduce shuffle volume

### Spark Joins

**Join Two Large Tables (Sort-Merge Join)**

- Default strategy for large-large joins
- Join keys → composite key (e.g., `hour`, `zone`)
- Add key to each record
- **Shuffle (Exchange)** by join key
- All same keys → same partition
- Inside partition → sort by key
- Perform merge to combine matching records
- Outer join → unmatched → `null`
- Inner join → drop unmatched
- Uses **Sort-Merge Join (External Merge Sort)**
- Expensive due to shuffle (network + disk I/O)
- Multi-stage job (groupBy stages + join stage)

---

**Join Large Table + Small Table (Broadcast Join)**

- If one table is small → **Broadcast Join**
- Small table sent to every executor
- No shuffle of large table
- Join done in-memory via lookup
- Single stage (no reshuffle stage)
- Much faster than sort-merge join
- Execution plan shows: `BroadcastExchange`

---

**Shuffle Insights**

- Shuffle = data redistribution by key
- Metrics: `shuffle read`, `shuffle write`
- Minimize shuffle for performance

---

**Materialization**

- Save intermediate results (Parquet)
- Avoid recomputing entire lineage
- Useful for reuse (dashboards, downstream jobs)

---

**Mental Model**

- Large + Large → `Shuffle → Sort → Merge`
- Large + Small → `Broadcast → In-memory lookup`
- Shuffle is the expensive villain
- Broadcast is the surgical strike

### Connection to GCS

- Continuing Spark series → focus shifts to **running Spark in the cloud** and with Docker.
- Section roadmap:
    - Connect Spark to **Google Cloud Storage (GCS)**
    - Create a **local Spark cluster**
    - Create a **data cluster on Google Cloud**
- Start with GCS integration (following Alvin’s guide).
- Workflow:
    - Duplicate existing Spark notebook (previously reading local `data/` folder).
    - Upload local Parquet (`pq`) folder to GCS bucket.
- Upload to GCS:
    - Use `gsutil cp -r -m`
        - `r` → recursive
        - `m` → parallel/multi-threaded upload
- To let Spark read from `gs://` paths:
    - Download **Cloud Storage Connector for Hadoop 3** (JAR file).
    - Ensure connector version matches Hadoop version used by Spark.
- Spark configuration changes:
    - Add connector JAR path in Spark config.
    - Provide Google credentials path (`GOOGLE_APPLICATION_CREDENTIALS`).
    - Create `SparkContext` first, then build `SparkSession` from it.
- Hadoop config setup:
    - Map `gs://` filesystem to GCS implementation class (from JAR).
    - Attach service account credentials.
- Validation:
    - Read from `gs://bucket/...`
    - Run simple actions (`show()`, `count()`) → confirms working connection.
- Key insight:
    - Local Spark requires manual connector + credential setup.
    - Managed Spark on GCP later won’t require this manual configuration.
- Next topic preview:
    - Create a **local standalone Spark cluster**.
    - Use `spark-submit` instead of running purely in local mode.

### Spark Submit

- Focus: **running Spark in the cloud**, but first prepare locally.
- Goals of this video:
    - Convert Jupyter notebook → Python script.
    - Use `spark-submit` to submit jobs.
    - Create a **local standalone Spark cluster**.
- Local mode recap:
    - `master("local")` auto-creates a Spark cluster inside notebook.
    - UI runs on `localhost:4040`.
    - Shutting down kernel stops the cluster.
- Create standalone cluster manually:
    - From `$SPARK_HOME/sbin/` → start **master**.
    - Spark master UI runs on port `8080`.
    - Connect notebook using master URL (`spark://...`).
    - Initially: error → “no resources” because **no workers registered**.
- Start worker:
    - Run worker (older Spark: `start-slave.sh`, newer: `start-worker.sh`).
    - Worker registers to master.
    - Jobs now execute successfully.
    - Spark UI shows application + running tasks.
- Convert notebook → script:
    - Use `jupyter nbconvert --to script`.
    - Clean formatting manually.
    - Execute with `python script.py`.
    - Issue: first running app consumed all resources → needed to stop it.
- Make script configurable:
    - Use `argparse`.
    - Parameters:
        - `-input-green`
        - `-input-yellow`
        - `-output`
    - Enables running job per year/month (e.g., 2020 only).
- Problem with hardcoding:
    - Hardcoding `master` in script is bad practice.
    - Multiple environments (local, Airflow, cloud) require different configs.
    - Executor memory, cores, etc. should be configurable.
- Proper way: use `spark-submit`.
    - Remove `master` from Python script.
    - Use:
        - `spark-submit --master spark://... script.py [args]`
    - Cluster config (master, memory, cores) before script.
    - Job arguments after script.
    - This is production-style job submission.
- Verified:
    - Ran one job without `spark-submit` (2020).
    - Ran another with `spark-submit` (2021).
    - Both produced output successfully.
- Cleanup:
    - Stop worker (`stop-worker.sh` / `stop-slave.sh`).
    - Stop master (`stop-master.sh`).
    - Confirm Spark UI no longer accessible.
- Key takeaways:
    - Notebook → script → configurable CLI.
    - Standalone Spark = master + workers.
    - `spark-submit` = proper job submission mechanism.
    - Foundation for running Spark on cloud-managed clusters next.

### Dataproc

- Use **Google Cloud Dataproc** to run Spark in GCP.
- Enable Dataproc API (first-time setup).
- Create cluster:
    - Region = same as GCS bucket.
    - Single node for testing; Standard (master + workers) for production.
    - Optional components: Jupyter, Docker.
    - Cluster provisions underlying VM automatically.
- Dataproc has built-in access to GCS (no manual connector setup needed).
- Submit job via Web UI:
    - Upload PySpark script to GCS (`gs://...`).
    - Do NOT set `master` in script (Dataproc assigns it).
    - Select PySpark job type.
    - Provide script path + runtime arguments (input/output paths).
    - Output written back to GCS (e.g., `report_2021`).
- Three submission methods:
    - Web UI
    - **Google Cloud SDK** (gcloud CLI)
    - REST API
- gcloud submission pattern:
    - `gcloud dataproc jobs submit pyspark`
    - `-cluster`, `-region`
    - Script path
    - `-` separator → job arguments after this
- Common issue:
    - Permission denied (service account lacks Dataproc role).
    - Fix: Add Dataproc Admin role in IAM.
- Verified:
    - Successfully ran for multiple years (2020, 2021).
    - Outputs created in GCS.
- Airflow integration:
    - Simplest: BashOperator running gcloud command.
    - Alternative: Spark Submit Operator.
- Current flow:
    - Read from GCS → Process in Dataproc → Write back to GCS.
- Next step:
    - Write directly to **BigQuery** instead of GCS (better for analytics & dashboards).

### Connecting Spark with BQ

- Goal: Write Spark output directly from **Google Cloud Dataproc** to **BigQuery**.
- Use Spark BigQuery Connector example (official connector docs).
- Modify Spark script:
    - Replace `.write.parquet(...)`
    - Use `.write.format("bigquery")`
    - Set `.option("table", "project.dataset.table")`
    - Remove file merge logic (not needed for BigQuery).
- Important:
    - Must set `temporaryGcsBucket` (required for BigQuery connector).
    - Use Dataproc-created temp bucket if needed.
- Upload updated script to GCS (`gsutil cp`).
- Submit via `gcloud dataproc jobs submit pyspark`.
- First failure:
    - `Failed to find data source: bigquery` → missing connector JAR.
- Fix:
    - Add BigQuery connector JAR in job submission (`-jars` or UI jar field).
- Second issue:
    - Missing `temporaryGcsBucket` option → add it.
- Result:
    - Job succeeded.
    - Table auto-created in BigQuery (if not existing).
    - Data visible in BigQuery UI.
- Section recap:
    - Local Spark → GCS
    - Dataproc cluster creation
    - Job submission (UI + CLI)
    - Write directly to BigQuery