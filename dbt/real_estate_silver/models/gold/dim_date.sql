{{ config(
    materialized='table',
    schema='GOLD'
) }}

SELECT DISTINCT

    ROW_NUMBER() OVER (ORDER BY listing_date) AS date_key,

    listing_date,

    YEAR(listing_date) AS year,
    MONTH(listing_date) AS month,
    DAY(listing_date) AS day,
    QUARTER(listing_date) AS quarter

FROM {{ ref('silver_listings') }}

WHERE listing_date IS NOT NULL