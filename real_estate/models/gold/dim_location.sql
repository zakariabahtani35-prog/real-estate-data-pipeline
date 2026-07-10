{{ config(materialized='table') }}

SELECT DISTINCT
    country,
    city,
    neighborhood
FROM {{ ref('silver_listings') }}
ORDER BY country, city;