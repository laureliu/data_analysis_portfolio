-- Identifying repeat visitors
-- A fair number of customers do come back to the site after first sessions

CREATE TEMPORARY TABLE sessions_w_repeats
SELECT
      ns.user_id
    , ns.website_session_id AS new_session_id
    , ws.website_session_id AS repeat_session_id
FROM
(
SELECT
      user_id
    , website_session_id
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-01'
	AND is_repeat_session = 0
) AS ns
	LEFT JOIN website_sessions ws 
        ON ns.user_id = ws.user_id
        AND ns.website_session_id < ws.website_session_id
        AND ws.created_at BETWEEN '2014-01-01' AND '2014-11-01'
;

SELECT 
      repeat_sessions
    , COUNT(DISTINCT user_id) AS users
FROM 
(
SELECT 
      user_id
    , COUNT(DISTINCT new_session_id) AS new_sessions
    , COUNT(DISTINCT repeat_session_id) AS repeat_sessions
FROM sessions_w_repeats
GROUP BY 1
ORDER BY 3 DESC
) As user_level
GROUP BY 1
;

-- Deeper dive on repeat sessions
-- Analyzing time to repeat

DROP TABLE IF EXISTS sessions_w_repeats_for_time_diff;
CREATE TEMPORARY TABLE sessions_w_repeats_for_time_diff
SELECT
      new_sessions.user_id
    , new_sessions.website_session_id AS new_session_id
    , new_sessions.created_at AS new_session_created_at
    , ws.website_session_id AS repeat_session_id
    , ws.created_at AS repeat_session_created_at
FROM
(
SELECT
      user_id
    , website_session_id
    , created_at
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-03'
	AND is_repeat_session = 0
) AS new_sessions
	LEFT JOIN website_sessions ws 
        ON ws.user_id = new_sessions.user_id
        AND ws.website_session_id > new_sessions.website_session_id
        AND ws.created_at BETWEEN '2014-01-01' AND '2014-11-03'
;

CREATE TEMPORARY TABLE users_first_to_second
SELECT 
      user_id
    , DATEDIFF(second_session_created_at, new_session_created_at) AS days_first_to_second_session
FROM
(
SELECT
      user_id
    , new_session_id
    , new_session_created_at
    , MIN(repeat_session_id) AS second_session_id
    , MIN(repeat_session_created_at) AS second_session_created_at
FROM sessions_w_repeats_for_time_diff
WHERE repeat_session_id IS NOT NULL
GROUP BY 1,2,3
) AS first_second
;

SELECT
      AVG(days_first_to_second_session) AS avg_days_first_to_second
    , MIN(days_first_to_second_session) AS min_days_first_to_second
    , MAX(days_first_to_second_session) AS max_days_first_to_second
FROM users_first_to_second
;

-- Repeat channel mix
-- What channels custoemrs come back through? Direct type-in or we're paying
-- for customers with paid search ads multiple times?
-- Most customers come back through organic search or direct type-in


SELECT
      CASE 
    		WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN 'organic_search'
    		WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
    		WHEN utm_campaign = 'brand' THEN 'paid_brand'
    		WHEN utm_source = 'socialbook' THEN 'paid_social'
    		WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
    	END AS channel_group
    , COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions
    , COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-05'
GROUP BY 1
ORDER BY 3 DESC
;

-- Analyzing new & repeat conversion rate
-- Repeat sessions are more likely to convert and produce more revenue per session

SELECT
      ws.is_repeat_session
    , COUNT(DISTINCT ws.website_session_id) AS sessions
    , COUNT(DISTINCT o.order_id) AS orders
    , COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rate
    , SUM(o.price_usd)/COUNT(DISTINCT ws.website_session_id) AS rev_per_session
FROM website_sessions ws 
LEFT JOIN orders o 
	ON ws.website_session_id = o.website_session_id
WHERE ws.created_at BETWEEN '2014-01-01' AND '2014-11-08'
GROUP BY 1
;
