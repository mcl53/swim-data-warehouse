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

SELECT
    file_name                               AS file_name,
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
