SELECT
    season.season_year          AS season_year,
    match_date.match_start_date AS match_start_date,
    match_date.match_end_date   AS match_end_date,
    location.country            AS country,
    location.state              AS state,
    location.city               AS city,
    LIST(match_date.file_name)  AS file_names
FROM
    {{ ref('file_match_date') }}     match_date
INNER JOIN
    {{ ref('file_match_location') }} location
ON
    match_date.file_name = location.file_name
INNER JOIN
    {{ ref('file_season') }}         season
ON
    match_date.file_name = season.file_name
GROUP BY
    ALL
