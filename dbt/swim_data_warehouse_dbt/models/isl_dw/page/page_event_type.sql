WITH event_word AS
(
    -- Pull out words relevant to the event type on each page
    SELECT
        file_name               AS file_name,
        page_number             AS page_number,
        word                    AS word,
        ROW_NUMBER() OVER (
            PARTITION BY
                file_name,
                page_number
            ORDER BY
                word_number ASC
        )                       AS word_order
    FROM
        {{ ref('pdf_page_line_word') }}
    WHERE
        line_number  = 2
    AND word_number >= 6
)
, round_word_order_num AS
(
    -- Determine the last word that denotes the event distance,
    -- and the first word that denotes the event round
    SELECT
        file_name                          AS file_name,
        page_number                        AS page_number,
        MAX(word_order) FILTER (
            word LIKE '%0m'
        )                                  AS last_distance_word_order_num,
        COALESCE(
            MIN(word_order) FILTER (
                word IN ('Final', 'Round')
            ),
            MAX(word_order) + 1
        )                                  AS first_round_word_order_num
    FROM
        event_word
    GROUP BY
        file_name,
        page_number
)
, word_event_type AS
(
    -- The different parts of the event type may contain different numbers of words each.
    -- However, they always follow the order of: Sex, Distance, Stroke, Round.
    -- The first word is always the sex.
    -- We then know the last word of the distance, therefore all words from the first to the last
    -- distance word are to do with distance.
    -- We also know the first round word, therefore the stroke words are between the last distance
    -- word and the first round word.
    -- All remaining words after the first round word are to do with the round.
    SELECT
        word.file_name   AS file_name,
        word.page_number AS page_number,
        word.word        AS word,
        word.word_order  AS word_order,
        CASE
            WHEN word.word_order  = 1                                      THEN 'sex'
            WHEN word.word_order >  1
             AND word.word_order <= round_num.last_distance_word_order_num THEN 'distance'
            WHEN word.word_order >  round_num.last_distance_word_order_num
             AND word.word_order <  round_num.first_round_word_order_num   THEN 'stroke'
            WHEN word.word_order >= round_num.first_round_word_order_num   THEN 'round'
        END              AS event_word_type
    FROM
        event_word           word
    LEFT JOIN
        round_word_order_num round_num
    ON
        word.file_name   = round_num.file_name
    AND word.page_number = round_num.page_number
)
SELECT
    file_name                                                         AS file_name,
    page_number                                                       AS page_number,
    FIRST(REPLACE(sex, '''s', '')) FILTER (sex IS NOT NULL)           AS sex,
    STRING_AGG(distance,       ''  ORDER BY word_order ASC)           AS distance,
    STRING_AGG(stroke,         ' ' ORDER BY word_order ASC)           AS stroke,
    COALESCE(STRING_AGG(round, ' ' ORDER BY word_order ASC), 'Final') AS round
FROM (
    PIVOT
        word_event_type
    ON
        event_word_type IN ('sex', 'distance', 'stroke', 'round')
    USING
        FIRST(word)
)
GROUP BY
    file_name,
    page_number

UNION ALL

SELECT
    file_name,
    page_number,
    sex,
    distance,
    stroke,
    round
FROM
    {{ ref('page_event_type_hand_written') }}
