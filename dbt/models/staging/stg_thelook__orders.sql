with source as (
    select * from {{ source('thelook', 'orders') }}
),

renamed as (
    select
        order_id,
        user_id,
        lower(status) as order_status,
        gender,
        num_of_item as item_count,
        created_at,
        shipped_at,
        delivered_at,
        returned_at
    from source
)

select * from renamed
