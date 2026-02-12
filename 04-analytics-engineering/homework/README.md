Q3: Count of records in fct_monthly_zone_revenue
```sql
select
  count(*)
from taxi_rides_ny.prod.agg_monthly_zone_revenue
```

Q4: Zone with highest revenue for Green in 2020
```sql
select 
  pu_zone,
  sum(total_revenue_monthly)
from taxi_rides_ny.prod.agg_monthly_zone_revenue
where year(revenue_month) = 2020 and taxi_type = 'green'
group by 1
order by 2 desc
```

Q5: Total trips for Green in Oct 2019
```sql
select 
  sum(total_trips_monthly)
from taxi_rides_ny.prod.agg_monthly_zone_revenue
where revenue_month = '2019-10-01'
  and taxi_type = 'green'
```

Q6: Count of records in stg_fhv_tripdata
```sql
select count(*)
from taxi_rides_ny.prod.stg_fhv_taxi_trips
```