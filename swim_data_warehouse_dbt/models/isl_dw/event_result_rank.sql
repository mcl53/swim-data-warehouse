{{
      config(
        enabled = false
        )
}}

WITH pdf_table_rows AS
(
    SELECT
        file_name,
        page_number,
        word,
        location_x AS min_location_x,
        location_x + width AS max_location_x,
        location_y AS min_location_y,
        location_y + height AS max_location_y,
        CASE
            WHEN min_location_y BETWEEN LAG(min_location_y) OVER rows_per_page_top_down AND LAG(max_location_y) OVER rows_per_page_top_down
            OR max_location_y BETWEEN LAG(min_location_y) OVER rows_per_page_top_down AND LAG(max_location_y) OVER rows_per_page_top_down
            OR (min_location_y < LAG(min_location_y) OVER rows_per_page_top_down AND max_location_y > LAG(max_location_y) OVER rows_per_page_top_down) THEN TRUE
            ELSE FALSE
        END AS in_same_row_as_previous,
        width,
        height,
        loaded_datetime
    FROM
        isl_raw.pdf_page_word
    WHERE
        file_name = '20191027_isl_results_budapest_sunday.pdf' AND page_number > 6 AND
        ROUND(location_y, 5) < 564.51417 -- Need to update these boundaries to be dynamic - don't work with budapest sunday
    AND ROUND(location_y, 5) > 99.99189
    WINDOW
        rows_per_page_top_down AS
        (
            PARTITION BY
                file_name,
                page_number,
                loaded_datetime
            ORDER BY
                location_y DESC,
                location_x ASC
        )
    ORDER BY
        location_y DESC,
        location_x ASC
)
, pdf_table_row_number AS
(
    SELECT
        *,
        SUM(
            CASE in_same_row_as_previous
                WHEN FALSE THEN 1
                ELSE            0
            END
        ) OVER (PARTITION BY file_name, page_number, loaded_datetime ORDER BY min_location_y DESC, min_location_x ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS table_rows_count
    FROM
        pdf_table_rows
)
, rows_per_swimmer AS
(
    SELECT
        table_row.file_name,
        table_row.page_number,
        table_row.loaded_datetime,
        CAST(MAX(table_row.table_rows_count) / swimmer_count.swimmer_count AS INT) AS rows_per_swimmer
    FROM
        pdf_table_row_number table_row
    INNER JOIN
        {{ ref('page_event_type') }} event_type
    ON
        table_row.file_name = event_type.file_name
    AND table_row.page_number = event_type.page_number
    AND table_row.loaded_datetime = event_type.loaded_datetime
    INNER JOIN
        {{ ref('event_swimmer_count') }} swimmer_count
    ON
        event_type.is_skins_event = swimmer_count.is_skins_event
    AND event_type.round = swimmer_count.round
    GROUP BY
        table_row.file_name,
        table_row.page_number,
        table_row.loaded_datetime,
        swimmer_count.swimmer_count
)
SELECT
    table_row.*,
    (table_row.table_rows_count + total_rows.rows_per_swimmer - 1) // total_rows.rows_per_swimmer AS swimmer_number
FROM
    pdf_table_row_number table_row
INNER JOIN
    rows_per_swimmer total_rows
ON
    table_row.file_name = total_rows.file_name
AND table_row.page_number = total_rows.page_number
AND table_row.loaded_datetime = total_rows.loaded_datetime
ORDER BY
    table_row.file_name,
    table_row.page_number,
    table_row.loaded_datetime,
    table_row.min_location_y DESC,
    table_row.min_location_x ASC

{# SELECT
    *
FROM
    isl_raw.pdf_page_word
WHERE
    file_name = '20191019_dallas_lewisville_isl_results_day_1.pdf' #}

{# SELECT
    *
FROM
    isl_raw.pdf_page_word
WHERE
    file_name = '20191027_isl_results_budapest_sunday.pdf' #}
