{# file_season_hand_written #}

SELECT
    CAST(file_name   AS VARCHAR) AS file_name,
    CAST(season_year AS INT    ) AS season_year
FROM
(
    VALUES
--  (file_name                             , season_year)
    ('20191220_isl_vegas_day_1_results.pdf', 2019       )
)
file_season_hand_written
    (file_name                             , season_year)
