/*
Product level sales analysis.
Show the baseline data so we can see how revenue and margin evolves as we roll out the new product.
*/

SELECT 
      YEAR(created_at) AS year
    , MONTH(created_at) AS month
    , COUNT(DISTINCT order_id) AS number_of_sales
    , SUM(price_usd) AS total_revenue
    , SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < '2013-01-04'
GROUP BY 1,2
;

/*
Impact on new product launch.
Conversion rate and revenue per session are improving.
Is it due to new product launch or just a continuation of the overall business improvement?
*/

SELECT 
      YEAR(ws.created_at) AS year
    , MONTH(ws.created_at) AS month
    , COUNT(DISTINCT ws.website_session_id) AS sessions
    , COUNT(DISTINCT o.order_id) AS orders
    , COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rate
    , SUM(o.price_usd)/COUNT(DISTINCT ws.website_session_id) AS revenue_per_session
    , COUNT(DISTINCT CASE WHEN primary_product_id = 1 THEN o.order_id ELSE NULL END) AS product_one_orders
    , COUNT(DISTINCT CASE WHEN primary_product_id = 2 THEN o.order_id ELSE NULL END) AS product_two_orders
FROM website_sessions ws
	LEFT JOIN orders o ON ws.website_session_id = o.website_session_id
WHERE ws.created_at BETWEEN '2012-04-01' AND '2013-04-05'
GROUP BY 1,2
;

/*
Product level website pathing.
Focus on sessions which hit the products page and see where they went next.
Overall click-through-rate has gone up while ctr declined for mcfuzzy.
Adding the additional product, lovebear, did canibalize some for mcfuzzy.
STEP 1: find the relevant / products pageviews with website_session_id
STEP 2: find the next pageview id that occurs after the product pageview
STEP 3: find the pageview_url associated with any applicable next pageview id
STEP 4: summarize the data and analyze the pre vs post periods
*/

-- STEP 1: find the relevant / products pageviews with website_session_id
CREATE TEMPORARY TABLE products_pageviews
SELECT 
      website_session_id
    , website_pageview_id
    , created_at
    , CASE 
        WHEN created_at < '2013-01-06' THEN 'A. Pre_Product_2'
        WHEN created_at >= '2013-01-06' THEN 'B. Post_Product_2'
        ELSE 'other'
      END AS time_period
FROM website_pageviews wp 
WHERE created_at < '2013-04-06'
    AND created_at > '2012-10-06'
    AND pageview_url = '/products'
;

-- STEP 2: find the next pageview id that occurs after the product pageview
CREATE TEMPORARY TABLE sessions_w_next_pageview_id
SELECT 
    pp.time_period
  , pp.website_session_id
  , MIN(wp.website_pageview_id) AS min_next_pageview_id
FROM products_pageviews pp 
  LEFT JOIN website_pageviews wp 
    ON pp.website_session_id = wp.website_session_id
    AND pp.website_pageview_id < wp.website_pageview_id
GROUP BY 1,2
;

-- STEP 3: find the pageview_url associated with any applicable next pageview id
CREATE TEMPORARY TABLE sessions_w_next_pageview_url
SELECT
      swnp.time_period
    , swnp.website_session_id
    , wp.pageview_url AS next_pageview_url
FROM sessions_w_next_pageview_id swnp
LEFT JOIN website_pageviews wp 
	ON wp.website_pageview_id = swnp.min_next_pageview_id
;

-- STEP 4: summarize the data and analyze the pre vs post periods
SELECT 
      time_period
    , COUNT(DISTINCT website_session_id) AS sessions
    , COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_pg
    , COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_w_next_pg
    , COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy
    , COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_to_mrfuzzy
    , COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear
    , COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_to_lovebear
FROM sessions_w_next_pageview_url
GROUP BY 1
;

/*
Product Conversion Funnels.
STEP 1: select all pageviews for relevant sessions.
STEP 2: figure out which pageview urls to look for.
STEP 3: pull all pageviews and. identify the funnel steps.
STEP 4: create the session-level conversion funnel view.
STEP 5: aggregate the data to assess funnel performance
*/


CREATE TEMPORARY TABLE sessions_seeing_product_pages
SELECT 
    website_session_id
  , website_pageview_id
  , pageview_url as product_page_seen
FROM website_pageviews
WHERE created_at < '2013-04-10'
  AND created_at > '2013-01-06'
  AND pageview_url in ('/the-original-mr-fuzzy', '/the-forever-love-bear')
;


-- Finding the right pageview_url to build the funnels
SELECT DISTINCT
    wp.pageview_url
FROM sessions_seeing_product_pages sspg
LEFT JOIN website_pageviews wp 
  ON wp.website_session_id = sspg.website_session_id
  AND wp.website_pageview_id > sspg.website_pageview_id
;

CREATE TEMPORARY TABLE session_product_level_made_it_flags
SELECT
      website_session_id
    , CASE
        WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mcfuzzy'
        WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
        ELSE 'check'
      END AS product_seen
	, MAX(cart_page) AS cart_made_it
	, MAX(shipping_page) AS shipping_made_it
	, MAX(billing_page) AS billing_made_it
	, MAX(thankyou_page) AS thankyou_made_it
FROM(
SELECT 
      sspg.website_session_id
    , sspg.product_page_seen
    , CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
    , CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page
    , CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page
    , CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_pages sspg
LEFT JOIN website_pageviews wp
    ON wp.website_session_id = sspg.website_session_id
    AND wp.website_pageview_id > sspg.website_pageview_id
) AS pageview_level
GROUP BY 1,2
;

-- final output 1

SELECT
      product_seen
    , COUNT(DISTINCT website_session_id) AS sessions
    , COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart
    , COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping
    , COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing
    , COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou

FROM session_product_level_made_it_flags
GROUP BY 1
;

-- final output 2 click rates
SELECT
      product_seen
    , COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS product_page_click_rate
    , COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)/ COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rate
    , COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rate
    , COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rate
FROM session_product_level_made_it_flags
GROUP BY 1
;

/*
Cross selling analysis.
CTR from the /cart page didn't go down and products per order,
AOV, and revenue per cart are up slighlt since the cross-sell feature 
was added. Trends look positive but doesn't look like a game changer.
*/

CREATE TEMPORARY TABLE sessions_seeing_cart
SELECT
    CASE 
      WHEN created_at < '2013-09-25' THEN 'A. Pre_Cross_Sell'
      WHEN created_at >= '2013-01-06' THEN 'B. Post_Cross_Sell'
      ELSE 'check'
    END AS time_period
    , website_session_id AS cart_session_id
    , website_pageview_id AS cart_pageview_id
FROM website_pageviews wp 
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
AND pageview_url = '/cart'
;

CREATE TEMPORARY TABLE cart_sessions_seeing_another_page
SELECT
      ssc.time_period
    , ssc.cart_session_id
    , MIN(wp.website_pageview_id) AS pv_id_after_cart
FROM sessions_seeing_cart ssc
  LEFT JOIN website_pageviews wp
    ON wp.website_session_id = ssc.cart_session_id
    AND wp.website_pageview_id > ssc.cart_pageview_id
GROUP BY 1,2
HAVING MIN(wp.website_pageview_id) IS NOT NULL
;

CREATE TEMPORARY TABLE pre_post_sessions_orders
SELECT
      time_period
    , cart_session_id
    , order_id
    , items_purchased
    , price_usd
FROM sessions_seeing_cart ssc
INNER JOIN orders o 
	ON ssc.cart_session_id = o.website_session_id
;

SELECT
      time_period
    , COUNT(DISTINCT cart_session_id) AS cart_sessions
    , SUM(clicked_to_another_page) AS clickthroughs
    , SUM(clicked_to_another_page)/COUNT(DISTINCT cart_session_id) AS cart_ctr
    , SUM(items_purchased)/SUM(placed_order) AS products_per_order
    , SUM(price_usd)/SUM(placed_order) AS aov
    , SUM(price_usd)/COUNT(DISTINCT cart_session_id) AS rev_per_cart_session
FROM(
SELECT
      ssc.time_period
    , ssc.cart_session_id
    , CASE WHEN css.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page
    , CASE WHEN pps.order_id IS NOT NULL THEN 0 ELSE 1 END AS placed_order
    , pps.items_purchased
    , pps.price_usd
FROM sessions_seeing_cart ssc
	LEFT JOIN cart_sessions_seeing_another_page css
		ON ssc.cart_session_id = css.cart_session_id
	LEFT JOIN pre_post_sessions_orders pps 
		ON ssc.cart_session_id = pps.cart_session_id
) AS full_data
GROUP BY 1
;

/*
Product portfolio expansion.
Critical metrics have improved since the launch of the third product.
*/

SELECT 
    CASE 
      WHEN ws.created_at < '2013-12-12' THEN 'A. Pre_Birthday_Bear'
      WHEN ws.created_at >= '2013-12-12' THEN 'B. Post_Birthday_Bear'
      ELSE 'check'
    END AS time_period
    , COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) AS conv_rate
    , SUM(o.price_usd)/COUNT(DISTINCT o.order_id) AS aov
    , SUM(o.items_purchased)/COUNT(DISTINCT o.order_id) AS products_per_order
    , SUM(price_usd)/ COUNT(DISTINCT ws.website_session_id) AS revenue_per_session
FROM website_sessions ws 
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE ws.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1
;
