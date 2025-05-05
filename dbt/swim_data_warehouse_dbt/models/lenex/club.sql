{# club #}

-- Sources

WITH meet AS (
    SELECT * FROM {{ ref('meet') }}
)

-- Model

, club_json AS (
    SELECT
        meet_name                          AS meet_name,
        UNNEST(CAST(clubs.CLUB AS JSON[])) AS club
    FROM
        meet
)

SELECT
    meet_name           AS meet_name,
    club->>'@name'      AS club_name,
    club->>'@shortname' AS club_short_name,
    club->>'@code'      AS club_code,
    club->>'@nation'    AS club_nation,
    club->>'@type'      AS club_type,
    club.ATHLETES       AS athletes,
    club.RELAYS         AS relays
FROM
    club_json
