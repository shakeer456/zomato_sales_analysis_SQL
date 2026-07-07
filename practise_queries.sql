-- 1. Top 5 most frequently ordered dishes by customer (last 1 year)
WITH cte AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        o.order_item AS dishes,
        COUNT(o.order_id) AS total_orders,
        DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM orders o 
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_date > CURDATE() - INTERVAL 1 YEAR
      AND c.customer_name = 'Erik Dawson'
    GROUP BY c.customer_id, c.customer_name, o.order_item
)
SELECT customer_name, dishes, total_orders
FROM cte
WHERE rnk <= 5;


-- 2. Popular time slots (2-hour intervals)
SELECT 
    FLOOR(HOUR(order_time) / 2) * 2 AS start_time,
    FLOOR(HOUR(order_time) / 2) * 2 + 2 AS end_time,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY start_time, end_time
ORDER BY total_orders DESC;


-- 3. Order value analysis (customers with >750 orders)
SELECT 
    c.customer_id,
    c.customer_name,
    AVG(o.total_amount) AS avg_order_value,
    COUNT(o.order_id) AS total_orders
FROM orders o 
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(o.order_id) > 750;


-- 4. High value customers (spent >100k total)
SELECT 
    c.customer_id,
    c.customer_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.total_amount) > 100000;


-- 5. Orders without delivery
SELECT 
    r.restaurant_name,
    r.city,
    COUNT(o.order_id) AS total_undelivered_orders
FROM orders o 
LEFT JOIN restaurants r ON o.restaurant_id = r.restaurant_id
LEFT JOIN delivery d ON d.order_id = o.order_id
WHERE d.delivery_id IS NULL
GROUP BY r.restaurant_name, r.city
ORDER BY total_undelivered_orders DESC;


-- 6. Restaurant revenue ranking (top in each city last year)
WITH cte AS (
    SELECT 
        r.restaurant_name,
        r.city,
        SUM(o.total_amount) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS rnk
    FROM orders o 
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    WHERE o.order_date >= CURDATE() - INTERVAL 1 YEAR
    GROUP BY r.restaurant_name, r.city
)
SELECT *
FROM cte
WHERE rnk = 1;


-- 7. Most popular dish by city
WITH cte AS (
    SELECT 
        r.city,
        o.order_item AS dish,
        COUNT(o.order_id) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY r.city ORDER BY COUNT(o.order_id) DESC) AS rnk
    FROM orders o 
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.city, o.order_item
)
SELECT city, dish, total_orders
FROM cte
WHERE rnk = 1
ORDER BY city;


-- 8. Customer churn (active in 2024, inactive in 2025)
SELECT DISTINCT customer_id
FROM orders
WHERE YEAR(order_date) = 2024
  AND customer_id NOT IN (
      SELECT customer_id FROM orders WHERE YEAR(order_date) = 2025
  );


-- 9. Cancellation rate comparison (2024 vs 2025)
WITH cancellation_24 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        SUM(CASE WHEN d.delivery_id IS NULL AND o.order_status = 'cancelled' THEN 1 ELSE 0 END) AS not_delivered
    FROM orders o 
    LEFT JOIN delivery d ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2024
    GROUP BY o.restaurant_id
),
py_data AS (
    SELECT 
        restaurant_id,
        total_orders,
        not_delivered,
        (not_delivered / total_orders) * 100 AS cancellation_ratio
    FROM cancellation_24
),
cancellation_25 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        SUM(CASE WHEN d.delivery_id IS NULL AND o.order_status = 'cancelled' THEN 1 ELSE 0 END) AS not_delivered
    FROM orders o 
    LEFT JOIN delivery d ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2025
    GROUP BY o.restaurant_id
),
cy_data AS (
    SELECT 
        restaurant_id,
        total_orders,
        not_delivered,
        (not_delivered / total_orders) * 100 AS cancellation_ratio
    FROM cancellation_25
)
SELECT 
    pyd.restaurant_id,
    pyd.cancellation_ratio AS prev_year_cancellation_ratio,
    cyd.cancellation_ratio AS curr_year_cancellation_ratio,
    (cyd.cancellation_ratio - pyd.cancellation_ratio) AS ratio_change,
    CASE 
        WHEN cyd.cancellation_ratio > pyd.cancellation_ratio THEN 'Increased'
        WHEN cyd.cancellation_ratio < pyd.cancellation_ratio THEN 'Decreased'
        ELSE 'No Change'
    END AS trend
FROM py_data pyd
JOIN cy_data cyd ON pyd.restaurant_id = cyd.restaurant_id
ORDER BY ratio_change DESC;


-- 10. Rider average delivery time
SELECT 
    o.order_id,
    o.order_time,
    d.rider_id,
    d.delivery_time,
    TIMESTAMPDIFF(SECOND, o.order_time, d.delivery_time) AS duration_seconds,
    CASE 
        WHEN TIMESTAMPDIFF(SECOND, o.order_time, d.delivery_time) > 0 THEN 'Normal Delivery'
        WHEN TIMESTAMPDIFF(SECOND, o.order_time, d.delivery_time) < 0 THEN 'Data Error'
        ELSE 'Instant Delivery'
    END AS status
FROM orders o
JOIN delivery d ON o.order_id = d.order_id
WHERE d.delivery_status = 'delivered';


-- 11. Monthly restaurant growth ratio
WITH cte AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS current_month_orders,
        DATE_FORMAT(o.order_date, '%m/%y') AS month_year,
        LAG(COUNT(o.order_id), 1) OVER (PARTITION BY o.restaurant_id ORDER BY DATE_FORMAT(o.order_date, '%m/%y')) AS prev_month_orders
    FROM orders o
    JOIN delivery d ON o.order_id = d.order_id 
    GROUP BY o.restaurant_id, DATE_FORMAT(o.order_date, '%m/%y')
)
SELECT 
    restaurant_id,
    month_year,
    current_month_orders,
    prev_month_orders,
    ROUND(((current_month_orders - prev_month_orders) / prev_month_orders) * 100, 2) AS growth_ratio
FROM cte;


-- 12. Customer segmentation (Gold/Silver)
WITH customer_categories AS (
    SELECT 
        customer_id,
        SUM(total_amount) AS total_spending,
        COUNT(order_id) AS total_orders,
        CASE 
            WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold'
            ELSE 'Silver'
        END AS customer_category
    FROM orders 
    GROUP BY customer_id
)
SELECT 
    customer_category,
    SUM(total_spending) AS total_amount_spent,
    SUM(total_orders) AS total_orders_placed,
    COUNT(customer_id) AS number_of_customers,
    ROUND(AVG(total_spending), 2) AS avg_spending_per_customer
FROM customer_categories
GROUP BY customer_category
ORDER BY total_amount_spent DESC;


-- 13. Rider's monthly earnings (8% commission)
SELECT 
    d.rider_id,
    DATE_FORMAT(o.order_date, '%m/%y') AS months,
    SUM(o.total_amount) AS total_revenue,
    ROUND(SUM(o.total_amount) * 0.08, 0) AS rider_earning
FROM orders o
JOIN delivery d ON o.order_id = d.order_id
GROUP BY d.rider_id, DATE_FORMAT(o.order_date, '%m/%y')
ORDER BY d.rider_id, months;


-- 14. Rider rating analysis
WITH cte AS (
    SELECT 
        d.rider_id,
        r.rider_name,
        CASE 
            WHEN TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time) < 15 THEN '5-star Rating'
            WHEN TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time) BETWEEN 15 AND 20 THEN '4-star Rating'
            ELSE '3-star Rating'
        END AS Rating
    FROM orders o 
    JOIN delivery d ON o.order_id = d.order_id
    JOIN riders r ON d.rider_id = r.rider_id
    WHERE d.delivery_status = 'delivered'
)
SELECT 
    rider_id,
    rider_name,
    SUM(CASE WHEN rating = '5-star Rating' THEN 1 ELSE 0 END) AS five_star_ratings,
    SUM(CASE WHEN rating = '4-star Rating' THEN 1 ELSE 0 END) AS four_star_ratings,
    SUM(CASE WHEN rating = '3-star Rating' THEN 1 ELSE 0 END) AS three_star_ratings,
    COUNT(*) AS total_deliveries
FROM cte
GROUP BY rider_id, rider_name
ORDER BY five_star_ratings DESC;


-- 15. Order frequency by day (peak day per restaurant)
WITH cte AS (
    SELECT 
        r.restaurant_name,
        DAYNAME(o.order_date) AS day_,
        COUNT(o.order_id) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY r.restaurant_name ORDER BY COUNT(o.order_id) DESC) AS rnk
    FROM orders o
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_name, DAYNAME(o.order_date)
)
SELECT *
FROM cte
WHERE rnk = 1;


-- 16. Customer lifetime value (CLV)
SELECT 
    c.customer_id,
    c.customer_name,
    SUM(o.total_amount) AS clv_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name;


-- 17. Monthly sales trends (current vs previous month)
SELECT 
    YEAR(order_date) AS year_,
    MONTH(order_date) AS month_,
    SUM(total_amount) AS current_month_sales,
    LAG(SUM(total_amount), 1) OVER (ORDER BY YEAR(order_date), MONTH(order_date)) AS previous_month_sales
FROM orders 
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY year_, month_;


-- 18. Rider efficiency
WITH cte AS (
    SELECT 
        d.rider_id,
        r.rider_name,
        TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time) AS delivery_time_minutes
    FROM orders o 
    JOIN delivery d ON o.order_id = d.order_id
    JOIN riders r ON d.rider_id = r.rider_id
    WHERE d.delivery_status = 'delivered'
)
SELECT 
    rider_id,
    rider_name,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time,
    CASE 
        WHEN AVG(delivery_time_minutes) < (SELECT AVG(delivery_time_minutes) FROM cte) THEN 'Efficient'
        ELSE 'Not Efficient'
    END AS efficiency
FROM cte
GROUP BY rider_id, rider_name
ORDER BY avg_delivery_time ASC;


-- 19. Order item popularity (seasonal trends)
WITH cte AS (
    SELECT 
        *,
        CASE 
            WHEN MONTH(order_date) IN (1, 2, 3, 4) THEN 'Winter'
            WHEN MONTH(order_date) IN (5, 6, 7, 8) THEN 'Summer'
            ELSE 'Monsoon'
        END AS seasons
    FROM orders
)
SELECT 
    order_item,
    seasons,
    COUNT(order_id) AS total_orders
FROM cte
GROUP BY order_item, seasons
ORDER BY order_item, total_orders DESC;


-- 20. Rank each city based on total revenue
SELECT 
    r.city,
    SUM(o.total_amount) AS revenue,
    DENSE_RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS rnk
FROM orders o 
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city
ORDER BY r.city;
