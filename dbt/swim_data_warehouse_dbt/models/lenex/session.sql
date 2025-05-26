{# session #}

-- Sources

WITH meet AS (
    SELECT * FROM {{ ref('meet') }}
)

-- Model

, session_json AS (
    SELECT
        meet_name                                AS meet_name,
        meet_city                                AS meet_city,
        meet_year                                AS meet_year,
        UNNEST(CAST(sessions.SESSION AS JSON[])) AS session
    FROM
        meet
)

SELECT
    meet_name                                   AS meet_name,
    meet_city                                   AS meet_city,
    meet_year                                   AS meet_year,
    CAST(session->>'@date'         AS DATE)     AS session_date,
    CAST(session->>'@daytime'      AS TIME)     AS session_start_time,
    CAST(session->>'@number'       AS INT )     AS session_number,
    CAST(session.POOL->>'@lanemin' AS INT )     AS session_min_lane_number,
    CAST(session.POOL->>'@lanemax' AS INT ) - 1 AS session_max_lane_number,
    session.EVENTS                              AS session_events
FROM
    session_json
