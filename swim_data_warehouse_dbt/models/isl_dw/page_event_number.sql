SELECT
    file_name,
    page_number,
    word AS event_number,
    loaded_datetime
FROM
    {{ source('isl_raw', 'pdf_page_word') }}
WHERE                     -- Dallas , Other US, Vegas  , Other EU, London
    ROUND(location_y, 3) IN (598.236, 605.756 , 638.408, 643.868 , 675.393)
QUALIFY
    -- All files have 3 words that follow the pattern: ['Event', 'Number', 'x'], where x is the integer event number
    ROW_NUMBER() OVER (PARTITION BY file_name, page_number, loaded_datetime ORDER BY location_x ASC) = 3
