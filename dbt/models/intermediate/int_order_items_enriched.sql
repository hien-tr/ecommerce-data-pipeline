with order_items as (
    select * from {{ ref('stg_thelook__order_items') }}
),

products as (
    select * from {{ ref('stg_thelook__products') }}
),

enriched as (
    select
        order_items.order_item_id,
        order_items.order_id,
        order_items.user_id,
        order_items.product_id,
        order_items.inventory_item_id,

        products.product_name,
        products.brand,
        products.category,
        products.department,

        order_items.item_status,
        order_items.item_status = 'cancelled' as is_cancelled,
        order_items.item_status = 'returned' as is_returned,
        order_items.item_status = 'complete' as is_complete,

        order_items.sale_price,
        products.product_cost,
        products.retail_price,
        order_items.sale_price - products.product_cost as item_margin,

        order_items.created_at,
        order_items.shipped_at,
        order_items.delivered_at,
        order_items.returned_at
    from order_items
    left join products
        on order_items.product_id = products.product_id
)

select * from enriched
