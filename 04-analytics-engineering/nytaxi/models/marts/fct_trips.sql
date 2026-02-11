{{
    config(
        materialized='incremental',
        unique_key='trip_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns'
    )
}}

select 
    -- identifiers
    t.trip_id,
    t.vendor_id,
    t.rate_code_id,

    -- location details 
    t.pu_location_id,
    pu_z.borough as pu_borough,
    pu_z.zone as pu_zone,
    pu_z.service_zone as pu_service_zone,
    t.do_location_id,
    do_z.borough as do_borough,
    do_z.zone as do_zone,
    do_z.service_zone as do_service_zone,

    -- timestamps
    t.pickup_datetime,
    t.dropoff_datetime,
    {{ get_duration_minutes('t.pickup_datetime', 't.dropoff_datetime') }} as trip_duration_minutes,

    -- trip details
    t.store_and_fwd_flag,
    t.passenger_count,
    t.trip_distance,
    t.trip_type,
    t.taxi_type,

    -- financials
    t.fare_amount,        
    t.extra,
    t.mta_tax,
    t.tip_amount, 
    t.tolls_amount,
    t.ehail_fee,
    t.improvement_surcharge,
    t.total_amount,
    t.payment_type,
    t.payment_type_description

from {{ ref('int_trips') }} as t
left join {{ ref('dim_zones') }} as pu_z
    on t.pu_location_id = pu_z.location_id
left join {{ ref('dim_zones') }} as do_z
    on t.do_location_id = do_z.location_id

{% if is_incremental() %}

    where t.pickup_datetime > (select max(pickup_datetime) from {{ this }})

{% endif %}
