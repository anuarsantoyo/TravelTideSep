--- user table filter
WITH active_users AS (
    SELECT
        user_id,
        COUNT(session_id) AS session_count
    FROM sessions
    WHERE session_start >= '2023-01-05'
    GROUP BY user_id
    HAVING COUNT(session_id) > 7
)
SELECT *
FROM users
WHERE user_id IN (SELECT user_id FROM active_users);


--- session table
with active_users as (SELECT
    user_id,
    COUNT(session_id) AS session_count
FROM sessions
WHERE session_start >= '2023-01-05'
GROUP BY user_id
HAVING COUNT(session_id) > 7)

select
  *
from
  sessions
where
  sessions.user_id in (select user_id from active_users)


--- flights table
with active_users as (SELECT
    user_id,
    COUNT(session_id) AS session_count
FROM sessions
WHERE session_start >= '2023-01-05'
GROUP BY user_id
HAVING COUNT(session_id) > 7),

active_sessions as (
select
  *
from
  sessions
where
  sessions.user_id in (select user_id from active_users))

select
  *
from flights

where flights.trip_id in (select distinct trip_id from active_sessions)


--- hotels table
with active_users as (SELECT
    user_id,
    COUNT(session_id) AS session_count
FROM sessions
WHERE session_start >= '2023-01-05'
GROUP BY user_id
HAVING COUNT(session_id) > 7),

active_sessions as (
select
  *
from
  sessions
where
  sessions.user_id in (select user_id from active_users))

select
  *
from hotels

where hotels.trip_id in (select distinct trip_id from active_sessions)






















