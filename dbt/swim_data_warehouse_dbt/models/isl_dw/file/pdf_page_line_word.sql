{# pdf_page_line_word #}

------------------------------------------------------------------------------------------------------------------------
-- The CTEs in this model both have a set of columns that are generated sequentially from the output of the previous
-- column(s), with the first taking all the text on a page and splitting that into each line of text from the page,
-- and the second taking each line and splitting it into each word within the line.
-- They both follow the same set of steps:
-- 1. Split the text field into an array column on the appropriate delimiter
--     * New line for splitting page text into lines
--     * Space character for splitting a line into words
-- 2. Create a second array column containing a contiguous range of integers that is the same length as the previous
--    array
--     * e.g. If the above array has 5 elements, this will be [1, 2, 3, 4, 5]
-- 3. Map the 2 above arrays. This generates a set of key-value pairs, where the key is from the integer array,
--    and the value is from the text array
-- 4. Unnest the map into one row per key-value pair
--     * This then allows the key and value to be pulled out into their own columns, with the key used as an index
--     * i.e. the first line is given line_num 1, the first word in a line is given word_num 1
--
-- This is all done in one model as selecting the intermediate values from the columns in this process is very slow,
-- whereas this format seems to allow DuckDB to optimise the query with lazy evaluation, and so makes this much faster
------------------------------------------------------------------------------------------------------------------------

-- Sources

WITH isl_raw__pdf_page AS (
    SELECT * FROM {{ source('raw', 'pdf_page') }}
)

-- Model

, pdf_page_lines AS (
    -- Use multiple lateral aliases to split PDF page text into numbered lines, one row per line.
    SELECT
        file_name                           AS file_name,
        page_number                         AS page_number,
        STRING_SPLIT_REGEX(page_text, '\n') AS lines,
        GENERATE_SERIES(1, LEN(lines))      AS line_nums,
        MAP(line_nums, lines)               AS lines_map,
        UNNEST(MAP_ENTRIES(lines_map))      AS line_num_value
    FROM
        isl_raw__pdf_page
    QUALIFY
        -- Limit here to the most recently loaded version of each file
        1 = ROW_NUMBER() OVER (
                PARTITION BY
                    file_name,
                    page_number
                ORDER BY
                    loaded_datetime DESC
            )
)
, pdf_page_line_words AS (
    -- Use multiple lateral aliases to split line text into numbered words, one row per word.
    SELECT
        file_name                               AS file_name,
        page_number                             AS page_number,
        line_num_value.key                      AS line_number,
        STRING_SPLIT(line_num_value.value, ' ') AS line_words,
        GENERATE_SERIES(1, LEN(line_words))     AS word_nums,
        MAP(word_nums, line_words)              AS words_map,
        UNNEST(MAP_ENTRIES(words_map))          AS word_num_value
    FROM
        pdf_page_lines
)

SELECT
    file_name                      AS file_name,
    page_number                    AS page_number,
    line_number                    AS line_number,
    ROW_NUMBER() OVER (
        PARTITION BY
            file_name,
            page_number,
            line_number
        ORDER BY
            word_num_value.key ASC
    )                              AS word_number,
    word_num_value.value           AS word
FROM
    pdf_page_line_words
WHERE
    word_num_value.value <> ''
