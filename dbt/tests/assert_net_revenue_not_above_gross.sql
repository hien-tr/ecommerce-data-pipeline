-- Net revenue excludes returned items, so it can never be higher than gross revenue.
-- Returns the orders that break this rule; the test fails if any are found.

select
    order_id,
    gross_revenue,
    net_revenue
from {{ ref('fct_orders') }}
where net_revenue > gross_revenue
