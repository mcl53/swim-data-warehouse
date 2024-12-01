SELECT
    CAST(file_name    AS VARCHAR) AS file_name,
    CAST(page_number  AS INTEGER) AS page_number,
    CAST(sex          AS VARCHAR) AS sex,
    CAST(distance     AS VARCHAR) AS distance,
    CAST(stroke       AS VARCHAR) AS stroke,
    CAST(round        AS VARCHAR) AS round
FROM
(
    VALUES
--  (file_name                             , page_number, sex    , distance, stroke             , round  )
    ('20191220_isl_vegas_day_1_results.pdf', 1          , 'Women', '100m'  , 'Butterfly'        , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 2          , 'Men'  , '100m'  , 'Butterfly'        , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 3          , 'Women', '50m'   , 'Breaststroke'     , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 4          , 'Men'  , '50m'   , 'Breaststroke'     , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 5          , 'Women', '400m'  , 'Individual Medley', 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 6          , 'Men'  , '400m'  , 'Individual Medley', 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 7          , 'Women', '4x100m', 'Freestyle Relay'  , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 11         , 'Men'  , '200m'  , 'Backstroke'       , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 12         , 'Women', '200m'  , 'Backstroke'       , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 13         , 'Men'  , '50m'   , 'Freestyle'        , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 14         , 'Women', '50m'   , 'Freestyle'        , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 15         , 'Men'  , '4x100m', 'Medley Relay'     , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 19         , 'Women', '200m'  , 'Freestyle'        , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 20         , 'Men'  , '200m'  , 'Freestyle'        , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 21         , 'Women', '50m'   , 'Backstroke'       , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 22         , 'Men'  , '50m'   , 'Backstroke'       , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 23         , 'Women', '200m'  , 'Breaststroke'     , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 24         , 'Men'  , '200m'  , 'Breaststroke'     , 'Final'),
    ('20191220_isl_vegas_day_1_results.pdf', 25         , 'Men'  , '4x100m', 'Freestyle Relay'  , 'Final')
)
page_event_type_hand_written
    (file_name                             , page_number, sex    , distance, stroke             , round  )
