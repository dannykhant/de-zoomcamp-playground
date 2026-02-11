select
    coalesce(pu_zone, 'Unknown') as pu_zone,
    date_trunc('month', pickup_datetime) as revenue_month,
    taxi_type,
    sum(total_amount) as total_revenue_monthly,
    count(trip_id) as total_trips_monthly,
    avg(passenger_count) as avg_passenger_count_monthly,
    avg(trip_distance) as avg_trip_distance_monthly
from {{ ref('fct_trips') }}
group by pu_zone, revenue_month, taxi_type