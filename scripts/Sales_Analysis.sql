--Core revenue metrics for current year
WITH current_year AS (
	SELECT
		SUM(sales_amount) AS total_revenue,
		COUNT(*) AS total_orders,
		COUNT(DISTINCT product_id) AS total_unique_products,
		COUNT(DISTINCT customer_id) AS total_unique_customers
	FROM
		view_orders
	WHERE
		order_date >= DATETRUNC(YEAR, GETDATE())
)

SELECT
	total_revenue,
	total_orders,
	total_revenue / total_orders AS avg_order_value,
	total_revenue / unique_products AS revenue_per_product,
	total_revenue / unique_customers AS revenue_per_customer
FROM
	current_year

--Year over year metrics by whole year, 
--same can be done on month and quarter level as well
WITH current_year AS (
	SELECT
		SUM(sales_amount) AS total_revenue,
		COUNT(*) AS total_orders,
		COUNT(DISTINCT customer_id) AS unique_customers
	FROM
		view_orders
	WHERE
		order_date >= DATETRUNC(YEAR, GETDATE())
),
previous_year AS (
	SELECT
		SUM(sales_amount) AS total_revenue,
		COUNT(*) AS total_orders,
		COUNT(DISTINCT customer_id) AS unique_customers
	FROM
		view_orders
	WHERE
		order_date < DATETRUNC(YEAR, GETDATE()) AND order_date >= DATETRUNC(YEAR, DATEADD(YEAR, -1, GETDATE()))
)

SELECT
	c.total_revenue AS current_year_revenue,
	p.total_revenue AS previous_year_revenue,
	CAST(ROUND((c.total_revenue - p.total_revenue) * 100 / p.total_revenue, 2) AS FLOAT) AS yoy_revenue_growth,
	c.total_orders AS current_year_total_orders,
	p.total_orders AS previous_year_total_orders,
	CAST(ROUND((c.total_orders - p.total_orders) * 100.0 / p.total_orders, 2) AS FLOAT) AS yoy_orders_growth,
	c.unique_customers AS current_year_customers,
	p.unique_customers AS previous_year_customers,
	CAST(ROUND((c.unique_customers - p.unique_customers) * 100.0 / p.unique_customers, 2) AS FLOAT) AS yoy_customers_growth
FROM
	current_year c, previous_year p;

--Year over year and month over month growth, 
--showing where we are in terms of total revenue, number of orders and number of customers compared
--to previous month and compared to same month last year
WITH current_month AS (
	SELECT
		SUM(sales_amount) AS total_revenue,
		COUNT(*) AS total_orders,
		COUNT(DISTINCT customer_id) AS unique_customers
	FROM
		view_orders
	WHERE
		order_date >= DATETRUNC(MONTH, GETDATE())
),
previous_month AS (
	SELECT
		SUM(sales_amount) AS total_revenue,
		COUNT(*) AS total_orders,
		COUNT(DISTINCT customer_id) AS unique_customers
	FROM
		view_orders
	WHERE
		order_date >= DATETRUNC(MONTH, DATEADD(MONTH, -1, GETDATE())) AND order_date < DATETRUNC(MONTH, GETDATE())
),
same_month_last_year AS (
	SELECT
		SUM(sales_amount) AS total_revenue,
		COUNT(*) AS total_orders,
		COUNT(DISTINCT customer_id) AS unique_customers
	FROM
		view_orders
	WHERE
		order_date >= DATETRUNC(MONTH, DATEADD(MONTH, -12, GETDATE())) AND order_date < DATETRUNC(MONTH, DATEADD(MONTH, -11, GETDATE()))
)

SELECT
	c.total_revenue AS current_month_revenue,
	p.total_revenue AS previous_month_revenue,
	CAST(ROUND((c.total_revenue - p.total_revenue) * 100 / p.total_revenue, 2) AS FLOAT) AS mom_revenue_growth,
	s.total_revenue AS same_month_prev_year_revenue,
	CAST(ROUND((c.total_revenue - s.total_revenue) * 100 / s.total_revenue, 2) AS FLOAT) AS yoy_revenue_growth,
	c.total_orders AS current_month_total_orders,
	p.total_orders AS previous_month_total_orders,
	CAST(ROUND((c.total_orders - p.total_orders) * 100.0 / p.total_orders, 2) AS FLOAT) AS mom_orders_growth,
	c.unique_customers AS current_month_customers,
	p.unique_customers AS previous_month_customers,
	CAST(ROUND((c.unique_customers - p.unique_customers) * 100.0 / p.unique_customers, 2) AS FLOAT) AS mom_customers_growth
FROM
	current_month c, previous_month p, same_month_last_year s

--Analysis of regional performance
WITH regional_current_year AS (
	SELECT
		region,
		SUM(sales_amount) AS total_revenue,
		COUNT(*) AS total_orders,
		COUNT(DISTINCT o.customer_id) AS unique_customers
	FROM
		view_orders o
	LEFT JOIN
		view_customers c
	ON 
		o.customer_id = c.customer_id
	WHERE
		order_date >= DATETRUNC(YEAR, GETDATE())
	GROUP BY
		region
),
regional_prev_year AS (
	SELECT
		region,
		SUM(sales_amount) AS total_revenue,
		COUNT(*) AS total_orders,
		COUNT(DISTINCT o.customer_id) AS unique_customers
	FROM
		orders o
	LEFT JOIN
		view_customers c
	ON 
		o.customer_id = c.customer_id
	WHERE
		order_date >= DATETRUNC(YEAR, DATEADD(YEAR, -1, GETDATE())) AND order_date < DATETRUNC(YEAR, GETDATE())
	GROUP BY
		region
)

SELECT
	c.region,
	c.total_revenue AS current_year_revenue,
	p.total_revenue AS previous_year_revenue,
	CAST(ROUND((c.total_revenue - p.total_revenue) * 100 / p.total_revenue, 2) AS FLOAT) AS yoy_revenue_growth,
	CAST(ROUND(c.total_revenue / c.total_orders, 2) AS FLOAT) AS avg_order_value,
	CAST(ROUND(c.total_revenue / SUM(c.total_revenue) OVER() * 100, 2) AS FLOAT) AS revenue_share
FROM
	regional_current_year c
LEFT JOIN
	regional_prev_year p
ON 
	c.region = p.region

--Analysis of product performance - Lenovo Select FHD Webcam is clear winner by revenue growth in this year
WITH product_metrics_current AS (
	SELECT
		product_name,
		SUM(sales_amount) AS total_revenue,
		COUNT(*) AS total_orders,
		SUM(quantity) AS units_sold
	FROM
		view_orders o
	LEFT JOIN
		view_products p
	ON 
		o.product_id = p.product_id
	WHERE
		order_date >= DATETRUNC(YEAR, GETDATE())
	GROUP BY
		product_name
),
product_metrics_prev AS (
	SELECT
		product_name,
		SUM(sales_amount) AS total_revenue,
		COUNT(*) AS total_orders,
		SUM(quantity) AS units_sold
	FROM
		view_orders o
	LEFT JOIN
		view_products p
	ON 
		o.product_id = p.product_id
	WHERE
		order_date >= DATETRUNC(YEAR, DATEADD(YEAR, -1, GETDATE())) AND order_date < DATETRUNC(YEAR, GETDATE())
	GROUP BY
		product_name
)

SELECT
	c.product_name,
	c.units_sold,
	c.total_revenue AS current_year_revenue,
	p.total_revenue AS previous_year_revenue,
	CAST(ROUND((c.total_revenue - p.total_revenue) * 100 / p.total_revenue, 2) AS FLOAT) AS yoy_revenue_growth,
	CAST(ROUND(c.total_revenue / c.total_orders, 2) AS FLOAT) AS avg_order_value,
	CAST(ROUND(c.total_revenue / c.units_sold, 2) AS FLOAT) AS avg_units_price
FROM
	product_metrics_current c
LEFT JOIN
	product_metrics_prev p
ON 
	c.product_name = p.product_name
ORDER BY
	current_year_revenue DESC

--Daily Sales and Trends plus Moving averages
WITH daily_sales AS (
    SELECT
        order_date,
        SUM(sales_amount) AS daily_revenue,
        COUNT(*) AS daily_orders
    FROM view_orders
    GROUP BY order_date
)
SELECT TOP 10
    order_date,
    daily_revenue,
    CAST(ROUND(AVG(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS decimal(12,2)) AS ma_7_day,
    CAST(ROUND(AVG(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 2) AS decimal(12,2)) AS ma_30_day,
    daily_orders
FROM daily_sales
ORDER BY order_date DESC

--Monthly trends and growth rates - Clearly we have increasing trend of growth rates in the second half of the year, 
--peaking in the holiday season while significantly receding at the beginning of the year
WITH monthly_sales AS (
    SELECT
        DATETRUNC(MONTH, order_date) AS month,
        SUM(sales_amount) AS monthly_revenue,
        COUNT(*) AS monthly_orders,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM view_orders
    GROUP BY DATETRUNC(MONTH, order_date)
)
SELECT TOP 10
    month,
    monthly_revenue,
    LAG(monthly_revenue, 1) OVER (ORDER BY month) AS prev_month_revenue,
    CAST(ROUND((monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY month)) * 100.0 /
          LAG(monthly_revenue, 1) OVER (ORDER BY month), 2) AS DECIMAL(12,2)) AS mom_growth_pct,
    LAG(monthly_revenue, 12) OVER (ORDER BY month) AS same_month_last_year,
    CAST(ROUND((monthly_revenue - LAG(monthly_revenue, 12) OVER (ORDER BY month)) * 100.0 /
          LAG(monthly_revenue, 12) OVER (ORDER BY month), 2) AS DECIMAL(12,2)) AS yoy_growth_pct
FROM monthly_sales
ORDER BY month DESC

--Day of Week Seasonality - Highest revenue is made on Thursday and Friday 
--while the highest volume of sales happens on Saturday
SELECT
    DATENAME(WEEKDAY, order_date) AS week_day,
    DATEPART(WEEKDAY, order_date) AS day_number,
    COUNT(*) AS total_orders,
    SUM(sales_amount) AS total_revenue,
    CAST(ROUND(AVG(sales_amount), 2) AS DECIMAL(12,2)) AS avg_order_value,
    CAST(ROUND(SUM(sales_amount) * 100.0 / SUM(SUM(sales_amount)) OVER (), 2) AS DECIMAL(12,2)) AS revenue_share_pct
FROM view_orders
WHERE order_date >= DATEADD(DAY, -90, GETDATE())
GROUP BY DATENAME(WEEKDAY, order_date), DATEPART(WEEKDAY, order_date)
ORDER BY day_number;

--Monthly Seasonality Index which shows that end of year sales are constantly growing above average sales 
--while in the beginning of the year we have opposite tendencies
WITH monthly_avg AS (
    SELECT
        MONTH(order_date) AS month_number,
        DATENAME(MONTH, order_date) AS month_name,
        AVG(amount) AS avg_monthly_revenue
    FROM (
        SELECT order_date, SUM(sales_amount) AS amount
        FROM view_orders
        GROUP BY order_date
    ) daily_totals
    GROUP BY MONTH(order_date), DATENAME(MONTH, order_date)
),
overall_avg AS (
    SELECT AVG(amount) AS overall_avg_revenue
    FROM (
        SELECT order_date, SUM(sales_amount) AS amount
        FROM view_orders
        GROUP BY order_date
    ) daily_totals
)
SELECT
    m.month_number,
    m.month_name,
    CAST(ROUND(m.avg_monthly_revenue, 2) AS DECIMAL(12,2)) AS avg_revenue,
    CAST(ROUND(m.avg_monthly_revenue / o.overall_avg_revenue * 100, 2) AS DECIMAL(12,2)) AS seasonality_index
FROM monthly_avg m, overall_avg o
ORDER BY m.month_number;

--Trend Summary and Forecast Indicators - very high volatility and variability in monthly sales levels, 
--going from 0.55M in March to it's peak in December - 1.97M
WITH recent_months AS (
    SELECT
        DATETRUNC(MONTH, order_date) AS month,
        SUM(sales_amount) AS revenue
    FROM view_orders
    WHERE order_date >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY DATETRUNC(MONTH, order_date)
),
trend_calc AS (
    SELECT
        AVG(revenue) AS avg_monthly_revenue,
        STDEV(revenue) AS revenue_volatility,
        MAX(revenue) AS peak_revenue,
        MIN(revenue) AS lowest_revenue
    FROM recent_months
)
SELECT
    CAST(ROUND(avg_monthly_revenue, 2) AS DECIMAL(12,2)) AS avg_monthly_revenue,
    ROUND(revenue_volatility, 2) AS volatility,
    ROUND(revenue_volatility / avg_monthly_revenue * 100, 2) AS coefficient_of_variation,
    ROUND(peak_revenue, 2) AS peak_revenue,
    ROUND(lowest_revenue, 2) AS lowest_revenue,
    CASE
        WHEN revenue_volatility / avg_monthly_revenue < 0.15 THEN 'Stable'
        WHEN revenue_volatility / avg_monthly_revenue < 0.30 THEN 'Moderate'
        ELSE 'High Volatility'
    END AS trend_stability
FROM trend_calc;