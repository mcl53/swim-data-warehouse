{# relay_split #}

-- Sources

WITH relay_result AS (
    SELECT * FROM {{ ref('relay_result') }}
)

-- Model

, split_json AS (
    SELECT
        meet_name                            AS meet_name,
        club_code                            AS club_code,
        event_id                             AS event_id,
        UNNEST(CAST(splits.SPLIT AS JSON[])) AS split
    FROM
        relay_result
)

SELECT
    meet_name           AS meet_name,
    club_code           AS club_code,
    event_id            AS event_id,
    split->>'@distance' AS split_distance,
    CAST(
        -- NT denotes No Time.
        CASE split->>'@swimtime'
            WHEN 'NT' THEN NULL
            ELSE           split->>'@swimtime'
        END
        AS INTERVAL
    )                                AS split_cumulative_time
FROM
    split_json
