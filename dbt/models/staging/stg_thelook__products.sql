with source as (
    select * from {{ source('thelook', 'products') }}
),

renamed as (
    select
        id as product_id,
        coalesce(name, concat('Unknown product (', cast(id as string), ')')) as product_name,
        brand,
        category,
        department,
        sku,
        cost as product_cost,
        retail_price,
        distribution_center_id
    from source
)

select * from renamed
