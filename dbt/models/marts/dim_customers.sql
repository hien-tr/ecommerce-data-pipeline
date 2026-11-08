with users as (
    select * from {{ ref('stg_thelook__users') }}
),

orders as (
    select * from {{ ref('fct_orders') }}
),

first_orders as (
    select
        user_id,
        min(order_date) as first_order_date
    from orders
    where order_status is distinct from 'cancelled'
    group by user_id
),

final as (
    select
        users.user_id,
        users.traffic_source as channel,
        users.created_at as signed_up_at,
        first_orders.first_order_date
    from users
    left join first_orders
        on first_orders.user_id = users.user_id
)

select * from final
