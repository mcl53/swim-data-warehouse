{# meet #}

-- Sources

WITH raw__lenex AS (
    SELECT * FROM {{ source('raw', 'lenex') }}
)

-- Model

, meet_json AS (
    SELECT
        file_name                      AS file_name,
        file_contents.LENEX.MEETS.MEET AS meet
    FROM
        raw__lenex
)

, meet_decomposed AS (
    SELECT
        meet->>'@name'                          AS meet_name,
        meet->>'@city'                          AS meet_city,
        meet->>'@nation'                        AS meet_country,
        meet->>'@course'                        AS pool_length,
        CAST(meet.POOL->>'@lanemin' AS INT)     AS min_lane_number,
        CAST(meet.POOL->>'@lanemax' AS INT) - 1 AS max_lane_number,
        meet.SESSIONS                           AS sessions,
        meet.CLUBS                              AS clubs
    FROM
        meet_json
)

, meet_session_year AS (
    SELECT
        meet_name AS meet_name,
        meet_city AS meet_city,
        YEAR(
            CAST(
                UNNEST(CAST(sessions.SESSION AS JSON[]))->>'@date'
                AS DATE
            )
        )         AS meet_year
    FROM
        meet_decomposed
)

, meet_year AS (
    SELECT
        m.meet_name      AS meet_name,
        m.meet_city      AS meet_city,
        MIN(s.meet_year) AS meet_year
    FROM
        meet_decomposed   m
    INNER JOIN
        meet_session_year s
    ON
        m.meet_name = s.meet_name
    AND m.meet_city = s.meet_city
    GROUP BY
        m.meet_name,
        m.meet_city
)

SELECT
    m.meet_name,
    m.meet_city,
    y.meet_year,
    m.meet_country,
    m.pool_length,
    m.min_lane_number,
    m.max_lane_number,
    m.sessions,
    m.clubs
FROM
    meet_decomposed m
INNER JOIN
    meet_year       y
ON
    m.meet_name = y.meet_name
AND m.meet_city = y.meet_city
