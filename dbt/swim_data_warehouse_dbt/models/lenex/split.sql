{# split #}

-- Sources

WITH result AS (
    SELECT * FROM {{ ref('result') }}
)

-- Model

, split_json AS (
    SELECT
        meet_name                            AS meet_name,
        athlete_id                           AS athlete_id,
        event_id                             AS event_id,
        UNNEST(CAST(splits.SPLIT AS JSON[])) AS split
    FROM
        result
    WHERE
        json_type(splits.SPLIT) = 'ARRAY'

    UNION ALL

    SELECT
        meet_name    AS meet_name,
        athlete_id   AS athlete_id,
        event_id     AS event_id,
        splits.SPLIT AS split
    FROM
        result
    WHERE
        json_type(splits.SPLIT) = 'OBJECT'
)

SELECT
    meet_name                        AS meet_name,
    athlete_id                       AS athlete_id,
    event_id                         AS event_id,
    CAST(split->>'@distance' AS INT) AS split_distance,
    CAST(
        CASE split->>'@swimtime'
            WHEN 'NT' THEN NULL
            ELSE           split->>'@swimtime'
        END
        AS INTERVAL
    )                                AS split_cumulative_time
FROM
    split_json
