with source as (
    select * from {{ source('raw', 'ad_spend') }}
),

renamed as (
    select
        spend_date,
        lower(channel) as channel,
        upper(trim(currency)) as currency,
        spend,
        loaded_at
    from source
)

select * from renamed
