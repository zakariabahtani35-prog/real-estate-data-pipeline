-- ============================================================
-- Modèle Silver : Nettoyage + Imputation des données
-- Auteur : Assiya
-- Branche : feature/dbt-silver
-- ============================================================

WITH bronze AS (
    SELECT * FROM {{ source('bronze', 'RAW_REAL_ESTATE') }}
),

-- ====================================================
-- 1. MODE NEIGHBORHOOD PAR CITY
-- ====================================================
neighborhood_mode AS (
    SELECT
        TRIM(city) AS city,
        LOWER(TRIM(neighborhood)) AS neighborhood_mode
    FROM (
        SELECT
            TRIM(city) AS city,
            LOWER(TRIM(neighborhood)) AS neighborhood,
            COUNT(*) AS cnt,
            ROW_NUMBER() OVER (
                PARTITION BY TRIM(city)
                ORDER BY COUNT(*) DESC
            ) AS rn
        FROM bronze
        WHERE neighborhood IS NOT NULL
          AND TRIM(neighborhood) != ''
        GROUP BY TRIM(city), LOWER(TRIM(neighborhood))
    ) ranked
    WHERE rn = 1
),

-- ====================================================
-- 2. MODE HEATING_TYPE PAR PROPERTY_TYPE
-- ====================================================
heating_mode AS (
    SELECT
        LOWER(TRIM(property_type)) AS property_type,
        LOWER(TRIM(heating_type)) AS heating_mode
    FROM (
        SELECT
            LOWER(TRIM(property_type)) AS property_type,
            LOWER(TRIM(heating_type)) AS heating_type,
            COUNT(*) AS cnt,
            ROW_NUMBER() OVER (
                PARTITION BY LOWER(TRIM(property_type))
                ORDER BY COUNT(*) DESC
            ) AS rn
        FROM bronze
        WHERE heating_type IS NOT NULL
          AND TRIM(heating_type) != ''
        GROUP BY LOWER(TRIM(property_type)), LOWER(TRIM(heating_type))
    ) ranked
    WHERE rn = 1
),

-- ====================================================
-- 3. MODE ENERGY_RATING PAR PROPERTY_TYPE + YEAR_RANGE + HEATING_TYPE
-- ====================================================
energy_mode AS (
    SELECT
        property_type,
        year_range,
        heating_type,
        UPPER(TRIM(energy_rating)) AS energy_mode
    FROM (
        SELECT
            LOWER(TRIM(property_type)) AS property_type,
            CASE
                WHEN year_built >= 2020 THEN '2020+'
                WHEN year_built >= 2010 THEN '2010-2019'
                WHEN year_built >= 2000 THEN '2000-2009'
                WHEN year_built >= 1990 THEN '1990-1999'
                ELSE 'before-1990'
            END AS year_range,
            LOWER(TRIM(heating_type)) AS heating_type,
            UPPER(TRIM(energy_rating)) AS energy_rating,
            COUNT(*) AS cnt,
            ROW_NUMBER() OVER (
                PARTITION BY
                    LOWER(TRIM(property_type)),
                    CASE
                        WHEN year_built >= 2020 THEN '2020+'
                        WHEN year_built >= 2010 THEN '2010-2019'
                        WHEN year_built >= 2000 THEN '2000-2009'
                        WHEN year_built >= 1990 THEN '1990-1999'
                        ELSE 'before-1990'
                    END,
                    LOWER(TRIM(heating_type))
                ORDER BY COUNT(*) DESC
            ) AS rn
        FROM bronze
        WHERE energy_rating IS NOT NULL
          AND TRIM(energy_rating) != ''
          AND UPPER(TRIM(energy_rating)) != 'UNKNOWN'
        GROUP BY
            LOWER(TRIM(property_type)),
            CASE
                WHEN year_built >= 2020 THEN '2020+'
                WHEN year_built >= 2010 THEN '2010-2019'
                WHEN year_built >= 2000 THEN '2000-2009'
                WHEN year_built >= 1990 THEN '1990-1999'
                ELSE 'before-1990'
            END,
            LOWER(TRIM(heating_type)),
            UPPER(TRIM(energy_rating))
    ) ranked
    WHERE rn = 1
),

-- ====================================================
-- 4. MODE GLOBAL ENERGY_RATING (fallback)
-- ====================================================
energy_global_mode AS (
    SELECT UPPER(TRIM(energy_rating)) AS energy_global
    FROM (
        SELECT
            UPPER(TRIM(energy_rating)) AS energy_rating,
            COUNT(*) AS cnt,
            ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
        FROM bronze
        WHERE energy_rating IS NOT NULL
          AND TRIM(energy_rating) != ''
          AND UPPER(TRIM(energy_rating)) != 'UNKNOWN'
        GROUP BY UPPER(TRIM(energy_rating))
    ) ranked
    WHERE rn = 1
),

-- ====================================================
-- 5. MODE PARKING PAR PROPERTY_TYPE + SURFACE_RANGE
-- ====================================================
parking_mode AS (
    SELECT
        property_type,
        surface_range,
        parking_mode
    FROM (
        SELECT
            LOWER(TRIM(property_type)) AS property_type,
            CASE
                WHEN surface_m2 > 150 THEN 'large'
                WHEN surface_m2 > 100 THEN 'medium-large'
                WHEN surface_m2 > 50  THEN 'medium'
                ELSE 'small'
            END AS surface_range,
            CASE
                WHEN LOWER(TRIM(parking)) IN ('yes', '1') THEN 'YES'
                WHEN LOWER(TRIM(parking)) IN ('no', '0')  THEN 'NO'
            END AS parking_mode,
            COUNT(*) AS cnt,
            ROW_NUMBER() OVER (
                PARTITION BY
                    LOWER(TRIM(property_type)),
                    CASE
                        WHEN surface_m2 > 150 THEN 'large'
                        WHEN surface_m2 > 100 THEN 'medium-large'
                        WHEN surface_m2 > 50  THEN 'medium'
                        ELSE 'small'
                    END
                ORDER BY COUNT(*) DESC
            ) AS rn
        FROM bronze
        WHERE parking IS NOT NULL
          AND LOWER(TRIM(parking)) IN ('yes', 'no', '1', '0')
        GROUP BY
            LOWER(TRIM(property_type)),
            CASE
                WHEN surface_m2 > 150 THEN 'large'
                WHEN surface_m2 > 100 THEN 'medium-large'
                WHEN surface_m2 > 50  THEN 'medium'
                ELSE 'small'
            END,
            CASE
                WHEN LOWER(TRIM(parking)) IN ('yes', '1') THEN 'YES'
                WHEN LOWER(TRIM(parking)) IN ('no', '0')  THEN 'NO'
            END
    ) ranked
    WHERE rn = 1
),

-- ====================================================
-- 6. MOYENNE SURFACE PAR PROPERTY_TYPE
-- ====================================================
surface_avg AS (
    SELECT
        LOWER(TRIM(property_type)) AS property_type,
        ROUND(AVG(surface_m2), 0)::INTEGER AS avg_surface_by_type
    FROM bronze
    WHERE surface_m2 IS NOT NULL
      AND surface_m2 != 9999
      AND CASE
            WHEN LOWER(TRIM(property_type)) = 'studio'
                 AND (surface_m2 < 15 OR surface_m2 > 60)  THEN FALSE
            WHEN LOWER(TRIM(property_type)) = 'apartment'
                 AND (surface_m2 < 30 OR surface_m2 > 300) THEN FALSE
            WHEN LOWER(TRIM(property_type)) = 'duplex'
                 AND (surface_m2 < 50 OR surface_m2 > 350) THEN FALSE
            WHEN LOWER(TRIM(property_type)) = 'house'
                 AND (surface_m2 < 60 OR surface_m2 > 600) THEN FALSE
            WHEN LOWER(TRIM(property_type)) IN ('villa','villa ')
                 AND (surface_m2 < 80 OR surface_m2 > 800) THEN FALSE
            WHEN LOWER(TRIM(property_type)) = 'penthouse'
                 AND (surface_m2 < 80 OR surface_m2 > 500) THEN FALSE
            ELSE TRUE
          END
    GROUP BY LOWER(TRIM(property_type))
),

-- ====================================================
-- 7. MEDIANE NUM_ROOMS PAR PROPERTY_TYPE
-- ====================================================
rooms_median AS (
    SELECT
        LOWER(TRIM(property_type)) AS property_type,
        MEDIAN(num_rooms) AS median_rooms_by_type
    FROM bronze
    WHERE num_rooms IS NOT NULL
      AND CASE
            WHEN LOWER(TRIM(property_type)) = 'studio'    AND num_rooms > 2  THEN FALSE
            WHEN LOWER(TRIM(property_type)) = 'apartment' AND num_rooms > 6  THEN FALSE
            WHEN LOWER(TRIM(property_type)) = 'duplex'    AND num_rooms > 8  THEN FALSE
            WHEN LOWER(TRIM(property_type)) = 'house'     AND num_rooms > 10 THEN FALSE
            WHEN LOWER(TRIM(property_type)) IN ('villa','villa ') AND num_rooms > 12 THEN FALSE
            WHEN LOWER(TRIM(property_type)) = 'penthouse' AND num_rooms > 8  THEN FALSE
            ELSE TRUE
          END
    GROUP BY LOWER(TRIM(property_type))
),

-- ====================================================
-- 8. MEDIANE FLOOR PAR PROPERTY_TYPE
-- ====================================================
floor_median AS (
    SELECT
        LOWER(TRIM(property_type)) AS property_type,
        MEDIAN(floor) AS median_floor_by_type
    FROM bronze
    WHERE floor IS NOT NULL
    GROUP BY LOWER(TRIM(property_type))
),

-- ====================================================
-- 9. STATISTIQUES GLOBALES
-- ====================================================
stats AS (
    SELECT
        AVG(
            CASE WHEN TRY_CAST(TRIM(REPLACE(price::VARCHAR, ' EUR', '')) AS FLOAT) >= 1000
            THEN TRY_CAST(TRIM(REPLACE(price::VARCHAR, ' EUR', '')) AS FLOAT)
            END
        ) AS avg_price,
        ROUND(AVG(
            CASE WHEN surface_m2 != 9999 AND surface_m2 >= 10
            THEN surface_m2 END
        ), 0)::INTEGER AS avg_surface,
        MEDIAN(num_rooms)     AS median_rooms,
        MEDIAN(num_bathrooms) AS median_bathrooms,
        MEDIAN(year_built)    AS median_year_built,
        MEDIAN(floor)         AS median_floor
    FROM bronze
),

-- ====================================================
-- 10. NETTOYAGE PRINCIPAL
-- ====================================================
cleaned AS (
    SELECT
        b.listing_id,

        --  Type de bien
        CASE
            WHEN LOWER(TRIM(b.property_type)) IN ('apt', 'apartment') THEN 'apartment'
            WHEN LOWER(TRIM(b.property_type)) IN ('villa ', 'villa')  THEN 'villa'
            WHEN LOWER(TRIM(b.property_type)) = 'house'               THEN 'house'
            WHEN LOWER(TRIM(b.property_type)) = 'studio'              THEN 'studio'
            WHEN LOWER(TRIM(b.property_type)) = 'duplex'              THEN 'duplex'
            WHEN LOWER(TRIM(b.property_type)) = 'penthouse'           THEN 'penthouse'
            ELSE LOWER(TRIM(b.property_type))
        END AS property_type,

        --  Pays
        COALESCE(
            NULLIF(TRIM(b.country), ''),
            CASE
                WHEN TRIM(b.city) IN ('Paris', 'Lyon', 'Nice', 'Marseille',
                                      'Bordeaux', 'Toulouse', 'Nantes',
                                      'Strasbourg', 'Montpellier', 'Rennes') THEN 'France'
                WHEN TRIM(b.city) IN ('Berlin', 'Munich', 'Hamburg', 'Frankfurt',
                                      'Cologne', 'Stuttgart', 'Düsseldorf',
                                      'Leipzig', 'Dresden', 'Nuremberg') THEN 'Germany'
                WHEN TRIM(b.city) IN ('Amsterdam', 'Rotterdam', 'Utrecht',
                                      'The Hague', 'Eindhoven', 'Groningen') THEN 'Netherlands'
                WHEN TRIM(b.city) IN ('Zurich', 'Geneva', 'Bern', 'Lausanne',
                                      'Lucerne', 'Basel') THEN 'Switzerland'
                WHEN TRIM(b.city) IN ('Madrid', 'Barcelona', 'Valencia',
                                      'Seville', 'Bilbao', 'Malaga',
                                      'Zaragoza', 'Palma', 'Alicante') THEN 'Spain'
                WHEN TRIM(b.city) IN ('Rome', 'Milan', 'Naples', 'Turin',
                                      'Florence', 'Bologna', 'Venice',
                                      'Genoa', 'Palermo') THEN 'Italy'
                WHEN TRIM(b.city) IN ('Lisbon', 'Porto', 'Coimbra', 'Braga',
                                      'Setúbal', 'Faro', 'Funchal') THEN 'Portugal'
                WHEN TRIM(b.city) IN ('Brussels', 'Antwerp', 'Ghent',
                                      'Bruges', 'Liège', 'Namur') THEN 'Belgium'
                WHEN TRIM(b.city) IN ('Vienna', 'Salzburg', 'Graz',
                                      'Innsbruck', 'Linz') THEN 'Austria'
                ELSE 'Unknown'
            END
        ) AS country,

        TRIM(b.city) AS city,

        --  Quartier
        COALESCE(
            NULLIF(LOWER(TRIM(b.neighborhood)), ''),
            n.neighborhood_mode,
            'unknown'
        ) AS neighborhood,

        --  Surface
        COALESCE(
            CASE
                WHEN b.surface_m2 = 9999 THEN NULL
                WHEN LOWER(TRIM(b.property_type)) = 'studio'
                     AND (b.surface_m2 < 15 OR b.surface_m2 > 60)  THEN NULL
                WHEN LOWER(TRIM(b.property_type)) = 'apartment'
                     AND (b.surface_m2 < 30 OR b.surface_m2 > 300) THEN NULL
                WHEN LOWER(TRIM(b.property_type)) = 'duplex'
                     AND (b.surface_m2 < 50 OR b.surface_m2 > 350) THEN NULL
                WHEN LOWER(TRIM(b.property_type)) = 'house'
                     AND (b.surface_m2 < 60 OR b.surface_m2 > 600) THEN NULL
                WHEN LOWER(TRIM(b.property_type)) IN ('villa', 'villa ')
                     AND (b.surface_m2 < 80 OR b.surface_m2 > 800) THEN NULL
                WHEN LOWER(TRIM(b.property_type)) = 'penthouse'
                     AND (b.surface_m2 < 80 OR b.surface_m2 > 500) THEN NULL
                ELSE b.surface_m2
            END,
            ROUND(sa.avg_surface_by_type, 0)::INTEGER,
            ROUND(s.avg_surface, 0)::INTEGER
        ) AS surface_m2,

        --  Num_rooms
        COALESCE(
            CASE
                WHEN LOWER(TRIM(b.property_type)) = 'studio'
                     AND b.num_rooms > 2    THEN NULL
                WHEN LOWER(TRIM(b.property_type)) = 'apartment'
                     AND b.num_rooms > 6    THEN NULL
                WHEN LOWER(TRIM(b.property_type)) = 'duplex'
                     AND b.num_rooms > 8    THEN NULL
                WHEN LOWER(TRIM(b.property_type)) = 'house'
                     AND b.num_rooms > 10   THEN NULL
                WHEN LOWER(TRIM(b.property_type)) IN ('villa', 'villa ')
                     AND b.num_rooms > 12   THEN NULL
                WHEN LOWER(TRIM(b.property_type)) = 'penthouse'
                     AND b.num_rooms > 8    THEN NULL
                ELSE b.num_rooms
            END,
            ROUND(rm.median_rooms_by_type, 0)::INTEGER,
            ROUND(s.median_rooms, 0)::INTEGER
        ) AS num_rooms,

        COALESCE(b.num_bathrooms, s.median_bathrooms) AS num_bathrooms,

        --  Floor → médiane par property_type
        COALESCE(
            b.floor,
            fm.median_floor_by_type,
            s.median_floor
        ) AS floor,

        COALESCE(b.year_built, s.median_year_built) AS year_built,

        --  Prix
        COALESCE(
            CASE
                WHEN TRY_CAST(TRIM(REPLACE(b.price::VARCHAR, ' EUR', '')) AS FLOAT) < 1000
                THEN NULL
                ELSE TRY_CAST(TRIM(REPLACE(b.price::VARCHAR, ' EUR', '')) AS FLOAT)
            END,
            s.avg_price
        ) AS price,

        --  Date → médiane comme fallback
        COALESCE(
            TRY_TO_DATE(b.listing_date, 'YYYY-MM-DD'),
            TRY_TO_DATE(b.listing_date, 'DD/MM/YYYY'),
            TRY_TO_DATE(b.listing_date, 'DD.MM.YYYY'),
            TRY_TO_DATE(b.listing_date, 'DD-MM-YYYY'),
            '2022-01-01'::DATE
        ) AS listing_date,

        --  Condition
        COALESCE(
            NULLIF(INITCAP(TRIM(b.condition)), ''),
            CASE UPPER(TRIM(b.energy_rating))
                WHEN 'A' THEN 'New'
                WHEN 'B' THEN 'New'
                WHEN 'C' THEN 'Good'
                WHEN 'D' THEN 'Renovated'
                WHEN 'E' THEN 'Old'
                WHEN 'F' THEN 'Old'
                WHEN 'G' THEN 'Old'
                ELSE 'Good'
            END
        ) AS condition,

        --  Chauffage
        COALESCE(
            NULLIF(LOWER(TRIM(b.heating_type)), ''),
            h.heating_mode,
            'unknown'
        ) AS heating_type,

        --  Parking
        COALESCE(
            CASE
                WHEN LOWER(TRIM(b.parking)) IN ('yes', '1') THEN 'YES'
                WHEN LOWER(TRIM(b.parking)) IN ('no', '0')  THEN 'NO'
                ELSE NULL
            END,
            p.parking_mode,
            'NO'
        ) AS parking,

        --  Classe énergie
        COALESCE(
            CASE WHEN UPPER(TRIM(b.energy_rating)) IN ('A','B','C','D','E','F','G')
                 THEN UPPER(TRIM(b.energy_rating))
                 ELSE NULL END,
            e.energy_mode,
            eg.energy_global
        ) AS energy_rating

    FROM bronze b
    LEFT JOIN neighborhood_mode n  ON TRIM(b.city) = n.city
    LEFT JOIN heating_mode h       ON LOWER(TRIM(b.property_type)) = h.property_type
    LEFT JOIN energy_mode e
        ON LOWER(TRIM(b.property_type)) = e.property_type
        AND CASE
            WHEN b.year_built >= 2020 THEN '2020+'
            WHEN b.year_built >= 2010 THEN '2010-2019'
            WHEN b.year_built >= 2000 THEN '2000-2009'
            WHEN b.year_built >= 1990 THEN '1990-1999'
            ELSE 'before-1990'
        END = e.year_range
        AND LOWER(TRIM(b.heating_type)) = e.heating_type
    LEFT JOIN parking_mode p
        ON LOWER(TRIM(b.property_type)) = p.property_type
        AND CASE
            WHEN b.surface_m2 > 150 THEN 'large'
            WHEN b.surface_m2 > 100 THEN 'medium-large'
            WHEN b.surface_m2 > 50  THEN 'medium'
            ELSE 'small'
        END = p.surface_range
    LEFT JOIN surface_avg sa ON LOWER(TRIM(b.property_type)) = sa.property_type
    LEFT JOIN rooms_median rm  ON LOWER(TRIM(b.property_type)) = rm.property_type
    LEFT JOIN floor_median fm  ON LOWER(TRIM(b.property_type)) = fm.property_type
    CROSS JOIN stats s
    CROSS JOIN energy_global_mode eg
    WHERE b.listing_id IS NOT NULL
),

-- ====================================================
-- 11. SUPPRESSION DES DOUBLONS
-- ====================================================
deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY listing_id
            ORDER BY listing_id DESC
        ) AS row_num
    FROM cleaned
),

-- ====================================================
-- 12. COLONNES CALCULÉES FINALES
-- ====================================================
final AS (
    SELECT
        listing_id, property_type, country, city, neighborhood,
        surface_m2, num_rooms, num_bathrooms, floor, year_built,
        price, listing_date, condition, heating_type, parking,
        energy_rating,

        --  Âge du bien
        YEAR(CURRENT_DATE()) - year_built AS property_age,

        --  Prix au m²
        CASE
            WHEN surface_m2 > 0 AND price > 0
            THEN ROUND(price / surface_m2, 2)
            ELSE NULL
        END AS price_per_m2

    FROM deduplicated
    WHERE row_num = 1
)

SELECT * FROM final
