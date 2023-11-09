SELECT
    file_name,
    page_number,
    word AS event_number,
    loaded_datetime
FROM
    {{ source('isl_raw', 'pdf_page_word') }}
WHERE
    ROUND(location_y, 5) IN (605.75611, 643.8682)
QUALIFY
    -- All files have 3 words that follow the pattern: ['Event', 'Number', 'x'], where x is the integer event number
    ROW_NUMBER() OVER (PARTITION BY file_name, page_number, loaded_datetime ORDER BY location_x ASC) = 3
