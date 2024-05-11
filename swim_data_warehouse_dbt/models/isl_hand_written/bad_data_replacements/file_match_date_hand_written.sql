SELECT
    CAST(file_name        AS VARCHAR) AS file_name,
    CAST(match_start_date AS DATE   ) AS match_start_date,
    CAST(match_end_date   AS DATE   ) AS match_end_date
FROM
(
    VALUES
--  (file_name                             , match_start_date, match_end_date)
    ('20191220_isl_vegas_day_1_results.pdf', '2019-12-20'    , '2019-12-21'  )
)
file_match_date_hand_written
    (file_name                             , match_start_date, match_end_date)
