WITH us_match_location AS
(
    -- Order words in the row of text at the given location_y from left to right for each PDF file
    SELECT
        file_name            AS file_name,
        word                 AS word,
        loaded_datetime      AS loaded_datetime,
        ROW_NUMBER() OVER
        (
            PARTITION BY
                file_name,
                location_y
            ORDER BY
                location_x
        )                    AS x_position
    FROM
        {{ source('isl_raw', 'pdf_page_word') }}
    WHERE
        location_y = 742.25708
    AND page_number = 1
)
, file_last_city_position AS
(
    -- Each file can have a variable number of words for the City
    -- However we can infer the final word of the city as it is always followed by a comma.
    -- E.g. for 'College Park, MD (USA)' -> ['College', 'Park,', 'MD', '(USA)']
    -- Park, is word we want to find, with x_location = 2.
    SELECT
        file_name       AS file_name,
        loaded_datetime AS loaded_datetime,
        MAX(x_position) AS last_city_position
    FROM
        us_match_location
    WHERE
        CONTAINS(word, ',')
    GROUP BY
        file_name,
        loaded_datetime
)
SELECT
    location.file_name                               AS file_name,
    STRING_AGG(REPLACE(location.word, ',', ''), ' ') AS match_location,
    'city'                                           AS match_location_type,
    location.loaded_datetime                         AS loaded_datetime
FROM
    us_match_location       location
INNER JOIN
    file_last_city_position last_pos
ON
    location.file_name       = last_pos.file_name
AND location.loaded_datetime = last_pos.loaded_datetime
WHERE
    location.x_position <= last_pos.last_city_position
GROUP BY
    location.file_name,
    location.loaded_datetime
UNION ALL
SELECT
    location.file_name                                                                 AS file_name,
    REPLACE(REPLACE(location.word,
        '(', ''),
        ')', '')                                                                       AS match_location,
    -- City is always followed by 2 words, the first being the state, and the second the country code.
    CASE
        WHEN location.x_position = last_pos.last_city_position + 1 THEN 'state'
        WHEN location.x_position = last_pos.last_city_position + 2 THEN 'country_code'
    END                                                                                AS match_location_type,
    location.loaded_datetime                                                           AS loaded_datetime
FROM
    us_match_location       location
INNER JOIN
    file_last_city_position last_pos
ON
    location.file_name       = last_pos.file_name
AND location.loaded_datetime = last_pos.loaded_datetime
WHERE
    location.x_position > last_pos.last_city_position
