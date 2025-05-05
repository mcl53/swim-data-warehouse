{# entry #}

-- Sources

WITH athlete AS (
    SELECT * FROM {{ ref('athlete') }}
)

-- Model

, entry_json AS (
    SELECT
        meet_name                             AS meet_name,
        athlete_id                            AS athlete_id,
        UNNEST(CAST(entries.ENTRY AS JSON[])) AS entry
    FROM
        athlete
    WHERE
        json_type(entries.ENTRY) = 'ARRAY'

    UNION ALL

    SELECT
        meet_name     AS meet_name,
        athlete_id    AS athlete_id,
        entries.ENTRY AS entry
    FROM
        athlete
    WHERE
        json_type(entries.ENTRY) = 'OBJECT'
)

SELECT
    meet_name                                 AS meet_name,
    athlete_id                                AS athlete_id,
    CAST(entry->>'@eventid'          AS INT ) AS event_id,
    CAST(entry->>'@heat'             AS INT ) AS event_heat_number,
    CAST(entry->>'@lane'             AS INT ) AS lane_number,
    CAST(
        CASE entry->>'@entrytime'
            -- NT denotes No Time for an entry.
            WHEN 'NT' THEN NULL
            ELSE           entry->>'@entrytime'
        END
        AS INTERVAL
    )                                         AS entry_time,
    CAST(entry->'MEETINFO'->>'@date' AS DATE) AS entry_time_swam_date
FROM
    entry_json
