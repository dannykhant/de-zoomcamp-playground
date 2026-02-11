select 
    count(*) as total_trips,
    count(distinct vendor_id || pickup_datetime || pu_location_id || taxi_type) as unique_trips,
from {{ ref('fct_trips') }}