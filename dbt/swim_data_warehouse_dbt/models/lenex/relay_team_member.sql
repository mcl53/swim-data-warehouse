{# relay_team_member #}

-- Sources

WITH relay_result AS (
    SELECT * FROM {{ ref('relay_result') }}
)

-- Model

, relay_position_json AS (
    SELECT
        meet_name                                             AS meet_name,
        club_code                                             AS club_code,
        event_id                                              AS event_id,
        UNNEST(CAST(relay_positions.RELAYPOSITION AS JSON[])) AS relay_position
    FROM
        relay_result
)

SELECT
    meet_name                                         AS meet_name,
    club_code                                         AS club_code,
    event_id                                          AS event_id,
    CAST(relay_position->>'@athleteid'        AS INT) AS athlete_id,
    CAST(relay_position->>'@number'           AS INT) AS athlete_position,
    relay_position->>'@status'                        AS athlete_status,
    INTERVAL (
        -- Multiply by 10 as reaction times are recorded in 1/100ths of seconds.
        CAST(relay_position->>'@reactiontime' AS INT) * 10
    ) MILLISECONDS                                    AS reaction_time
FROM
    relay_position_json
