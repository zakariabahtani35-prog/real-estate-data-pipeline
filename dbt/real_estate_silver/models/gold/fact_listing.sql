{{ config(
    materialized='table',
    schema='GOLD'
) }}

SELECT

    s.listing_id,

    d.date_key,

    l.location_key,

    p.property_key,

    s.surface_m2,

    s.num_rooms,

    s.num_bathrooms,

    s.floor,

    s.year_built,

    s.property_age,

    s.price,

    s.price_per_m2,

    s.listing_date

FROM {{ ref('silver_listings') }} s

LEFT JOIN {{ ref('dim_location') }} l
ON s.country = l.country
AND s.city = l.city
AND s.neighborhood = l.neighborhood

LEFT JOIN {{ ref('dim_property') }} p
ON s.property_type = p.property_type
AND s.condition = p.condition
AND s.heating_type = p.heating_type
AND s.parking = p.parking
AND s.energy_rating = p.energy_rating

LEFT JOIN {{ ref('dim_date') }} d
ON s.listing_date = d.listing_date