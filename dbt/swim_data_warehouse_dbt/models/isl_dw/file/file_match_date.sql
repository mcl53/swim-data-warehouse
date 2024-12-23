------------------------------------------------------------------------------------------------------------------------
-- This model identifies the line of the PDF that contains match date as the one 2 after the line containing
-- Season/Series info.
-- This is always in the format ['Month Name', 'Start Date', '-', 'End Date']
-- e.g. ['October', '5', '-', '6']
------------------------------------------------------------------------------------------------------------------------
WITH file_match_date_line_num AS
(
    SELECT
        file_name       AS file_name,
        page_number     AS page_number,
        line_number + 2 AS match_date_line -- Use the line 2 after the Season/Series info
    FROM
        {{ ref("pdf_page_line_word") }}
    WHERE
        word        IN ('Season', 'Series')
    AND page_number =  1 -- Only use the first page in each file, as all subsequent pages will have the same info
)

, date_word_type AS
(
    SELECT
        CAST(word_type  AS VARCHAR) AS word_type,
        CAST(word_order AS INT    ) AS word_order
    FROM
    (
        VALUES
    --  (word_type   , word_order)
        ('month_name', 1         ),
        ('start_date', 2         ),
        ('end_date'  , 3         )
    )
    date_word_type
        (word_type   , word_order)
)

, file_match_date_word AS
(
    SELECT
        raw.file_name                AS file_name,
        raw.word                     AS word,
        -- After removing the dash this ROW_NUMBER will now match the order of values in the date_word_type CTE
        ROW_NUMBER() OVER (
            PARTITION BY
                raw.file_name
            ORDER BY
                raw.word_number ASC
        )                            AS word_order
    FROM
        {{ ref("pdf_page_line_word") }} raw
    INNER JOIN
        file_match_date_line_num        date_line
    ON
        raw.file_name   = date_line.file_name
    AND raw.page_number = date_line.page_number
    AND raw.line_number = date_line.match_date_line
    WHERE
        raw.word <> '-' -- Remove the dash word as it isn't useful
)

SELECT
    file_date.file_name                AS file_name,
    STRPTIME(
        CONCAT(
            file_date.start_date, ' ',
            file_date.month_name, ' ',
            season.season_year
        ),
        '%-d %B %Y')::DATE             AS match_start_date,
    STRPTIME(
        CONCAT(
            file_date.end_date,   ' ',
            file_date.month_name, ' ',
            season.season_year
        ),
        '%-d %B %Y')::DATE             AS match_end_date
FROM
    file_match_date_word     date_word
INNER JOIN
    date_word_type           word_type
ON
    date_word.word_order = word_type.word_order
PIVOT
(
    FIRST(word)
    FOR word_type IN
    (
        'month_name' AS month_name,
        'start_date' AS start_date,
        'end_date'   AS end_date
    )
    -- This specified GROUP BY is required as duckdb throws an error without it saying a reference to the column
    -- 'word_order' is ambiguous. Presumably this statement is compiled to a more verbose version that causes this error.
    GROUP BY
        file_name
)                            file_date
INNER JOIN
    {{ ref("file_season") }} season
ON
    file_date.file_name = season.file_name

UNION ALL

SELECT
    file_name,
    match_start_date,
    match_end_date
FROM
    {{ ref("file_match_date_hand_written") }}
