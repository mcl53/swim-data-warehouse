WITH page_event_number_line_number AS
(
    SELECT
        file_name,
        page_number,
        line_number
    FROM
        {{ ref('pdf_page_line_word') }}
    WHERE
        word = 'Event'
    -- The word 'Event' appears twice in all files, as both have a system event number and a sequential event number.
    -- Here we filter to only the second of these, the sequential event number.
    QUALIFY
        line_number = MAX(line_number) OVER (
                          PARTITION BY
                              file_name,
                              page_number
                      )
)

SELECT
    word.file_name         AS file_name,
    word.page_number       AS page_number,
    CAST(word.word AS INT) AS event_number
FROM
    {{ ref('pdf_page_line_word') }} word
INNER JOIN
    page_event_number_line_number   event_line
ON
    word.file_name   = event_line.file_name
AND word.page_number = event_line.page_number
AND word.line_number = event_line.line_number
WHERE
    word NOT IN ('Event', 'Number')

UNION ALL

SELECT
    file_name,
    page_number,
    event_number
FROM
    {{ ref('page_event_number_hand_written') }}
