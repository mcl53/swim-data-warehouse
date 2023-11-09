WITH us_match_season AS
(
    SELECT
        file_name                         AS file_name,
        -- Some files use Series instead of Season.
        -- This ensures all files use the same wording.
        REPLACE(word, 'Series', 'Season') AS word,
        location_x                        AS location_x,
        loaded_datetime                   AS loaded_datetime
    FROM
        {{ source('isl_raw', 'pdf_page_word') }}
    WHERE
        page_number = 1
    AND location_y  = 761.99708
)

, eu_match_season AS
(
    SELECT
        file_name                         AS file_name,
        -- Some files use Series instead of Season.
        -- This ensures all files use the same wording.
        REPLACE(word, 'Series', 'Season') AS word,
        location_x                        AS location_x,
        loaded_datetime                   AS loaded_datetime
    FROM
        {{ source('isl_raw', 'pdf_page_word') }}
    WHERE
        page_number = 1
    AND location_y  = 810.08200
)

SELECT
    file_name             AS file_name,
    FIRST(word)           AS season_year,
    STRING_AGG(word, ' ') AS season_name,
    loaded_datetime       AS loaded_datetime
FROM
    us_match_season
GROUP BY
    file_name,
    loaded_datetime
UNION ALL
SELECT
    file_name             AS file_name,
    FIRST(word)           AS season_year,
    STRING_AGG(word, ' ') AS season_name,
    loaded_datetime       AS loaded_datetime
FROM
    eu_match_season
GROUP BY
    file_name,
    loaded_datetime
