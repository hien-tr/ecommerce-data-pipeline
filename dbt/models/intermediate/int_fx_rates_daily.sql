with rates as (
    select * from {{ ref('stg_frankfurter__fx_rates') }}
),

calendar as (
    select calendar_date
    from unnest(generate_date_array(
        (select min(rate_date) from rates),
        greatest(
            (select max(rate_date) from rates),
            date_sub(current_date(), interval 1 day)
        )
    )) as calendar_date
),

currencies as (
    select distinct base_currency, currency
    from rates
),

spine as (
    select
        calendar.calendar_date,
        currencies.base_currency,
        currencies.currency
    from calendar
    cross join currencies
),

joined as (
    select
        spine.calendar_date,
        spine.base_currency,
        spine.currency,
        rates.rate as published_rate
    from spine
    left join rates
        on rates.rate_date = spine.calendar_date
        and rates.currency = spine.currency
),

filled as (
    select
        calendar_date as rate_date,
        base_currency,
        currency,
        last_value(published_rate ignore nulls) over (
            partition by currency
            order by calendar_date
            rows between unbounded preceding and current row
        ) as rate,
        published_rate is null as is_carried_forward
    from joined
),

usd as (
    select
        calendar_date as rate_date,
        'USD' as base_currency,
        'USD' as currency,
        1.0 as rate,
        false as is_carried_forward
    from calendar
)

select * from filled
union all
select * from usd
