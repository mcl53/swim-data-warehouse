{# relay_result #}

-- Sources

WITH club AS (
    SELECT * FROM {{ ref('club') }}
)

-- Model

, relay_json AS (
    SELECT
        meet_name                            AS meet_name,
        club_code                            AS club_code,
        UNNEST(CAST(relays.RELAY AS JSON[])) AS relay
    FROM
        club
    WHERE
        json_type(relays.RELAY) = 'ARRAY'

    UNION ALL

    SELECT
        meet_name    AS meet_name,
        club_code    AS club_code,
        relays.RELAY AS relay
    FROM
        club
    WHERE
        json_type(relays.RELAY) = 'OBJECT'
)

, relay_result_json AS (
    SELECT
        meet_name                                    AS meet_name,
        club_code                                    AS club_code,
        relay                                        AS relay,
        UNNEST(CAST(relay.RESULTS.RESULT AS JSON[])) AS result
    FROM
        relay_json
    WHERE
        json_type(relay.RESULTS.RESULT) = 'ARRAY'

    UNION ALL

    SELECT
        meet_name            AS meet_name,
        club_code            AS club_code,
        relay                AS relay,
        relay.RESULTS.RESULT AS result
    FROM
        relay_json
    WHERE
        json_type(relay.RESULTS.RESULT) = 'OBJECT'
)

SELECT
    meet_name                           AS meet_name,
    club_code                           AS club_code,
    CAST(result->>'@eventid'    AS INT) AS event_id,
    relay->>'@name'                     AS club_name,
    CAST(relay->>'@number'      AS INT) AS team_number,
    CAST(result->>'@place'      AS INT) AS event_place,
    CAST(
        -- NT denotes No Time.
        CASE result->>'@swimtime'
            WHEN 'NT' THEN NULL
            ELSE           result->>'@swimtime'
        END
        AS INTERVAL
    )                                   AS finish_time,
    INTERVAL (
        -- Multiply by 10 as reaction times are recorded in 1/100ths of seconds.
        CAST(result->>'@reactiontime' AS INT) * 10
    ) MILLISECONDS                      AS reaction_time,
    result->>'@stats'                   AS status,
    CAST(result->>'@heat'       AS INT) AS event_heat_number,
    CAST(result->>'@lane'       AS INT) AS lane_number,
    relay->>'@gender'                   AS sex,
    CAST(relay->>'@agetotalmax' AS INT) AS maximum_age_total,
    CAST(relay->>'@agemin'      AS INT) AS minimum_age,
    CAST(relay->>'@agemax'      AS INT) AS maximum_age,
    result->'RELAYPOSITIONS'            AS relay_positions,
    result->'SPLITS'                    AS splits
FROM
    relay_result_json
