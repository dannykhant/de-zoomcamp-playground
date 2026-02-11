with trips as (
    select * from {{ ref('fct_trips') }}
)

select 
    distinct vendor_id,
    {{ get_vendor_info('vendor_id') }} as vendor_name
from trips