-- What are the most-viewed website pages?
-- Insight: homepage and products page get the bulk of our traffic (next place to look at to see if there's room for improvement).
SELECT
	pageview_url
	, COUNT(DISTINCT website_pageview_id) AS pvs
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY 1
ORDER BY 2 DESC
;

-- What are the top entry pages?
-- Website manager will focus ON making improvements ON the top entry pages next.
CREATE TEMPORARY TABLE first_pv_per_session
SELECT
	website_session_id
	, MIN(website_pageview_id) AS first_pv
FROM website_pageviews 
WHERE created_at < '2012-06-12'
GROUP BY 1
;

SELECT
	website_pageviews.pageview_url AS landing_page_url
	, COUNT(first_pv_per_session.website_session_id) AS sessions_hitting_page
FROM first_pv_per_session
LEFT JOIN website_pageviews 
	ON first_pv_per_session.first_pv = website_pageviews.website_pageview_id
GROUP BY 1
ORDER BY 2 DESC
;


-- What is the home page bounce rate?
-- Insight: 60% bounce rate. too high for paid search (which should be a high quality traffic)
-- STEP 1: find the first website_pageview_id for relevant sessions
-- STEP 2: identify the landing page for each session
-- STEP 3: COUNTing pageviews for each session, to identify "bounces"
-- STEP 4: summarizing total sessions and bounces sessions, by landing page

DROP TABLE IF EXISTS first_pageviews;
CREATE TEMPORARY TABLE first_pageviews
SELECT
	website_session_id
	, MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews 
WHERE created_at < '2012-06-14'
GROUP BY 1
;

DROP TABLE IF EXISTS sessions_w_home_landing_page;
CREATE TEMPORARY TABLE sessions_w_home_landing_page
SELECT
	first_pageviews.website_session_id
	, website_pageviews.pageview_url AS landing_page
FROM first_pageviews
LEFT JOIN website_pageviews
	ON first_pageviews.min_pageview_id = website_pageviews.website_pageview_id
WHERE website_pageviews.pageview_url = '/home'
;


DROP TABLE IF EXISTS bounced_sessions;
CREATE TEMPORARY TABLE bounced_sessions
SELECT
	sessions_w_home_landing_page.website_session_id
	, sessions_w_home_landing_page.landing_page
    	, COUNT(website_pageviews.website_pageview_id) AS count_of_paged_viewed
FROM sessions_w_home_landing_page
LEFT JOIN website_pageviews 
	ON website_pageviews.website_session_id = sessions_w_home_landing_page.website_session_id
GROUP BY 1,2
having COUNT(website_pageviews.website_pageview_id) = 1
;


SELECT 
	COUNT(DISTINCT sessions_w_home_landing_page.website_session_id) AS total_sessions
	, COUNT(DISTINCT bounced_sessions.website_session_id) AS bounced_sessions
        , COUNT(DISTINCT bounced_sessions.website_session_id)/COUNT(DISTINCT sessions_w_home_landing_page.website_session_id) AS bounce_rate
FROM sessions_w_home_landing_page
LEFT JOIN bounced_sessions
	ON sessions_w_home_landing_page.website_session_id = bounced_sessions.website_session_id
;


-- Test bounce rate for new landing page and homepage for gsearch nonbrand traffic
-- Insight: fewer customer bounce for the new landing page. will have the campaigns directed to the new lander.

-- Find the first instance of /lander-1 to set analysis time frame
DROP TABLE IF EXISTS lander1_start;
CREATE TEMPORARY TABLE lander1_start
SELECT
	MIN(created_at) AS first_created_at
	, MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE pageview_url = '/lander-1'
	AND created_at is not null
;

DROP TABLE IF EXISTS first_test_pageviews;
CREATE TEMPORARY TABLE first_test_pageviews
SELECT 
	website_pageviews.website_session_id
	, MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
INNER JOIN website_sessions
ON website_sessions.website_session_id = website_pageviews.website_session_id
    AND website_sessions.created_at < '2012-07-28'
    AND website_sessions.created_at > (SELECTfirst_created_at FROM lander1_start)
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 1
;

DROP TABLE IF EXISTS sessions_w_lander1;
CREATE TEMPORARY TABLE sessions_w_lander1
SELECT 
	first_test_pageviews.website_session_id
	, website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
LEFT JOIN website_pageviews
	ON first_test_pageviews.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.pageview_url = '/lander-1'
OR website_pageviews.pageview_url = '/home'
;

DROP TABLE IF EXISTS bounced_sessions;
CREATE TEMPORARY TABLE bounced_sessions
SELECT 
	sessions_w_lander1.website_session_id 
	, sessions_w_lander1.landing_page
        , COUNT(DISTINCT website_pageviews.website_pageview_id) AS count_of_paged_viewed
FROM sessions_w_lander1
LEFT JOIN website_pageviews
	ON sessions_w_lander1.website_session_id = website_pageviews.website_session_id
GROUP BY 1,2
having COUNT(DISTINCT website_pageviews.website_pageview_id) = 1
;

SELECT
	sessions_w_lander1.landing_page AS landing_page
	, COUNT(sessions_w_lander1.website_session_id) AS total_sessions
	, COUNT(bounced_sessions.website_session_id) AS bounced_sessions
	, COUNT(bounced_sessions.website_session_id)/COUNT(sessions_w_lander1.website_session_id) AS bounce_rate
FROM sessions_w_lander1
LEFT JOIN bounced_sessions
	ON sessions_w_lander1.website_session_id = bounced_sessions.website_session_id
GROUP BY 1
;


-- Landing page trend analysis
-- Insight: all the traffic hAS been rerouted to lander

CREATE TEMPORARY TABLE sessions_w_min_pv_id_and_view_count
SELECT
	website_sessions.website_session_id
	, MIN(website_pageviews.website_pageview_id) AS first_pageview_id
	, COUNT(website_pageviews.website_pageview_id) AS COUNT_pageviews

FROM website_sessions
LEFT JOIN website_pageviews
	ON website_sessions.website_session_id = website_pageviews.website_session_id

WHERE website_sessions.utm_source = 'gsearch'
AND website_sessions.utm_campaign = 'nonbrand'
AND website_sessions.created_at > '2012-06-01'
AND website_sessions.created_at < '2012-08-31'
GROUP BY 1;

CREATE TEMPORARY TABLE sessions_w_counts_lander_and_created_at
SELECT
	sessions_w_min_pv_id_and_view_count.website_session_id
	, sessions_w_min_pv_id_and_view_count.first_pageview_id
	, sessions_w_min_pv_id_and_view_count.COUNT_pageviews
	, website_pageviews.pageview_url AS landing_page
	, website_pageviews.created_at AS session_created_at

FROM sessions_w_min_pv_id_and_view_count
LEFT JOIN website_pageviews
	ON sessions_w_min_pv_id_and_view_count.first_pageview_id = website_pageviews.website_pageview_id
;


SELECT
	yearweek(session_created_at) AS year_week
     	, MIN(date(session_created_at)) AS week_start_date
--     	, COUNT(DISTINCT website_session_id) AS total_sessions
--     	, COUNT(DISTINCT CASE WHEN COUNT_pageviews = 1 then website_session_id ELSE NULL END) AS bounced_sessions
   	, COUNT(DISTINCT CASE WHEN COUNT_pageviews = 1 then website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS bounce_rate
	, COUNT(DISTINCT CASE WHEN landing_page = '/home' then website_session_id ELSE NULL END) AS home_sessions
    	, COUNT(DISTINCT CASE WHEN landing_page = '/lander-1' then website_session_id ELSE NULL END) AS lander_sessions

FROM sessions_w_counts_lander_and_created_at

GROUP BY 1;

-- Where we lose the gsearch visitors between the new/lander-1 page and placing an order?
-- Insight: focus on pages that have the lowest click rates
SELECT
	website_session_id
	, MAX(products_page) AS product_made_id
	, MAX(mrfuzzy_page) AS mrfuzzy_made_id
	, MAX(cart_page) AS cart_made_id
	, MAX(shipping_page) AS shipping_made_id
	, MAX(billing_page) AS billing_made_id
	, MAX(thankyou_page) AS thankyou_made_id
FROM(

SELECT
	website_sessions.website_session_id
	, website_pageviews.pageview_url
	, CASE WHEN pageview_url = '/products' then 1 else 0 end AS products_page
	, CASE WHEN pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end AS mrfuzzy_page
	, CASE WHEN pageview_url = '/cart' then 1 else 0 end AS cart_page
	, CASE WHEN pageview_url = '/shipping' then 1 else 0 end AS shipping_page
	, CASE WHEN pageview_url = '/billing' then 1 else 0 end AS billing_page
	, CASE WHEN pageview_url = '/thank-you-for-your-order' then 1 else 0 end AS thankyou_page
FROM website_sessions
LEFT JOIN website_pageviews
	ON website_sessions.website_session_id = website_pageviews.website_session_id

WHERE website_sessions.utm_source = 'gsearch'
	AND website_sessions.utm_campaign = 'nonbrand'
	AND website_sessions.created_at > '2012-08-05'
	AND website_sessions.created_at < '2012-09-05'
ORDER BY 
	website_sessions.website_session_id
	, website_pageviews.created_at
) AS pageview_level
	
GROUP BY website_session_id
;

DROP TABLE IF EXISTS session_level_made_it_flags;
CREATE TEMPORARY TABLE session_level_made_it_flags
SELECT
	website_session_id
	, MAX(products_page) AS product_made_it
	, MAX(mrfuzzy_page) AS mrfuzzy_made_it
	, MAX(cart_page) AS cart_made_it
	, MAX(shipping_page) AS shipping_made_it
	, MAX(billing_page) AS billing_made_it
	, MAX(thankyou_page) AS thankyou_made_it
FROM(

SELECT
	website_sessions.website_session_id
	, website_pageviews.pageview_url
	, CASE WHEN pageview_url = '/products' then 1 else 0 end AS products_page
	, CASE WHEN pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end AS mrfuzzy_page
	, CASE WHEN pageview_url = '/cart' then 1 else 0 end AS cart_page
	, CASE WHEN pageview_url = '/shipping' then 1 else 0 end AS shipping_page
	, CASE WHEN pageview_url = '/billing' then 1 else 0 end AS billing_page
	, CASE WHEN pageview_url = '/thank-you-for-your-order' then 1 else 0 end AS thankyou_page
FROM website_sessions
LEFT JOIN website_pageviews
	ON website_sessions.website_session_id = website_pageviews.website_session_id

WHERE website_sessions.utm_source = 'gsearch'
	AND website_sessions.utm_campaign = 'nonbrand'
	AND website_sessions.created_at > '2012-08-05'
	AND website_sessions.created_at < '2012-09-05'
ORDER BY 
	website_sessions.website_session_id
	, website_pageviews.created_at
) AS pageview_level
GROUP BY website_session_id
;


SELECT
	COUNT(DISTINCT website_session_id) AS sessions
	, COUNT(DISTINCT CASE WHEN product_made_it = 1 then website_session_id ELSE NULL END) AS to_products		
	, COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 then website_session_id ELSE NULL END) AS to_mrfuzzy
	, COUNT(DISTINCT CASE WHEN cart_made_it = 1 then website_session_id ELSE NULL END) AS to_cart
	, COUNT(DISTINCT CASE WHEN shipping_made_it = 1 then website_session_id ELSE NULL END) AS to_shipping
	, COUNT(DISTINCT CASE WHEN billing_made_it = 1 then website_session_id ELSE NULL END) AS to_billing
	, COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 then website_session_id ELSE NULL END) AS to_thankyou
FROM session_level_made_it_flags;

SELECT
	COUNT(DISTINCT CASE WHEN product_made_it = 1 then website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS lander_click_rt
	, COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 then website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product_made_it = 1 then website_session_id ELSE NULL END) AS products_click_rt
	, COUNT(DISTINCT CASE WHEN cart_made_it = 1 then website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 then website_session_id ELSE NULL END) AS mrfuzzy_click_rt
	, COUNT(DISTINCT CASE WHEN shipping_made_it = 1 then website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_made_it = 1 then website_session_id ELSE NULL END) AS cart_click_rt
	, COUNT(DISTINCT CASE WHEN billing_made_it = 1 then website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 then website_session_id ELSE NULL END) AS shipping_click_rt
	, COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 then website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it = 1 then website_session_id ELSE NULL END) AS billing_click_rt
FROM session_level_made_it_flags;

-- What % sessions on the testing pages end up placing an order?
-- Insight: new billing version page is converting more customers

SELECT 
	MIN(website_pageviews.website_pageview_id) AS first_pv_id
FROM website_pageviews
WHERE pageview_url = '/billing-2'
;

SELECT 
	billing_version_see
	, COUNT(DISTINCT website_session_id) AS sessions
        , COUNT(DISTINCT order_id) AS orders
        , COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS billing_to_order_rt
FROM(

SELECT
	website_pageviews.website_session_id
	, website_pageviews.pageview_url AS billing_version_see
	, orders.order_id
FROM website_pageviews
LEFT JOIN orders
	ON orders.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.website_pageview_id >= 53550
	AND website_pageviews.created_at <'2012-11-10'
	AND website_pageviews.pageview_url in ('/billing', '/billing-2')
) AS billing_sessions_w_orders
GROUP BY 1
; 
