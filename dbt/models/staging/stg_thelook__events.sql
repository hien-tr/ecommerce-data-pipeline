with source as (
    select * from {{ source('thelook', 'events') }}
),

renamed as (
    select
        id as event_id,
        user_id,
        session_id,
        sequence_number,
        event_type,
        uri,
        browser,
        lower(traffic_source) as traffic_source,
        ip_address,
        city,
        state,
        postal_code,
        created_at
    from source
)

select * from renamed
