"""@bruin

name: ingestion.green_taxi_trips
connection: duckdb-default

materialization:
  type: table
  strategy: create+replace

image: python:3.11

variables:
  taxi_type:
    type: string
    default: "green"

parameters:
  enforce_schema: true

columns:
  - name: vendor_id
    type: integer
    description: "A code indicating the LPEP provider that provided the record."
  - name: lpep_pickup_datetime
    type: datetime
    description: "The date and time when the meter was engaged."
  - name: lpep_dropoff_datetime
    type: datetime
    description: "The date and time when the meter was disengaged."
  - name: store_and_fwd_flag
    type: string
    description: "Whether the trip record was held in vehicle memory before sending to vendor."
  - name: ratecode_id
    type: float
    description: "The final rate code in effect at the end of the trip."
  - name: pu_location_id
    type: integer
    description: "TLC Taxi Zone in which the taximeter was engaged."
  - name: do_location_id
    type: integer
    description: "TLC Taxi Zone in which the taximeter was disengaged."
  - name: passenger_count
    type: float
  - name: trip_distance
    type: float
  - name: fare_amount
    type: float
  - name: extra
    type: float
  - name: mta_tax
    type: float
  - name: tip_amount
    type: float
  - name: tolls_amount
    type: float
  - name: ehail_fee
    type: float
    nullable: true
  - name: improvement_surcharge
    type: float
  - name: total_amount
    type: float
  - name: payment_type
    type: float
  - name: trip_type
    type: float
  - name: congestion_surcharge
    type: float
  - name: extracted_at
    type: timestamp
    description: "Timestamp when the data was extracted"
  - name: source_file
    type: string
    description: "Source parquet file name"

@bruin"""

import os
import json
from datetime import datetime

import pandas as pd


def materialize():
    """
    Ingest NYC green taxi trip data from NYC TLC parquet files.
    
    Note: This function does NOT connect to DuckDB directly to check for existing
    files because DuckDB doesn't allow concurrent connections. Instead, we rely
    on the staging layer to handle deduplication.
    """
    start_date = os.getenv("BRUIN_START_DATE")
    end_date = os.getenv("BRUIN_END_DATE")

    bruin_vars_raw = os.getenv("BRUIN_VARS", "{}")
    bruin_vars = json.loads(bruin_vars_raw)
    
    taxi_type = bruin_vars.get("taxi_type", "green")

    print(f"Ingesting data from {start_date} to {end_date} for type: {taxi_type}")

    date_range = pd.date_range(start=start_date, end=end_date, freq='MS')

    all_dfs = []
    extraction_at = datetime.now()
    base_url = "https://d37ci6vzurychx.cloudfront.net/trip-data"

    for date_point in date_range:
        year_month = date_point.strftime("%Y-%m")
        file_name = f"{taxi_type}_tripdata_{year_month}.parquet"

        url = f"{base_url}/{file_name}"
        
        try:
            df = pd.read_parquet(url)
            df["extracted_at"] = extraction_at
            df["source_file"] = file_name
            all_dfs.append(df)
            print(f"Loaded {file_name} with {len(df)} rows")
        except Exception as e:
            print(f"Skipping {file_name}: {e}")

    if all_dfs:
        result = pd.concat(all_dfs, ignore_index=True)
        return result
    return pd.DataFrame()
