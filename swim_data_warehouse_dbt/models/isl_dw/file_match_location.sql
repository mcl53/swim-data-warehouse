------------------------------------------------------------------------------------------------------------------------
-- This model identifies the line of the PDF that contains match location as the one that follows the line containing
-- Season/Series info.
-- There can be a varying number of words that make up the location info, e.g. a city could be 2 words, such as
-- 'Las Vegas'.
-- Therefore, location information is identified as follows:
-- 1. The final word in the location line is the 3 letter country code
--     * with the exception of Indianapolis match files, as the country code is not included in these at all
-- 2. The word before the country code is the US state if it is a US based match
--     * This is identified as where this word is 2 letters long
-- 3. All other words that are not the country or the state make up the city, which are concatenated together
--
-- Each of the resultant CTEs from these steps then contains one value per file, and can then be joined
------------------------------------------------------------------------------------------------------------------------

WITH file_match_location_line_num AS
(
    SELECT
        file_name       AS file_name,
        page_number     AS page_number,
        line_number + 1 AS event_num_line -- Use the line after the Season/Series info
    FROM
        {{ ref('pdf_page_line_word') }}
    WHERE
        word        IN ('Season', 'Series')
    AND page_number =  1 -- Only use the first page in each file, as all subsequent pages will have the same info
)
, file_match_location_line_word AS
(
    SELECT
        raw.file_name            AS file_name,
        raw.page_number          AS page_number,
        raw.line_number          AS line_number,
        raw.word_number          AS word_number,
        REPLACE(REPLACE(REPLACE(
            raw.word, ',', ''),
                      '(', ''),
                      ')', '')   AS word
    FROM
        {{ ref('pdf_page_line_word') }} raw
    INNER JOIN
        file_match_location_line_num    location_line
    ON
        raw.file_name       = location_line.file_name
    AND raw.page_number     = location_line.page_number
    AND raw.line_number     = location_line.event_num_line
    WHERE
        raw.word <> ''
)
, file_match_country AS
(
    SELECT
        file_name                                       AS file_name,
        -- Indianapolis files do not have a country in the location info, and all other files do.
        -- All country codes are 3 letters long, therefore we can infer if the last word on the line is not 3 letters
        -- long, this is an Indianapolis file so the country must be USA.
        IF(LEN(word) = 3, word       , 'USA')           AS country,
        -- For Indianapolis files, the last word on this line is the state rather than the country. Therefore for these
        -- files only, we add 1 to the word_number for where it would have said USA, if this were present in the file.
        IF(LEN(word) = 3, word_number, word_number + 1) AS word_number
    FROM
        file_match_location_line_word
    QUALIFY
        -- Filter to only the last word on this line
        1 = ROW_NUMBER() OVER (
                PARTITION BY
                    file_name
                ORDER BY
                    word_number DESC
            )
)
, file_match_state AS
(
    SELECT
        location.file_name   AS file_name,
        location.word        AS state,
        location.word_number AS word_number
    FROM
        file_match_location_line_word location
    INNER JOIN
        file_match_country            country
    ON
        location.file_name = country.file_name
    WHERE
        location.word_number = country.word_number - 1 -- State is the word before country
    AND LEN(location.word)   = 2 -- Non-US matches do not have a state, so these will be filtered out here
)
, file_match_city AS
(
    SELECT
        location.file_name                                               AS file_name,
        STRING_AGG(location.word, ' ' ORDER BY location.word_number ASC) AS city -- Concat city names with more than 1 word
    FROM
        file_match_location_line_word location
    INNER JOIN
        file_match_country            country
    ON
        location.file_name = country.file_name
    LEFT JOIN
        file_match_state              state
    ON
        location.file_name = state.file_name
    WHERE
        location.word_number < COALESCE(state.word_number, country.word_number)
    GROUP BY
        location.file_name
)
SELECT
    country.file_name,
    country.country,
    state.state,
    city.city
FROM
    file_match_country country
LEFT JOIN
    file_match_state   state
ON
    country.file_name = state.file_name
INNER JOIN
    file_match_city    city
ON
    country.file_name = city.file_name
