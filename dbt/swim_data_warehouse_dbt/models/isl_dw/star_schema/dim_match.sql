{# dim_match #}

-- References

WITH file_match_date AS (
    SELECT * FROM {{ ref("file_match_date") }}
)

, file_match_location AS (
    SELECT * FROM {{ ref("file_match_location") }}
)

, file_season AS (
    SELECT * FROM {{ ref("file_season") }}
)

-- Model

SELECT DISTINCT
    season.season_year          AS season_year,
    match_date.match_start_date AS match_start_date,
    match_date.match_end_date   AS match_end_date,
    location.country            AS country,
    location.state              AS state,
    location.city               AS city
FROM
    file_match_date     match_date
INNER JOIN
    file_match_location location
ON
    match_date.file_name = location.file_name
INNER JOIN
    file_season         season
ON
    match_date.file_name = season.file_name
