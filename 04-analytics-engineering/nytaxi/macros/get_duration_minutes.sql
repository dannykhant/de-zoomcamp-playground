{% macro get_duration_minutes(start_time, end_time) %}
    {{ dbt.datediff(start_time, end_time, 'minute') }}
{% endmacro %}