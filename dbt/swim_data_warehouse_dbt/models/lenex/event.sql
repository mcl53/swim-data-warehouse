{# event #}

-- Sources

WITH session AS (
    SELECT * FROM {{ ref('session') }}
)

-- Model

, event_json AS (
    SELECT
        meet_name                                    AS meet_name,
        session_number                               AS session_number,
        UNNEST(CAST(session_events.EVENT AS JSON[])) AS event
    FROM
        session
)

SELECT
    meet_name                                    AS meet_name,
    session_number                               AS session_number,
    CAST(event->>'@eventid'              AS INT) AS event_id,
    CAST(event->>'@number'               AS INT) AS event_number,
    CAST(event->>'@preveventid'          AS INT) AS previous_event_id,
    event->>'@gender'                            AS sex,
    event->>'@round'                             AS event_round,
    event->>'@daytime'                           AS event_start_time,
    CAST(event.SWIMSTYLE->>'@distance'   AS INT) AS distance,
    CAST(event.SWIMSTYLE->>'@relaycount' AS INT) AS event_team_size,
    event.SWIMSTYLE->>'@stroke'                  AS stroke,
    event.HEATS                                  AS heats
FROM
    event_json
