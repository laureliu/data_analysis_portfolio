/*
1. Gsearch seems to be the biggest driver of the business. Pull monthly trend
for gsearch sessions and orders so that the company can showcase the growth.
*/

SELECT
	YEAR(ws.created_at) AS yr
    , MONTH(ws.created_at) AS mo
    , COUNT(DISTINCT ws.website_session_id) AS sessions
    , COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions ws
LEFT JOIN orders o 
ON o.website_session_id = ws.website_session_id
WHERE ws.created_at < '2012-11-27'
	AND ws.utm_source = 'gsearch'
GROUP BY 1,2
;

/*
2. Monthly trend for gsearch, but this time splitting out nonbrand and brand 
campaigns seperately to see if a brand is picking up at all.
*/

SELECT
	YEAR(ws.created_at) AS yr
    , MONTH(ws.created_at) AS mo
    , COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbrand_sessions
    , COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) AS nonbrand_orders
    , COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_sessions
    , COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN o.order_id ELSE NULL END) AS brand_orders
FROM website_sessions ws 
LEFT JOIN orders o 
	ON ws.website_session_id = ws.website_session_id
WHERE ws.created_at < '2012-11-27'
	AND ws.utm_source = 'gsearch'
GROUP BY 1,2
;

/*
3. While on gsearch, dive into nonbrand, and pull monthly sessions and orders split 
by device type. 
*/

SELECT 
	YEAR(ws.created_at) AS yr
    , MONTH(ws.created_at) AS mo
    , COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN ws.website_session_id ELSE NULL END) AS desktop_sessions
    , COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN o.order_id ELSE NULL END) AS desktop_orders
    , COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN ws.website_session_id ELSE NULL END) AS mobile_sessions
    , COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN o.order_id ELSE NULL END) AS mobile_orders
FROM website_sessions ws 
LEFT JOIN orders o 
	ON o.website_session_id = ws.website_session_id
WHERE ws.created_at < '2012-11-27'
	AND ws.utm_source = 'gsearch'
    AND ws.utm_campaign = 'nonbrand'
GROUP BY 1,2
;

/*
4. Pull monthly trends for gsearch, alongside monthly trends for each of the other channels/
*/

-- Finding the various utm sources and referers to see the traffic we're getting

SELECT DISTINCT 
	utm_source
    , utm_campaign
    , http_referer
FROM website_sessions ws 
WHERE ws.created_at < '2012-11-27'
;


SELECT 
	YEAR(ws.created_at) AS yr
    , MONTH(ws.created_at) AS mo
    , COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN ws.website_session_id ELSE NULL END) AS gsearch_paid_sessions
    , COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN ws.website_session_id ELSE NULL END) AS bsearch_paid_sessions
    , COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN ws.website_session_id ELSE NULL END) AS organic_search_sessions
    , COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN ws.website_session_id ELSE NULL END) AS direct_type_in_sessions
FROM website_sessions ws 
LEFT JOIN orders o 
	ON o.website_session_id = ws.website_session_id
WHERE ws.created_at < '2012-11-27'
GROUP BY 1,2
;


/*
5. Tell the story of the website performance improvements over the first 8 months
*/

SELECT 
	YEAR(ws.created_at) AS yr
    , MONTH(ws.created_at) AS mo
    , COUNT(DISTINCT ws.website_session_id) AS sessions
    , COUNT(DISTINCT o.order_id) AS orders
    , COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS conversion_rate
FROM website_sessions ws 
LEFT JOIN orders o 
	ON o.website_session_id = ws.website_session_id
WHERE ws.created_at < '2012-11-27'
GROUP BY 1,2
;

/*
6. For gsearch lander test, estimate the revenue that test earned us.
*/

SELECT 
	MIN(website_pageview_id) AS first_test_pb
FROM website_pageviews 
WHERE pageview_url = '/lander-1'
;

CREATE TEMPORARY TABLE first_test_pageviews
SELECT 
	wp.website_session_id
    , MIN(wp.website_pageview_id) AS min_pageview_id
FROM website_pageviews wp 
INNER JOIN website_sessions ws 
	ON ws.website_session_id = wp.website_session_id
	AND ws.created_at < '2012-07-28'
    AND wp.website_pageview_id >= 23504
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 1
;

CREATE TEMPORARY TABLE nonbrand_test_session_w_landing_pages
SELECT
	ftp.website_session_id
    , wp.pageview_url AS landing_page
FROM first_test_pageviews ftp 
LEFT JOIN website_pageviews wp 
	ON wp.website_pageview_id = ftp.min_pageview_id
WHERE wp.pageview_url IN ('/home', '/lander-1')
;

CREATE TEMPORARY TABLE nonbrand_test_session_w_orders
SELECT 
	nts.website_session_id
    , nts.landing_page
    , o.order_id 
FROM nonbrand_test_session_w_landing_pages nts
LEFT JOIN orders o
	ON o.website_session_id = nts.website_session_id
;

SELECT 
	landing_page
    , COUNT(DISTINCT website_session_id) AS sessions
    , COUNT(DISTINCT order_id) AS orders
    , COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS conv_rate
FROM nonbrand_test_session_w_orders
GROUP BY 1
;

-- Find the most recent pageview for gsearch nonbrand where the traffic was sent to home
SELECT 
	MAX(ws.website_session_id) AS most_recent_gsearch_nonbrand_home_pageview
FROM website_sessions ws 
LEFT JOIN website_pageviews wp 
	ON ws.website_session_id = wp.website_session_id
WHERE utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
    AND pageview_url = '/home'
    AND ws.created_at < '2012-11-27'
;

SELECT 
	COUNT(website_session_id) AS sessions_since_test
FROM website_sessions
WHERE created_at < '2012-11-27'
	AND website_session_id > 17145
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
;

-- 202 incremental orders since 7/29

/*
7. For the landing page test, show a full conversion funnel from each
of the two pages to orders. Use the same time period.
*/

CREATE TEMPORARY TABLE session_level_made_it_flagged
SELECT 
	website_session_id
    , MAX(homepage) AS saw_homepage
    , MAX(custom_lander) AS saw_custom_lander
    , MAX(product_page) AS product_made_it
    , MAX(mrfuzzy_page) AS mrfuzzy_made_it
    , MAX(cart_page) AS cart_made_it
    , MAX(shipping_page) AS shipping_made_it
    , MAX(billing_page) AS billing_made_it
    , MAX(thankyou_page) AS thankyou_made_it

FROM (
SELECT
	ws.website_session_id
    , wp.pageview_url
    , CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage
    , CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander
    , CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS product_page
    , CASE WHEN pageview_url = '/the-priginal-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page
    , CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
    , CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page
    , CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page
    , CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions ws 
LEFT JOIN website_pageviews wp 
	ON ws.website_session_id = wp.website_session_id
WHERE ws.utm_source = 'gsearch'
	AND ws.utm_campaign = 'nonbrand'
    AND ws.created_at < '2012-07-28'
    AND ws.created_at > '2012-06-19'
) AS pageview_level
GROUP BY 1
;
