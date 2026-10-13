with orders as (
    select * from {{ ref('stg_thelook__orders') }}
),

order_items as (
    select * from {{ ref('int_order_items_enriched') }}
),

order_item_totals as (
    select
        order_id,
        count(*) as item_count,
        countif(is_cancelled) as cancelled_item_count,
        countif(is_returned) as returned_item_count,
        sum(if(not is_cancelled, sale_price, 0)) as gross_revenue,
        sum(if(not is_cancelled and not is_returned, sale_price, 0)) as net_revenue,
        sum(if(not is_cancelled and not is_returned, product_cost, 0)) as net_cost
    from order_items
    group by order_id
),

final as (
    select
        orders.order_id,
        orders.user_id,
        orders.order_status,
        orders.created_at,
        date(orders.created_at) as order_date,
        orders.shipped_at,
        orders.delivered_at,
        orders.returned_at,
        coalesce(totals.item_count, 0) as item_count,
        coalesce(totals.cancelled_item_count, 0) as cancelled_item_count,
        coalesce(totals.returned_item_count, 0) as returned_item_count,
        round(coalesce(totals.gross_revenue, 0), 2) as gross_revenue,
        round(coalesce(totals.net_revenue, 0), 2) as net_revenue,
        round(coalesce(totals.net_revenue - totals.net_cost, 0), 2) as net_margin
    from orders
    left join order_item_totals as totals
        on orders.order_id = totals.order_id
)

select * from final
