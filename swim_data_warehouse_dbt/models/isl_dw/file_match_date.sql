WITH match_month_date AS
(
    -- Dates always come in the format 'Month start - end' e.g. 'October 5 - 6'
    -- Therefore the words here are
    --  'October' - 1
    --  '5'       - 2
    --  '-'       - 3
    --  '6'       - 4
    SELECT
        file_name                                                          AS file_name,
        word                                                               AS word,
        ROW_NUMBER() OVER (PARTITION BY file_name ORDER BY location_x ASC) AS x_position,
        loaded_datetime                                                    AS loaded_datetime
    FROM
        {{ source('isl_raw', 'pdf_page_word') }}
    WHERE
        location_y  IN (722.51708, 768.08200)
    AND page_number =  1
)
, match_month_date_description AS
(
    -- Convert the integer x_position values to a descriptive string,
    -- as SQLMesh doesn't like to PIVOT to columns with integer names
    SELECT
        file_name                         AS file_name,
        word                              AS word,
        x_position                        AS x_position,
        CASE x_position
            WHEN 1 THEN 'match_month'
            WHEN 2 THEN 'match_start_day'
            WHEN 3 THEN 'dash'
            WHEN 4 THEN 'match_end_day'
        END                               AS word_description,
        loaded_datetime                   AS loaded_datetime
    FROM
        match_month_date
)
, match_start_end_dates AS
(
    -- This pivot can be included in the final select and joined to with duckdb,
    -- however SQLMesh cannot parse it and throws a sqlglot based error.
    PIVOT
        match_month_date_description
    ON
        word_description IN ('match_month', 'match_start_day', 'match_end_day')
    USING
        FIRST(word)
    GROUP BY
        file_name,
        loaded_datetime
)
, match_year AS
(
    SELECT
        file_name       AS file_name,
        FIRST(word)     AS word,
        loaded_datetime AS loaded_datetime
    FROM
        {{ source('isl_raw', 'pdf_page_word') }}
    WHERE
        location_y  IN (761.99708, 810.08200)
    AND page_number =  1
    GROUP BY
        file_name,
        loaded_datetime
)
-- Concat the words from the 2 CTEs above into a date in the format '5October2019'
-- This is then converted to a timestamp by STRPTIME, and then the time component removed.
SELECT
    m_dates.file_name                                                                                    AS file_name,
    CAST(STRPTIME(CONCAT(m_dates.match_start_day, m_dates.match_month, m_year.word), '%-d%B%Y') AS DATE) AS match_start_date,
    CAST(STRPTIME(CONCAT(m_dates.match_end_day,   m_dates.match_month, m_year.word), '%-d%B%Y') AS DATE) AS match_end_date,
    m_dates.loaded_datetime                                                                              AS loaded_datetime
FROM
    match_start_end_dates m_dates
INNER JOIN
    match_year            m_year
ON
    m_dates.file_name       = m_year.file_name
AND m_dates.loaded_datetime = m_year.loaded_datetime
