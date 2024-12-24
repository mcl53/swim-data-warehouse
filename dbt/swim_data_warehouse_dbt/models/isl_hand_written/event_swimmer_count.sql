{# event_swimmer_count #}

SELECT
    CAST(id             AS INT    ) AS id,
    CAST(is_skins_event AS VARCHAR) AS is_skins_event,
    CAST(round          AS VARCHAR) AS round,
    CAST(swimmer_count  AS INT    ) AS swimmer_count
FROM
(
    VALUES
--  (id, is_skins_event, round    , swimmer_count)
    (1 , FALSE         , 'Final'  , 8            ),
    (2 , TRUE          , 'Round 1', 8            ),
    (3 , TRUE          , 'Round 2', 4            ),
    (4 , TRUE          , 'Final'  , 2            )
)
event_swimmer_count
    (id, is_skins_event, round, swimmer_count    )
