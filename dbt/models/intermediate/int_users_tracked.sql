{{ config(materialized='ephemeral') }}

select
    user_id,
    country,
    state,
    city,
    postal_code,
    traffic_source,
    created_at
from {{ ref('stg_thelook__users') }}
