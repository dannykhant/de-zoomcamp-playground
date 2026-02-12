with unioned as (
    select * from {{ ref('int_trips_unioned') }}
)
, payment_type_lookup as (
    select * from {{ ref('payment_type_lookup') }}
)
, latest as (
    select 
        vendor_id,
        pickup_datetime,
        pu_location_id,
        do_location_id,
        taxi_type,
        max(dropoff_datetime) as dropoff_datetime,
        max(trip_distance) as trip_distance,
        max(total_amount) as total_amount,
        max(passenger_count) as passenger_count
    from unioned
    group by 1,2,3,4,5
)
, deduped as (
    select 
        u.*
    from unioned u
    join latest l
    on u.vendor_id = l.vendor_id
    and u.pickup_datetime = l.pickup_datetime
    and u.pu_location_id = l.pu_location_id
    and u.do_location_id = l.do_location_id
    and u.taxi_type = l.taxi_type
    and u.dropoff_datetime = l.dropoff_datetime
    and u.trip_distance = l.trip_distance
    and u.total_amount = l.total_amount
    and u.passenger_count = l.passenger_count
)
, cleaned_enriched as (
    select 
    {{ dbt_utils.generate_surrogate_key([
        'u.vendor_id', 
        'u.pickup_datetime', 
        'u.pu_location_id',
        'u.do_location_id',
        'u.taxi_type'
    ]) }} as trip_id,

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

    from deduped u
    left join payment_type_lookup p
    on u.payment_type = p.payment_type
)

select * from cleaned_enriched