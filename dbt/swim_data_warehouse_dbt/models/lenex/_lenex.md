{% docs athlete_id %}
The ID number for the athlete. The same ID is not used for the same athlete across different meets.
{% enddocs %}

{% docs club_code %}
The code for the club. Unique across different meets.
{% enddocs %}

{% docs club_name %}
The name of the team or club.
{% enddocs %}

{% docs event_heat_number %}
The heat number within the event.
{% enddocs %}

{% docs event_id %}
The ID number of the event. This is unique per round of an event.
{% enddocs %}

{% docs event_place %}
The overall finishing position of the athlete or team in the event.
This is -1 where the athlete is not classified.
{% enddocs %}

{% docs finish_time %}
The finishing time for the athlete in the event.
{% enddocs %}

{% docs heat_id %}
The ID number of the heat.
{% enddocs %}

{% docs lane_number %}
The lane number of the athlete for the heat.
{% enddocs %}

{% docs meet_city %}
The city the meet was held in.
{% enddocs %}

{% docs meet_name %}
The name of the meet.
{% enddocs %}

{% docs meet_year %}
The year the meet was held in.
{% enddocs %}

{% docs reaction_time %}
The reaction time of the athlete.
{% enddocs %}

{% docs session_number %}
The session number for the meet.
{% enddocs %}

{% docs sex %}
The sex of the athlete or team.
{% enddocs %}

{% docs splits %}
JSON data on the splits for the athlete or team in the event.
{% enddocs %}

{% docs split_cumulative_time %}
The time at the split_distance since the start of the race.
{% enddocs %}

{% docs split_distance %}
The distance into the race that the split was taken.
{% enddocs %}

{% docs status %}
The status of the athlete's swim in the event.
Examples include:
- DNS -> Did Not Start
- DSQ -> Disqualified
{% enddocs %}
