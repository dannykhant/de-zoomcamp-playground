{% macro get_vendor_info(vendor_id) %}

{% set vendors = {
    1: 'Creative Mobile Technologies, LLC.',
    2: 'VeriFone Inc.',
    4: 'Unknown'
} %}

case {{ vendor_id }}
    {% for id, name in vendors.items() %}
        when {{ id }} then '{{ name }}'
    {% endfor %}
end

{% endmacro %}