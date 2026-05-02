--------------------------------------------
--CHECKING order table
--------------------------------------------
--NULL or DUPLICATE check for Primary Key column
SELECT
	TOP 10 *
FROM
	orders
WHERE order_id IS NULL

--Duplicate in Primary Key check
SELECT
	order_id,
	COUNT(*)
FROM
	orders
GROUP BY
	order_id
HAVING
	COUNT(*) > 1

--Check for negative values in quantity and sales amount columns
SELECT
	TOP 5 *
FROM
	orders
WHERE
	quantity < 0 OR
	sales_amount < 0

--Check for invalid order dates
SELECT
	TOP 5 *
FROM
	orders
WHERE
	order_date > GETDATE() OR
	order_date < '2022-01-01'

--------------------------------------------
--CHECKING product table
--------------------------------------------
--NULL or DUPLICATE check for Primary Key column
SELECT
	TOP 10 *
FROM
	products
WHERE product_id IS NULL

--Duplicate in Primary Key check
SELECT
	product_id,
	COUNT(*)
FROM
	products
GROUP BY
	product_id
HAVING
	COUNT(*) > 1

--Check for unwanted spaces
SELECT
	product_name
FROM
	products
WHERE
	product_name != TRIM(product_name)

SELECT
	product_category
FROM
	products
WHERE
	product_category != TRIM(product_category)

--------------------------------------------
--CHECKING customer table
--------------------------------------------
--NULL or DUPLICATE check for Primary Key column
SELECT
	TOP 10 *
FROM
	customers
WHERE customer_id IS NULL

--Duplicate in Primary Key check
SELECT
	customer_id,
	COUNT(*)
FROM
	customers
GROUP BY
	customer_id
HAVING
	COUNT(*) > 1

--Check for unwanted spaces
SELECT
	*
FROM
	customers
WHERE
	customer_name != TRIM(customer_name)

--Check for invalid dates
SELECT
	customer_id
FROM
	customers
WHERE
	signup_date > GETDATE() OR
	signup_date < '2022-01-01'

--------------------------------------------
--For some orders that doesnt have customer info (customer ids in orders table are not present in customers table) 
--we had to do standardization by adding custom values in order to not end up with blank values in PowerBI
INSERT INTO customers
(customer_id, customer_name, region, country, signup_date)
VALUES
(0,'Unknown','Unknown','Unknown','1900-01-01')

--Orders without customer info are all standardized in one group
UPDATE orders
SET customer_id = 0
WHERE 
	customer_id NOT IN (SELECT customer_id 
						FROM customers)

--Found that dataset contain orders from 1/1/2023 to 28/12/2025 and in that time window we collected 50000 orders
--10.02 and 900.00 are the lowest and highest prices which means that we have some cheap products but also high price products so there is a variety
--453.97 average price

SELECT
	MIN(order_date) AS first_order,
	MAX(order_date) AS last_order,
	COUNT(*) AS orders_count,
	MIN(price) AS lowest_product_price,
	MAX(price) AS highest_product_price,
	AVG(price) AS avg_price
FROM
	view_orders

--2 products haven't been ordered yet
SELECT 
	p.product_name AS not_ordered_products
FROM
	view_orders o
FULL JOIN
	view_products p
ON
	o.product_id = p.product_id
WHERE 
	o.order_id IS NULL

--Cleaned order table, price and quantity columns had nulls
--Order status had inconsistent cases
CREATE OR ALTER VIEW view_orders AS
SELECT
	order_id,
	product_id,
	customer_id,
	order_date,
	CAST(ROUND(COALESCE(price, sales_amount / quantity), 2) AS DECIMAL(12,2)) AS price,
	CAST(COALESCE(quantity, sales_amount / price) AS INT) AS quantity,
	sales_amount,
	LOWER(order_status) AS order_status
FROM
	orders