with source as (
    select * from {{ source('raw', 'fx_rates') }}
),

renamed as (
    select
        rate_date,
        base_currency,
        currency,
        rate,
        loaded_at
    from source
)

select * from renamed
