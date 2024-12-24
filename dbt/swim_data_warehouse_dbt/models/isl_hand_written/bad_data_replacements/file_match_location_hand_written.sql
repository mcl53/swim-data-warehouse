{# file_match_location_hand_written #}

SELECT
    CAST(file_name AS VARCHAR) AS file_name,
    CAST(country   AS VARCHAR) AS country,
    CAST(state     AS VARCHAR) AS state,
    CAST(city      AS VARCHAR) AS city
FROM
(
    VALUES
--  (file_name                             , country, state, city       )
    ('20191220_isl_vegas_day_1_results.pdf', 'USA'  , 'NV' , 'Las Vegas')
)
file_match_location_hand_written
    (file_name                             , country, state, city       )
