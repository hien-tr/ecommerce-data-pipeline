with ad_spend as (
    select * from {{ ref('stg_marketing__ad_spend') }}
),

fx_rates as (
    select * from {{ ref('int_fx_rates_daily') }}
),

final as (
    select
        ad_spend.spend_date,
        ad_spend.channel,
        ad_spend.currency,
        ad_spend.spend,
        fx_rates.rate,
        {{ convert_to_usd('ad_spend.spend', 'fx_rates.rate') }} as spend_usd
    from ad_spend
    left join fx_rates
        on fx_rates.rate_date = ad_spend.spend_date
        and fx_rates.currency = ad_spend.currency
)

select * from final
