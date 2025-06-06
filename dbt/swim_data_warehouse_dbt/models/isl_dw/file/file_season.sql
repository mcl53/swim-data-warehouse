{# file_season #}

------------------------------------------------------------------------------------------------------------------------
-- The line containing season information has words in the format '2019 ISL Season', where Season and Series are used
-- interchangably. We only care about the year, therefore filter to the first word on this line.
------------------------------------------------------------------------------------------------------------------------

-- References

WITH file_season_hand_written AS (
    SELECT * FROM {{ ref("file_season_hand_written") }}
)

, pdf_page_line_word AS (
    SELECT * FROM {{ ref("pdf_page_line_word") }}
)

-- Model

, file_season_line_num AS (
    -- The line number that matches season information can be found on the first page.
    SELECT
        file_name,
        page_number,
        line_number
    FROM
        pdf_page_line_word
    WHERE
        word        IN ('Season', 'Series')
    AND page_number =  1
)

SELECT
    raw.file_name AS file_name,
    raw.word      AS season_year
FROM
    pdf_page_line_word raw
INNER JOIN
    file_season_line_num      season_line
ON
    raw.file_name   = season_line.file_name
AND raw.page_number = season_line.page_number
AND raw.line_number = season_line.line_number
WHERE
    raw.word_number = 1

UNION ALL

SELECT
    file_name,
    season_year
FROM
    file_season_hand_written
