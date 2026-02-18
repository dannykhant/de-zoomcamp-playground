/* @bruin

# Docs:
# - Materialization: https://getbruin.com/docs/bruin/assets/materialization
# - Quality checks (built-ins): https://getbruin.com/docs/bruin/quality/available_checks
# - Custom checks: https://getbruin.com/docs/bruin/quality/custom

# TODO: Set the asset name (recommended: staging.trips).
name: staging.trips
# TODO: Set platform type.
# Docs: https://getbruin.com/docs/bruin/assets/sql
# suggested type: duckdb.sql
type: duckdb.sql

# TODO: Declare dependencies so `bruin run ... --downstream` and lineage work.
# Examples:
# depends:
#   - ingestion.trips
#   - ingestion.payment_lookup
depends:
  - ingestion.green_taxi_trips
  - ingestion.yellow_taxi_trips
  - ingestion.payment_lookup

# TODO: Choose time-based incremental processing if the dataset is naturally time-windowed.
# - This module expects you to use `time_interval` to reprocess only the requested window.
materialization:
  # What is materialization?
  # Materialization tells Bruin how to turn your SELECT query into a persisted dataset.
  # Docs: https://getbruin.com/docs/bruin/assets/materialization
  #
  # Materialization "type":
  # - table: persisted table
  # - view: persisted view (if the platform supports it)
  type: table
  # TODO: set a materialization strategy.
  # Docs: https://getbruin.com/docs/bruin/assets/materialization
  # suggested strategy: time_interval
  #
  # Incremental strategies (what does "incremental" mean?):
  # Incremental means you update only part of the destination instead of rebuilding everything every run.
  # In Bruin, this is controlled by `strategy` plus keys like `incremental_key` and `time_granularity`.
  #
  # Common strategies you can choose from (see docs for full list):
  # - create+replace (full rebuild)
  # - truncate+insert (full refresh without drop/create)
  # - append (insert new rows only)
  # - delete+insert (refresh partitions based on incremental_key values)
  # - merge (upsert based on primary key)
  # - time_interval (refresh rows within a time window)
  strategy: merge
  # TODO: set incremental_key to your event time column (DATE or TIMESTAMP).
  # incremental_key: pickup_datetime
  # TODO: choose `date` vs `timestamp` based on the incremental_key type.
  # time_granularity: timestamp

# TODO: Define output columns, mark primary keys, and add a few checks.
columns:
  - name: trip_id
    type: string
    description: "Unique identifier for each trip"
    primary_key: true
    nullable: false
    checks:
      - name: not_null
      - name: unique
  - name: vendor_id
    type: integer
    description: "A code indicating the LPEP provider that provided the record."
    checks:
      - name: not_null
  - name: rate_code_id
    type: integer
    description: "The final rate code in effect at the end of the trip."
  - name: pu_location_id
    type: integer
    description: "TLC Taxi Zone in which the taximeter was engaged."
    checks:
      - name: not_null
  - name: do_location_id
    type: integer
    description: "TLC Taxi Zone in which the taximeter was disengaged."
    checks:
      - name: not_null

  # Timestamps
  - name: pickup_datetime
    type: timestamp
    description: "The date and time when the meter was engaged."
    checks:
      - name: not_null
  - name: dropoff_datetime
    type: timestamp
    description: "The date and time when the meter was disengaged."
    checks:
      - name: not_null

  # Trip Details
  - name: store_and_fwd_flag
    type: string
    description: "This flag indicates whether the trip record was held in vehicle memory before sending to the vendor."
  - name: passenger_count
    type: integer
    description: "The number of passengers in the vehicle."
  - name: trip_distance
    type: double
    description: "The elapsed trip distance in miles reported by the taximeter."
  - name: trip_type
    type: integer
    description: "A code indicating whether the trip was a street-hail or a dispatch."
  - name: taxi_type
    type: string
    description: "Type of taxi (e.g., Green or Yellow)."

  # Financials
  - name: payment_type
    type: integer
    description: "A numeric code signifying how the passenger paid for the trip."
  - name: payment_type_name
    type: string
    description: "The descriptive name of the payment type."
  - name: fare_amount
    type: double
    description: "The time-and-distance fare calculated by the meter."
  - name: extra
    type: double
  - name: mta_tax
    type: double
  - name: tip_amount
    type: double
  - name: tolls_amount
    type: double
  - name: ehail_fee
    type: double
  - name: airport_fee
    type: double
  - name: improvement_surcharge
    type: double
  - name: congestion_surcharge
    type: double
  - name: total_amount
    type: double
    description: "The total amount charged to passengers. Does not include cash tips."

# TODO: Add one custom check that validates a staging invariant (uniqueness, ranges, etc.)
# Docs: https://getbruin.com/docs/bruin/quality/custom
custom_checks:
  - name: payment_lookup_join_check
    description: Validates that all payment_type values in trips are present in the payment_lookup table
    query: |
      -- TODO: return a single scalar (COUNT(*), etc.) that should match `value`
      SELECT count(*) > 1 from ingestion.payment_lookup
    value: 1

@bruin */

-- TODO: Write the staging SELECT query.
--
-- Purpose of staging:
-- - Clean and normalize schema from ingestion
-- - Deduplicate records (important if ingestion uses append strategy)
-- - Enrich with lookup tables (JOINs)
-- - Filter invalid rows (null PKs, negative values, etc.)
--
-- Why filter by {{ start_datetime }} / {{ end_datetime }}?
-- When using `time_interval` strategy, Bruin:
--   1. DELETES rows where `incremental_key` falls within the run's time window
--   2. INSERTS the result of your query
-- Therefore, your query MUST filter to the same time window so only that subset is inserted.
-- If you don't filter, you'll insert ALL data but only delete the window's data = duplicates.

with combined_trips as (
  select 
    -- identifiers 1
    vendor_id,
    ratecode_id,
    pu_location_id,
    do_location_id,

    -- timestamps
    lpep_pickup_datetime,
    lpep_dropoff_datetime,

    -- trip details
    store_and_fwd_flag,
    passenger_count,
    trip_distance,
    trip_type,
    'green' as taxi_type,

    -- financials
    payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    ehail_fee,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    0 as airport_fee, -- green taxis don't have airport_fee, so we can hardcode it
    extracted_at

  from ingestion.green_taxi_trips
  where lpep_pickup_datetime >= '{{ start_datetime }}' and lpep_pickup_datetime <= '{{ end_datetime }}'
    and vendor_id is not null
  union all
  select
    -- identifiers 2
    vendor_id,
    ratecode_id,
    pu_location_id,
    do_location_id,

    -- timestamps
    tpep_pickup_datetime,
    tpep_dropoff_datetime,

    -- trip details
    store_and_fwd_flag,
    passenger_count,
    trip_distance,
    1 as trip_type,  -- yellow taxis only have one trip type, so we can hardcode it
    'yellow' as taxi_type,

    -- financials
    payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    0 as ehail_fee,  -- yellow taxis don't have ehail_fee, so we can hardcode it
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    airport_fee,
    extracted_at

  from ingestion.yellow_taxi_trips
  where tpep_pickup_datetime >= '{{ start_datetime }}' and tpep_pickup_datetime <= '{{ end_datetime }}'
    and vendor_id is not null
)

,latest_trips as (
  select
    *,
    row_number() over (
      partition by vendor_id, lpep_pickup_datetime, pu_location_id, do_location_id, taxi_type
      order by extracted_at desc, lpep_dropoff_datetime desc
    ) as rn
  from combined_trips
)

,deduped_trips as (
  select *
  from latest_trips
  where rn = 1
)

select 
  {{ generate_surrogate_key([
    't.vendor_id', 
    't.lpep_pickup_datetime', 
    't.pu_location_id', 
    't.do_location_id', 
    't.taxi_type'
  ]) }} as trip_id,

  -- identifiers final
  t.vendor_id,
  t.ratecode_id as rate_code_id,
  t.pu_location_id,
  t.do_location_id,

  -- timestamps
  t.lpep_pickup_datetime as pickup_datetime,
  t.lpep_dropoff_datetime as dropoff_datetime,

  -- trip details
  t.store_and_fwd_flag,
  t.passenger_count,
  t.trip_distance,
  t.trip_type,
  t.taxi_type,

  -- financials
  t.payment_type,
  p.payment_type_name,
  t.fare_amount,
  t.extra,
  t.mta_tax,
  t.tip_amount,
  t.tolls_amount,
  t.ehail_fee,
  t.airport_fee,
  t.improvement_surcharge,
  t.congestion_surcharge,
  t.total_amount,
from deduped_trips t
left join ingestion.payment_lookup p
  on t.payment_type = p.payment_type_id