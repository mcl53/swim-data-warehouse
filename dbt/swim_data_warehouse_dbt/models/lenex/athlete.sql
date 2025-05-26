{# athlete #}

-- Sources

WITH club AS (
    SELECT * FROM {{ ref('club') }}
)

-- Model

, athlete_json AS (
    SELECT
        meet_name                                AS meet_name,
        meet_city                                AS meet_city,
        meet_year                                AS meet_year,
        club_code                                AS club_code,
        UNNEST(CAST(athletes.ATHLETE AS JSON[])) AS athlete
    FROM
        club
    WHERE
        json_type(athletes.ATHLETE) = 'ARRAY'

    UNION ALL

    SELECT
        meet_name        AS meet_name,
        meet_city        AS meet_city,
        meet_year        AS meet_year,
        club_code        AS club_code,
        athletes.ATHLETE AS athlete
    FROM
        club
    WHERE
        json_type(athletes.ATHLETE) = 'OBJECT'
)

SELECT
    meet_name                            AS meet_name,
    meet_city                            AS meet_city,
    meet_year                            AS meet_year,
    club_code                            AS club_code,
    CAST(athlete->>'@athleteid' AS INT ) AS athlete_id,
    athlete->>'@firstname'               AS first_name,
    athlete->>'@lastname'                AS last_name,
    CAST(athlete->>'@birthdate' AS DATE) AS date_of_birth,
    athlete->>'@gender'                  AS sex,
    athlete.ENTRIES                      AS entries,
    athlete.RESULTS                      AS results
FROM
    athlete_json
