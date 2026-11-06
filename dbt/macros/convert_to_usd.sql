{% macro convert_to_usd(amount, rate) %}
    round(cast( safe_divide({{ amount }} , {{ rate }}) as numeric), 2) 
{% endmacro %}