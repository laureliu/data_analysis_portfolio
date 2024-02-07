/*
Analyzing seasonality. Use last year's pattern to prepare for the upcoming year.
Steady growth all year and significant volume around the holiday months.
*/

SELECT 
      YEAR(ws.created_at) AS year
    , WEEK(ws.created_at) AS week
    , MIN(DATE(ws.created_at)) AS week_start
    , COUNT(DISTINCT ws.website_session_id) AS sessions
    , COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions ws
	LEFT JOIN orders o ON o.website_session_id = ws.website_session_id
WHERE YEAR(ws.created_at) = 2012
GROUP BY 1,2
;


/*
Data for customer service - analyzing business patterns.
8AM to 5PM we need to double up the staff members.
*/

SELECT
      hr
    , ROUND(AVG(CASE WHEN wkday = 0 THEN website_sessions ELSE NULL END),1) AS 'Monday' 
    , ROUND(AVG(CASE WHEN wkday = 1 THEN website_sessions ELSE NULL END),1) AS 'Tuesday' 
    , ROUND(AVG(CASE WHEN wkday = 2 THEN website_sessions ELSE NULL END),1) AS 'Wednesday'     
    , ROUND(AVG(CASE WHEN wkday = 3 THEN website_sessions ELSE NULL END),1) AS 'Thursday' 
    , ROUND(AVG(CASE WHEN wkday = 4 THEN website_sessions ELSE NULL END),1) AS 'Friday' 
	  , ROUND(AVG(CASE WHEN wkday = 5 THEN website_sessions ELSE NULL END),1) AS 'Saterday' 
  	, ROUND(AVG(CASE WHEN wkday = 6 THEN website_sessions ELSE NULL END),1) AS 'Sunday' 
FROM(
SELECT 
      DATE(created_at) AS created_date
    , WEEKDAY(created_at) AS wkday
    , HOUR(created_at) AS hr
    , COUNT(DISTINCT website_session_id) AS website_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
GROUP BY 1,2,3
) AS daily_hourly_sessions
GROUP BY 1
;
