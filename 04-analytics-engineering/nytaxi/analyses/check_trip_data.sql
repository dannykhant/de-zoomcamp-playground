select 
    count(*) as total_trips,
    count(distinct trip_id) as unique_trips,
from {{ ref('int_trips') }}