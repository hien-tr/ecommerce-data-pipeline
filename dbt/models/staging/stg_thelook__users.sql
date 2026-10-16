with source as (
    select * from {{ source('thelook', 'users') }}
),

renamed as (
    select
        id as user_id,
        first_name,
        last_name,
        email,
        age,
        gender,
        street_address,
        postal_code,
        city,
        state,
        country,
        latitude,
        longitude,
        user_geom,
        lower(traffic_source) as traffic_source,
        created_at
    from source
)

select * from renamed
