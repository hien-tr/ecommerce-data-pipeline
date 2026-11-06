{% macro convert_to_usd(amount, rate) %}
   safe_divide({{ amount }} ,  cast( {{ rate }} as numeric)) 
{% endmacro %}