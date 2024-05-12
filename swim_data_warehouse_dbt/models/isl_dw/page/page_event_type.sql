{{
      config(
        enabled = false
        )
}}

WITH skins_event_page_number AS
(
    -- Skins races follow a different format, therefore these are selected here and the below transformations are done
    -- in 2 stages: all events except skins and then all skins events.
    SELECT
        file_name,
        page_number
    FROM
        {{ source('isl_raw', 'pdf_page_word') }}
    WHERE
        ROUND(location_y, 5) IN (701.40022, 745.61726)
    AND word = 'Skin'
)

, standard_event_info AS
(
    SELECT
        pdf.file_name                                                                               AS file_name,
        pdf.page_number                                                                             AS page_number,
        pdf.word                                                                                    AS word,
        ROW_NUMBER() OVER (PARTITION BY pdf.file_name, pdf.page_number ORDER BY pdf.location_x ASC) AS word_order,
        COUNT(pdf.word) OVER (PARTITION BY pdf.file_name, pdf.page_number)                          AS num_words,
        CASE
            WHEN word_order = 1                                                      THEN 'sex'
            -- The first set of conditions matches individual events. These are 5 words when the stroke is 'Individual Medley', and 4 words otherwise.
            -- It also matches relay events where the distance is one word i.e. '4x100', these events also do not include the word 'Relay',
            -- and as such act the same as individual events with 4 words.
            -- The second set of conditions matches relay events where the distance is split over multiple words i.e. '4', 'x', '100m'.
            -- These events all have 7 words, and are the only events where this is the case after filtering out skins events.
            WHEN word_order =  2 AND num_words  IN (4, 5)
              OR word_order >= 2 AND word_order <= 4      AND num_words = 7          THEN 'distance'
            WHEN word_order > 2  AND word_order < 6       AND word_order < num_words THEN 'stroke'
            WHEN word_order = 6                                                      THEN 'relay'
            WHEN word_order = num_words                                              THEN 'round'
        END                                                                                         AS event_info_type,
        pdf.loaded_datetime                                                                         AS loaded_datetime
    FROM
        {{ source('isl_raw', 'pdf_page_word') }} pdf
    LEFT JOIN
        skins_event_page_number                  skin_page
    ON
        pdf.file_name   = skin_page.file_name
    AND pdf.page_number = skin_page.page_number
    WHERE
        ROUND(location_y, 5)  IN (701.40022, 745.61726)
    AND skin_page.page_number IS NULL -- Remove skins events
)

, skins_event_info AS
(
    SELECT
        pdf.file_name                                                                               AS file_name,
        pdf.page_number                                                                             AS page_number,
        pdf.word                                                                                    AS word,
        ROW_NUMBER() OVER (PARTITION BY pdf.file_name, pdf.page_number ORDER BY pdf.location_x ASC) AS word_order,
        COUNT(pdf.word) OVER (PARTITION BY pdf.file_name, pdf.page_number)                          AS num_words,
        CASE
            WHEN word_order = 1 THEN 'sex'
            WHEN word_order = 2 THEN 'distance'
            WHEN word_order = 3 THEN 'stroke'
            WHEN word_order = 4 THEN 'skin'
            WHEN word_order = 5 THEN 'race'
            WHEN word_order > 5 THEN 'round'
        END                                                                                         AS event_info_type,
        pdf.loaded_datetime                                                                         AS loaded_datetime
    FROM
        {{ source('isl_raw', 'pdf_page_word') }} pdf
    INNER JOIN -- Limit to skins events only
        skins_event_page_number                  skin_page
    ON
        pdf.file_name   = skin_page.file_name
    AND pdf.page_number = skin_page.page_number
    WHERE
        ROUND(location_y, 5) IN (701.40022, 745.61726)
)

, all_event_type_info AS
(
    SELECT
        file_name,
        page_number,
        word,
        word_order,
        event_info_type,
        loaded_datetime
    FROM
        standard_event_info
    UNION ALL
    SELECT
        file_name,
        page_number,
        word,
        word_order,
        event_info_type,
        loaded_datetime
    FROM
        skins_event_info
)
SELECT
    file_name                                    AS file_name,
    page_number                                  AS page_number,
    MAX(REPLACE(sex, '''s', ''))                 AS sex,
    STRING_AGG(distance, '' ORDER BY word_order) AS distance,
    STRING_AGG(stroke, ' ' ORDER BY word_order)  AS stroke,
    CASE
        WHEN MAX(skin) IS NOT NULL THEN TRUE
        ELSE                            FALSE
    END                                          AS is_skins_event,
    STRING_AGG(round, ' ' ORDER BY word_order)   AS round,
    loaded_datetime                              AS loaded_datetime
FROM
(
    PIVOT
        all_event_type_info
    ON
        event_info_type IN ('sex', 'distance', 'stroke', 'skin', 'round')
    USING
        MAX(word)
)
GROUP BY
    file_name,
    page_number,
    loaded_datetime
