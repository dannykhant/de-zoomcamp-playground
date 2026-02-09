# Module: 3

### 3.1.1: Data Warehouse

- OLTP vs. OLAP
    - OLTP
        - Normalized
        - Write optimized
    - OLAP
        - Denormalized
        - Read optimized
- Data warehouse
    - Used for reporting & data analysis
    - Data sources → Staging area → Warehouse → Data marts
- BigQuery
    - Serverless data warehouse
    - Scalablility & high availability
    - ML, Geo-spatial, BI features available
- BQ cost
    - On-demand pricing
    - Flat rate pricing
        - Based on number of pre-requested slots
- Partition in BQ
    - It allows to reduce costs because it only scans the required partitions
    - For partition info: `dataset.INFORMATION_SCHEMA.PARTITIONS`
- Clustering in BQ
    - It groups same value in the table together and that makes BQ scans less data size

### 3.1.2: Partitioning & Clustering

- BQ partition
    - Types
        - Time-unit column
        - Ingestion time (_PARTITIONTIME)
        - Integer range partitioning
    - Time-unit & Ingestion time
        - Daily (default)
        - Hourly
        - Monthly or yearly
    - Partition limit: 4,000
- BQ clustering
    - Order of the column is important
    - The order of the specific columns determines the sort order of the data
    - Clustering improves:
        - Filter queries
        - Aggregate queries
    - Table with data size < 1 GB, there is no significant improvement
    - Clustering column limit: 4
- Partitioning vs. Clustering
    - Partitioning
        - Cost known upfront
        - Need partition management
        - Filter or aggregate on single column
    - Clustering
        - Cost known upfront
        - Need more granularity than partition
        - Filter or aggregate on multiple specific columns
        - When cardinality of values in a column is large
- Clustering over partitioning
    - When partition size is small (< 1GB)
    - When it can hit the max partition limit
    - If there is modification on the partitions frequently
- Automatic reclustering
    - BQ performs it in the background to restore the sort property of the table

### 3.2.1: BigQuery Best Practices

- Cost reduction
    - Avoid `select *`
    - Use cluster & partition
    - Be careful with streaming inserts
    - Materialize query results in stages
- Query performance
    - Filter on partitioned columns
    - Denormalize data
    - Use nested columns
    - Be careful with external data sources
    - Reduce data before joins
    - Avoid oversharding tables
    - Avoid Javascript UDF
    - Use approx aggregation functions such as HyperLogLog++
    - Optimize join patterns: put the largest table first

### 3.2.2: Internals of BigQuery

- Stack
    - Colossus for storage
    - Jupiter for network
    - Dremel for compute
- Dremel
    - Root → Mixer → Leaf node → Colossus

### 3.3.1: BigQuery Machine Learning

- Free-tier
    - 10 GB per month for storage
    - 1 TB per month for queries processed
    - ML models: 10 GB per month
-