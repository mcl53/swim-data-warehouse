{# result #}

-- Sources

WITH athlete AS (
    SELECT * FROM {{ ref('athlete') }}
)

-- Model

, result_json AS (
    SELECT
        meet_name                              AS meet_name,
        meet_city                              AS meet_city,
        meet_year                              AS meet_year,
        athlete_id                             AS athlete_id,
        UNNEST(CAST(results.RESULT AS JSON[])) AS result
    FROM
        athlete
    WHERE
        json_type(results.RESULT) = 'ARRAY'

    UNION ALL

    SELECT
        meet_name      AS meet_name,
        meet_city      AS meet_city,
        meet_year      AS meet_year,
        athlete_id     AS athlete_id,
        results.RESULT AS result
    FROM
        athlete
    WHERE
        json_type(results.RESULT) = 'OBJECT'
)

SELECT
    meet_name                                 AS meet_name,
    meet_city                                 AS meet_city,
    meet_year                                 AS meet_year,
    athlete_id                                AS athlete_id,
    CAST(result->>'@eventid'          AS INT) AS event_id,
    CAST(result->>'@place'            AS INT) AS event_place,
    CAST(
        -- NT denotes No Time.
        CASE result->>'@swimtime'
            WHEN 'NT' THEN NULL
            ELSE           result->>'@swimtime'
        END
        AS INTERVAL
    )                                         AS finish_time,
    INTERVAL (
        -- Multiply by 10 as reaction times are recorded in 1/100ths of seconds.
        CAST(result->>'@reactiontime' AS INT) * 10
    ) MILLISECONDS                            AS reaction_time,
    CAST(result->>'@points'           AS INT) AS fina_points,
    result->>'@status'                        AS status,
    CAST(result->>'@heatid'           AS INT) AS heat_id,
    result->>'@heat'                          AS event_heat_number,
    CAST(result->>'@lane'             AS INT) AS lane_number,
    result.SPLITS                             AS splits
FROM
    result_json
