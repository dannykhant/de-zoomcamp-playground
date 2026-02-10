Module-3: Homework

Load data into BQ from GCS
```sql
LOAD DATA OVERWRITE tripdata.yellow_trip_2024
FROM FILES (
  format = 'PARQUET',
  uris = ['gs://saanay-ai-zoomcamp-mod3-datawarehouse/yellow_tripdata_2024-*.parquet']);
```

External table for data in GCS
```sql
CREATE EXTERNAL TABLE tripdata.ext_yellow_trip_2024
  OPTIONS (
    format = 'PARQUET',
    uris =
      [
        'gs://saanay-ai-zoomcamp-mod3-datawarehouse/yellow_tripdata_2024-*.parquet']);
```

Number of records where fare_amount of 0
```sql
SELECT COUNT(1)
FROM `tripdata.yellow_trip_2024`
WHERE fare_amount = 0;
```

Partitioned table creation
```sql
CREATE OR REPLACE TABLE `tripdata.yellow_trip_2024_partitioned`
  PARTITION BY date(tpep_dropoff_datetime)
  CLUSTER BY VendorID
AS
SELECT *
FROM `tripdata.yellow_trip_2024`;
```

Unique vendorID
```sql
SELECT DISTINCT VendorID
FROM `tripdata.yellow_trip_2024`
WHERE tpep_dropoff_datetime BETWEEN '2024-03-01' AND '2024-03-15'
```

Total records
```sql
SELECT COUNT(*)
FROM `tripdata.yellow_trip_2024_partitioned`
```