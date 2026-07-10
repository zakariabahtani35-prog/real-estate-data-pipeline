{{ config(
    materialized='table',
    schema='GOLD'
) }}

SELECT DISTINCT

    ROW_NUMBER() OVER (
        ORDER BY property_type,
                 condition,
                 heating_type,
                 parking,
                 energy_rating
    ) AS property_key,

    property_type,
    condition,
    heating_type,
    parking,
    energy_rating

FROM {{ ref('silver_listings') }}