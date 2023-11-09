WITH match_location_word_postition AS
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
                location_x ASC
        )                    AS x_position
    FROM
        {{ source('isl_raw', 'pdf_page_word') }}
    WHERE
        location_y  = 789.08200
    AND page_number = 1
)
-- Expected PDF format has 'London (GBR)' in the row of text selected above.
-- In this example, the first word is 'London' (the City), and the second is '(GBR)' (the Country Code)
SELECT
    file_name                      AS file_name,
    REPLACE(REPLACE(REPLACE(word,
        ',', ''),
        '(', ''),
        ')', '')                   AS match_location,
    CASE x_position
        WHEN 1 THEN 'city'
        WHEN 2 THEN 'country_code'
    END                            AS match_location_type,
    loaded_datetime                AS loaded_datetime
FROM
    match_location_word_postition
