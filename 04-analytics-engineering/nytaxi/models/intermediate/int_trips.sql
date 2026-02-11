{{ config(
    materialized='table'
) }}

with unioned as (
    select * from {{ ref('int_trips_unioned') }}
)
, payment_type_lookup as (
    select * from {{ ref('payment_type_lookup') }}
)
, cleaned_enriched as (
    select 
    {{ dbt_utils.generate_surrogate_key(['u.vendor_id', 'u.pickup_datetime', 'u.pu_location_id', 'u.taxi_type']) }} as trip_id,

    u.vendor_id,
    u.rate_code_id,
    u.pu_location_id,
    u.do_location_id,
    u.pickup_datetime,
    u.dropoff_datetime,
    u.store_and_fwd_flag,
    u.passenger_count,
    u.trip_distance,
    u.trip_type,
    u.fare_amount,        
    u.extra,
    u.mta_tax,
    u.tip_amount, 
    u.tolls_amount,
    u.ehail_fee,
    u.improvement_surcharge,
    u.total_amount,
    u.taxi_type,

    coalesce(u.payment_type, 0) as payment_type,
    coalesce(p.description, 'Unknown') as payment_type_description

    from unioned u
    left join payment_type_lookup p
    on u.payment_type = p.payment_type
)

select * from cleaned_enriched
qualify row_number() over (
        partition by vendor_id, pickup_datetime, pu_location_id, taxi_type 
        order by dropoff_datetime desc
) = 1