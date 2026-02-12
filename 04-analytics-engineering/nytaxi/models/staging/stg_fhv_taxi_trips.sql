with source as (
    select
        *
    from {{ source('raw', 'fhv_tripdata') }}
),

renamed as (
    select
        -- identifiers
        cast(dispatching_base_num as string) as dispatching_base_num,
        cast(pulocationid as integer) as pu_location_id,
        cast(dolocationid as integer) as do_location_id,

        -- timestamps
        cast(pickup_datetime as timestamp) as pickup_datetime,
        cast(dropoff_datetime as timestamp) as dropoff_datetime,

        -- trip info
        cast(SR_Flag as string) as sr_flag,
        cast(Affiliated_base_number as string) as affiliated_base_number,

    from source
    where dispatching_base_num is not null
)

select distinct * from renamed

{% if target.name == 'dev' %}
    limit 500
{% endif %}