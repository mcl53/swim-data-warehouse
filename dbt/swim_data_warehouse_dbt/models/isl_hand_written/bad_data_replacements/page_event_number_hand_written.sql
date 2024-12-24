{# page_event_number_hand_written #}

SELECT
    CAST(file_name    AS VARCHAR) AS file_name,
    CAST(page_number  AS INTEGER) AS page_number,
    CAST(event_number AS INTEGER) AS event_number
FROM
(
    VALUES
--  (file_name                             , page_number, event_number)
    ('20191220_isl_vegas_day_1_results.pdf', 1          , 1           ),
    ('20191220_isl_vegas_day_1_results.pdf', 2          , 2           ),
    ('20191220_isl_vegas_day_1_results.pdf', 3          , 3           ),
    ('20191220_isl_vegas_day_1_results.pdf', 4          , 4           ),
    ('20191220_isl_vegas_day_1_results.pdf', 5          , 5           ),
    ('20191220_isl_vegas_day_1_results.pdf', 6          , 6           ),
    ('20191220_isl_vegas_day_1_results.pdf', 7          , 7           ),
    ('20191220_isl_vegas_day_1_results.pdf', 11         , 8           ),
    ('20191220_isl_vegas_day_1_results.pdf', 12         , 9           ),
    ('20191220_isl_vegas_day_1_results.pdf', 13         , 10          ),
    ('20191220_isl_vegas_day_1_results.pdf', 14         , 11          ),
    ('20191220_isl_vegas_day_1_results.pdf', 15         , 12          ),
    ('20191220_isl_vegas_day_1_results.pdf', 19         , 13          ),
    ('20191220_isl_vegas_day_1_results.pdf', 20         , 14          ),
    ('20191220_isl_vegas_day_1_results.pdf', 21         , 15          ),
    ('20191220_isl_vegas_day_1_results.pdf', 22         , 16          ),
    ('20191220_isl_vegas_day_1_results.pdf', 23         , 17          ),
    ('20191220_isl_vegas_day_1_results.pdf', 24         , 18          ),
    ('20191220_isl_vegas_day_1_results.pdf', 25         , 19          )
)
page_event_number_hand_written
    (file_name                             , page_number, event_number)
