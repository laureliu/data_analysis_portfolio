/*
Analyzing channel portfolios.
Weekly trended session volume for gsearch nonbrand and bsearch (second paid
search channel) for comparison.
*/

SELECT 
     MIN(DATE(created_at)) AS week_start_date
    , COUNT(DISTINCT website_session_id) AS total_sessions
    , COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions
    , COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM website_sessions
WHERE created_at > '2012-08-22' 
	AND created_at < '2012-11-29'
	AND utm_source in ('gsearch', 'bsearch')
    AND utm_campaign = 'nonbrand'
GROUP BY 
	YEARWEEK(created_at)
ORDER BY 
	1 
;


/*
Comparing channel characteristics. 
Percentage of traffic for different device types for bsearch nonbrand campaign.
Channels are different from a device standpoint.
*/

SELECT 
      utm_source
    , COUNT(DISTINCT website_session_id) AS  sessions
    , COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions
    , COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_mobile
FROM website_sessions
WHERE created_at > '2012-08-22'
	AND created_at < '2012-11-30'
	AND utm_campaign = 'nonbrand'
GROUP BY 
	1
;

/*
Cross-channel bid optimization.
Nonbrand conversion rates from session to order for gsearch and bsearch.
*/

SELECT
      ws.device_type
    , ws.utm_source
    , COUNT(DISTINCT ws.website_session_id) AS sessions
    , COUNT(DISTINCT o.order_id) AS orders
    , COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rate
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE ws.created_at BETWEEN '2012-08-22' AND '2012-09-18'
	AND ws.utm_campaign = 'nonbrand'
GROUP BY 
	1,2
;


/*
Impact of bid changes.Analyzing channel portfolio trends.
Weekly session volume for gsearch and bsearch nonbrand, broken down by device type.
*/

SELECT 
      MIN(DATE(created_at)) as weeks_start_date
    , COUNT(DISTINCT CASE WHEN device_type = 'desktop' AND utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS g_dtop_sessions
    , COUNT(DISTINCT CASE WHEN device_type = 'desktop' AND utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS b_dtop_sessions
    , COUNT(DISTINCT CASE WHEN device_type = 'desktop' AND utm_source = 'bsearch' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN device_type = 'desktop' AND utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS b_pct_of_g_dtop
    , COUNT(DISTINCT CASE WHEN device_type = 'mobile' AND utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS g_mob_sessions
    , COUNT(DISTINCT CASE WHEN device_type = 'mobile' AND utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS b_mob_sessions
    , COUNT(DISTINCT CASE WHEN device_type = 'mobile' AND utm_source = 'bsearch' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN device_type = 'mobile' AND utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS b_pct_of_g_mob
FROM website_sessions 
WHERE created_at BETWEEN '2012-11-04' AND '2012-12-22'
	AND utm_campaign = 'nonbrand'
GROUP BY 
	YEARWEEK(created_at)
;

/*
Analyzing direct traffic. Site traffic breakdown. 
We're building momentum with our brand as the brand, direct, and organic
volumes are growing as a percentage of our paid traffic volume.
*/

SELECT 
      YEAR(created_at) AS yr
    , MONTH(created_at) AS mo
    , COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand
    , COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END) AS brand
    , COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS brand_pct_of_nonbrand
    , COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END) AS direct
    , COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END)  AS direct_pct_of_nonbrand
    , COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END) AS organic
    , COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand
FROM (

SELECT 
      website_session_id
    , created_at
    , CASE
            WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'organic_search'
            WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
            WHEN utm_campaign = 'brand' THEN 'paid_brand'
            WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
		  END AS channel_group
FROM website_sessions
WHERE created_at < '2012-12-23'
) AS sessions_w_channel_group
GROUP BY 
	1,2
;
