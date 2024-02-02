-- Analyze Top Traffic Sources
-- Insight: Identify top traffic sources by session count and conversion rate
SELECT 
    ws.utm_content,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / NULLIF(COUNT(DISTINCT ws.website_session_id), 0) AS session_to_order_conv_rt
FROM 
    website_sessions ws
LEFT JOIN 
    orders o ON o.website_session_id = ws.website_session_id
WHERE 
    ws.website_session_id BETWEEN 1000 AND 2000
GROUP BY 
    ws.utm_content
ORDER BY 
    sessions DESC;


-- Find Top Traffic Sources
-- Insight: gsearch and nonbrand drive significant website traffic
SELECT 
    utm_source,
    utm_campaign,
    http_referer,
    COUNT(DISTINCT website_session_id) AS number_of_sessions
FROM 
    website_sessions
WHERE 
    created_at < '2012-04-12'
GROUP BY 
    utm_source, utm_campaign, http_referer
ORDER BY 
    number_of_sessions DESC;


-- Top Traffic Source Conversion Rate
-- Insight: Session to order conversion rate for gsearch nonbrand is below the threshold, suggesting a need to adjust search bids
SELECT 
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / NULLIF(COUNT(DISTINCT ws.website_session_id), 0) AS sessions_to_order_cvr
FROM 
    website_sessions ws
LEFT JOIN 
    orders o ON ws.website_session_id = o.website_session_id
WHERE 
    utm_source = 'gsearch' AND
    utm_campaign = 'nonbrand' AND
    ws.created_at < '2012-04-14';



-- Traffic Source Trending
-- Insight: Session volumes decrease after reducing bids on gsearch nonbrand, indicating sensitivity to bid changes
SELECT 
    MIN(DATE(created_at)) AS week_started_at,
    COUNT(DISTINCT website_session_id) AS sessions
FROM 
    website_sessions
WHERE 
    utm_source = 'gsearch' AND
    utm_campaign = 'nonbrand' AND
    created_at < '2012-05-12'
GROUP BY 
    YEAR(created_at), WEEK(created_at);


-- Bid Optimization for Paid Traffic
-- Insight: Desktop conversion rate is 3% higher than mobile, suggesting different bid strategies for each device type
SELECT
    device_type,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / NULLIF(COUNT(DISTINCT ws.website_session_id), 0) AS session_to_order_ctr
FROM 
    website_sessions ws
LEFT JOIN 
    orders o ON ws.website_session_id = o.website_session_id
WHERE 
    ws.created_at < '2012-05-11' AND
    ws.utm_source = 'gsearch' AND
    ws.utm_campaign = 'nonbrand'
GROUP BY 
    device_type
ORDER BY 
    session_to_order_ctr DESC;


-- Trending with Granular Segments
-- Insight: After increasing bids for desktop traffic, the website experienced more sessions, indicating a successful strategy adjustment
SELECT 
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions
FROM 
    website_sessions
WHERE 
    created_at BETWEEN '2012-04-15' AND '2012-06-09' AND
    utm_source = 'gsearch' AND
    utm_campaign = 'nonbrand'
GROUP BY 
    YEAR(created_at), WEEK(created_at);
