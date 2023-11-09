WITH all_match_locations AS
(
    SELECT
        file_name,
        match_location,
        match_location_type,
        loaded_datetime
    FROM
        {{ ref('eu_file_match_location') }}
    UNION ALL
    SELECT
        file_name,
        match_location,
        match_location_type,
        loaded_datetime
    FROM
        {{ ref('us_file_match_location') }}
)
SELECT
    file_name                                                         AS file_name,
    city                                                              AS city,
    state                                                             AS state,
    CASE
        WHEN city = 'Indianapolis' AND state = 'IN' THEN 'USA'
        ELSE                                             country_code
    END                                                               AS country_code,
    loaded_datetime                                                   AS loaded_datetime
FROM
(
    PIVOT
        all_match_locations
    ON
        match_location_type IN ('city', 'country_code', 'state') -- Only US locations will have a value for state
    USING
        MAX(match_location)
)
