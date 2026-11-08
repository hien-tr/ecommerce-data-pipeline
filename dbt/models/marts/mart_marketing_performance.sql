with ad_spend as (
    select * from {{ ref('fct_ad_spend') }}
),

orders as (
    select * from {{ ref('fct_orders') }}
),

customers as (
    select * from {{ ref('dim_customers') }}
),

-- The mart covers the days that have ad spend data, so ROAS and CAC are meaningful.
date_range as (
    select
        min(spend_date) as first_date,
        max(spend_date) as last_date
    from ad_spend
),

spend as (
    select
        spend_date as date,
        channel,
        sum(spend_usd) as spend_usd
    from ad_spend
    group by 1, 2
),

revenue as (
    select
        orders.order_date as date,
        customers.channel,
        sum(orders.net_revenue) as net_revenue,
        count(orders.order_id) as orders
    from orders
    inner join customers
        on customers.user_id = orders.user_id
    where orders.order_status is distinct from 'cancelled'
    group by 1, 2
),

new_customers as (
    select
        first_order_date as date,
        channel,
        count(*) as new_customers
    from customers
    where first_order_date is not null
    group by 1, 2
),

-- Every day and channel that appears on any side, so organic (revenue, no spend)
-- and days with spend but no orders are both kept.
keys as (
    select date, channel from spend
    union distinct
    select date, channel from revenue
    union distinct
    select date, channel from new_customers
),

final as (
    select
        keys.date,
        keys.channel,
        round(coalesce(spend.spend_usd, 0), 2) as spend_usd,
        round(coalesce(revenue.net_revenue, 0), 2) as net_revenue,
        coalesce(revenue.orders, 0) as orders,
        coalesce(new_customers.new_customers, 0) as new_customers
    from keys
    cross join date_range
    left join spend
        on spend.date = keys.date
        and spend.channel = keys.channel
    left join revenue
        on revenue.date = keys.date
        and revenue.channel = keys.channel
    left join new_customers
        on new_customers.date = keys.date
        and new_customers.channel = keys.channel
    where keys.date between date_range.first_date and date_range.last_date
)

select * from final
