with green_trips as (
    select 
        vendor_id,
        rate_code_id,
        pu_location_id,
        do_location_id,
        pickup_datetime,
        dropoff_datetime,
        store_and_fwd_flag,
        passenger_count,
        trip_distance,
        trip_type,
        fare_amount,        
        extra,
        mta_tax,
        tip_amount, 
        tolls_amount,
        ehail_fee,
        improvement_surcharge,
        total_amount,
        payment_type,
        'green' as taxi_type
    from {{ ref('stg_green_taxi_trip') }}
),
yellow_trips as (
    select 
        vendor_id,
        rate_code_id,
        pu_location_id,
        do_location_id,
        pickup_datetime,
        dropoff_datetime,
        store_and_fwd_flag,
        passenger_count,
        trip_distance,
        cast(1 as integer) as trip_type,
        fare_amount,        
        extra,
        mta_tax,
        tip_amount, 
        tolls_amount,
        cast(0 as numeric) as ehail_fee,
        improvement_surcharge,
        total_amount,
        payment_type,
        'yellow' as taxi_type
    from {{ ref('stg_yellow_taxi_trip') }}
)

select * from green_trips
union all
select * from yellow_trips