-- 1. Gsearch seems to be the biggest driver of our business. 
-- Could you pull monthly trends for gsearch sessions and orders 
-- so that we can showcase the growth there?
SELECT
	YEAR(website_sessions.created_at) as year,
	MONTH(website_sessions.created_at) as month,
	count(website_sessions.website_session_id) as gsearch_sessions,
	count(order_id) as gsearch_orders,
	count(order_id) / count(website_sessions.website_session_id) as gsearch_conv_rate
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE utm_source = 'gsearch' and website_sessions.created_at < '2012-11-27'
GROUP BY 1, 2;



-- 2. Next, it would be great to see a similar monthly trend for Gsearch, 
-- but this time splitting out nonbrand and brand campaigns separately. 
-- I am wondering if brand is picking up at all. If so, this is a good story to tell.
SELECT
	YEAR(website_sessions.created_at) AS year,
	MONTH(website_sessions.created_at) AS month,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' 
						THEN website_sessions.website_session_id ELSE NULL END) 
								AS nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' 
						THEN orders.order_id ELSE NULL END) AS nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' 
						THEN website_sessions.website_session_id ELSE NULL END)
								AS brand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' 
						THEN orders.order_id ELSE NULL END) AS brand_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE utm_source = 'gsearch' and website_sessions.created_at < '2012-11-27'
GROUP BY 1,2



-- 3. while we're on Gsearch, could you dive into nonbrand, 
-- and pull sessions and orders split by device type? 
-- I want to flex our analytical muscles a little and show the board we really know 
-- our traffic sources.
SELECT
	YEAR(website_sessions.created_at) AS YEAR,
    MONTH(website_sessions.created_at) AS MONTH,
		COUNT(CASE WHEN device_type = 'desktop' 
				THEN website_sessions.website_session_id ELSE NULL END) 
					AS desktop_sessions,
    COUNT(CASE WHEN device_type = 'desktop' 
				THEN orders.order_id ELSE NULL END) AS desktop_orders,
    COUNT(CASE WHEN device_type = 'mobile' 
				THEN website_sessions.website_session_id ELSE NULL END) 
					AS mobile_sessions,
    COUNT(CASE WHEN device_type = 'mobile' 
				THEN orders.order_id ELSE NULL END) AS mobile_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE utm_source = 'gsearch' 
			AND utm_campaign = 'nonbrand' 
			AND website_sessions.created_at < '2012-11-27'
GROUP BY 1, 2



-- 4. I'm worried that one of our more pessimistic board members may be concerned about 
-- the large % of traffic from Gsearch. Can you pull monthly trends for Gsearch,
-- alongside monthly trends for each of our other channels.
SELECT
	distinct utm_source,
	utm_campaign,
    http_referer
FROM website_sessions
WHERE created_at < '2012-11-27'
-- first, finding the various utm sources and referers to see the traffic we're getting.
-- pulling the distinct combinations of utm source, utm campaign and http referrer.

SELECT 
	YEAR(website_sessions.created_at) as year,
	MONTH(website_sessions.created_at) as month,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' 
				THEN website_sessions.website_session_id ELSE NULL END) 
					AS gsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' 
				THEN website_sessions.website_session_id ELSE NULL END) 
					AS bsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL 
				THEN website_sessions.website_session_id ELSE NULL END) 
					AS organic_search_sessions,
					-- it doesn't have paid tracking but it does have a	referring domain
					-- from the search engine. -> organic search.
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL 
				THEN website_sessions.website_session_id ELSE NULL END) 
					AS direct_type_in_sessions
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY 1, 2;



-- 5. I'd like to tell the story of our website performance improvements 
-- over the course of the first 8 months. Could you pull session to order conversion rates, 
-- by month?
 SELECT
	YEAR(website_sessions.created_at) AS year,
    MONTH(website_sessions.created_at) AS month,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS ordrs,
    COUNT(DISTINCT orders.order_id) / 
			COUNT(DISTINCT website_sessions.website_session_id) AS conversion_rate
FROM website_sessions
	Left JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY 1,2



-- 6. For the gsearch lander test, please estimate the revenue that test earned us.
SELECT MIN(website_pageview_id) AS first_test_pv
FROM website_pageviews
WHERE pageview_url = '/lander-1';
-- min pageview id -> find when the teset started. first_test_pv: 23504

DROP TABLE IF EXISTS first_test_pageview;
CREATE TEMPORARY TABLE first_test_pageview
SELECT
	website_sessions.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
	JOIN website_sessions
		ON website_pageviews.website_session_id = 
				website_sessions.website_session_id
WHERE website_pageviews.website_pageview_id >= '23504'
	AND website_sessions.created_at < '2012-07-28'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY website_sessions.website_session_id;
-- session level table. session id, first pageview id of that session.

DROP TABLE IF EXISTS nonbrand_test_sessions_landing_pages;
CREATE TEMPORARY TABLE nonbrand_test_sessions_landing_pages
SELECT
	website_pageviews.website_session_id,
    pageview_url AS landing_page
FROM first_test_pageview
	LEFT JOIN website_pageviews
		ON first_test_pageview.min_pageview_id = 
				website_pageviews.website_pageview_id
WHERE pageview_url IN ('/home', '/lander-1');
-- bring in the landing page for each session but restricting to home/lander-1

DROP TABLE IF EXISTS nonbrand_test_session_orders;
CREATE TEMPORARY TABLE nonbrand_test_session_orders
SELECT
	nonbrand_test_sessions_landing_pages.website_session_id,
    nonbrand_test_sessions_landing_pages.landing_page,
    orders.order_id
FROM nonbrand_test_sessions_landing_pages
	LEFT JOIN orders
		ON nonbrand_test_sessions_landing_pages.website_session_id = 
				orders.website_session_id;
-- bring in orders

SELECT
	landing_page,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) AS conv_rate
FROM nonbrand_test_session_orders
GROUP BY 1;


SELECT 
	MAX(website_sessions.website_session_id) AS 
			most_recent_gsearch_nonbrand_home_session
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id = 
			website_pageviews.website_session_id
WHERE utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
    AND pageview_url = '/home'
    AND website_sessions.created_at < '2012-11-27';
-- find the last home lander traffic so that we can find when all traffic is rerouted to lander-1


SELECT
	COUNT(website_session_id) AS sessions_since_test
FROM website_sessions
WHERE created_at < '2012-11-27'
	AND website_session_id > 17145
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'



-- 7. For the landing page test you analyzed previously, it would be great to show a 
-- full conversion funnel from each of the two pages to orders. 
-- You can use the same time period you analyzed last time (Jun 19 - Jul 28).
DROP TABLE IF EXISTS session_level_made_it_flagged;
CREATE TEMPORARY TABLE session_level_made_it_flagged
SELECT
	website_session_id,
    MAX(homepage) AS saw_homepage,
    MAX(custom_lander) AS saw_custom_lander,
    MAX(products_page) AS product_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM (
		SELECT
			website_sessions.website_session_id,
			website_pageviews.pageview_url,
			-- website_sessions.created_at,
			CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
			CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
			CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
			CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END
				AS mrfuzzy_page,
			CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
			CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
			CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
			CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END 
				AS thankyou_page
		FROM website_sessions
			LEFT JOIN website_pageviews
				ON website_sessions.website_session_id = 
						website_pageviews.website_session_id
		WHERE website_sessions.utm_source = 'gsearch'
			AND website_sessions.utm_campaign = 'nonbrand'
			AND website_sessions.created_at > '2012-06-19'
			AND website_sessions.created_at < '2012-07-28'
		ORDER BY website_sessions.website_session_id, website_sessions.created_at
 ) AS pageview_level -- a flag say where this is the homepage, custom_lander, ...
 
GROUP BY website_session_id;


SELECT
	CASE
		WHEN saw_homepage = 1 THEN 'saw_homepage'
		WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'uh oh ... check logic'
	END AS segment,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id 
				ELSE NULL END) / COUNT(DISTINCT website_session_id) 
					AS lander_click_rt,

    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id 
				ELSE NULL END) / COUNT(DISTINCT CASE WHEN product_made_it = 1 
					THEN website_session_id ELSE NULL END) AS products_click_rt,

    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id 
				ELSE NULL END) / COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 
					THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rt,

    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id 
				ELSE NULL END) / COUNT(DISTINCT CASE WHEN cart_made_it = 1 
					THEN website_session_id ELSE NULL END) AS cart_click_rt,

    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id
				ELSE NULL END) / COUNT(DISTINCT CASE WHEN shipping_made_it = 1 
					THEN website_session_id ELSE NULL END) AS shipping_click_rt,

    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id 
				ELSE NULL END) / COUNT(DISTINCT CASE WHEN billing_made_it = 1 
					THEN website_session_id ELSE NULL END) AS billing_click_rt
    
FROM session_level_made_it_flagged
GROUP BY 1;



-- 8. I'd love for you to quantify the impact of our billing test, as well. 
-- Please analyze the lift generated from the test (Sep 10 - Nov 10), 
-- in terms of revenue per billing page session, and then 
-- pull the number of billing page sessions for the past month(10/27-11/27) 
-- to understand monthly impact.
SELECT
	billing_version_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    SUM(price_usd) / COUNT(DISTINCT website_session_id) 
				AS revenue_per_billing_page_seen
FROM (
	SELECT
		website_pageviews.website_session_id, 
		website_pageviews.pageview_url AS billing_version_seen, 
		orders.order_id, 
		orders.price_usd
	FROM website_pageviews
		LEFT JOIN orders
			ON website_pageviews.website_session_id = orders.website_session_id
	WHERE website_pageviews.created_at > '2012-09-10'
		AND website_pageviews.created_at < '2012-11-10'
		AND website_pageviews.pageview_url IN ('/billing', '/billing-2')
) AS billing_version_revenue
GROUP BY 1;


SELECT COUNT(website_session_id) AS billing_sessions_last_month
FROM website_pageviews
WHERE pageview_url IN ('/billing', '/billing-2')
	AND created_at > '2012-10-27'
	AND created_at < '2012-11-27'  -- past month