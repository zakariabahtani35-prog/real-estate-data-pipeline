{{ config(
    materialized='table',
    schema='GOLD'
) }}
SELECT DISTINCT

    ROW_NUMBER() OVER (ORDER BY country, city, neighborhood) AS location_key,

    country,
    city,
    neighborhood

FROM {{ ref('silver_listings') }}