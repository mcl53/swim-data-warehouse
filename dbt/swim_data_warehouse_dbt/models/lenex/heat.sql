{# heat #}

-- Sources

WITH event AS (
    SELECT * FROM {{ ref('event') }}
)

-- Model

, heat_json AS (
    -- Events with more than one heat are represented by an array of heat objects, whereas events
    -- with only one heat are not in an array.
    -- Here these are split up and arrays unnested so that we end up with one heat per row.
    SELECT
        meet_name                            AS meet_name,
        meet_city                            AS meet_city,
        meet_year                            AS meet_year,
        session_number                       AS session_number,
        event_id                             AS event_id,
        UNNEST(CAST((heats.HEAT) AS JSON[])) AS heat
    FROM
        event
    WHERE
        json_type(heats.HEAT) = 'ARRAY'

    UNION ALL

    SELECT
        meet_name      AS meet_name,
        meet_city      AS meet_city,
        meet_year      AS meet_year,
        session_number AS session_number,
        event_id       AS event_id,
        heats.HEAT     AS heat
    FROM
        event
    WHERE
        json_type(heats.HEAT) = 'OBJECT'
)

SELECT
    meet_name                       AS meet_name,
    meet_city                       AS meet_city,
    meet_year                       AS meet_year,
    session_number                  AS session_number,
    event_id                        AS event_id,
    CAST(heat->>'@heatid'  AS INT ) AS heat_id,
    CAST(heat->>'@number'  AS INT ) AS event_heat_number,
    CAST(heat->>'@daytime' AS TIME) AS heat_start_time
FROM
    heat_json
