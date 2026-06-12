CREATE DATABASE ecom;
USE ecom;


-- =========================
-- 1. PARENT TABLES
-- =========================

CREATE TABLE customers_transformed (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_unique_id VARCHAR(20),
    customer_zip_code VARCHAR(20),
    customer_city VARCHAR(100),
    customer_state VARCHAR(100),
    signup_date DATE,
    gender VARCHAR(20),
    age INT,
    age_group VARCHAR(20)
);

select*from customers_transformed;

CREATE TABLE products_transformed (
    product_id VARCHAR(20) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g FLOAT,
    product_length_cm FLOAT,
    product_height_cm FLOAT,
    product_width_cm FLOAT
);

CREATE TABLE sellers_transformed (
    seller_id VARCHAR(20) PRIMARY KEY,
    seller_zip_code VARCHAR(20),
    seller_city VARCHAR(100),
    seller_state VARCHAR(100)
);


CREATE TABLE geolocation_transformed (
    geolocation_zip_code VARCHAR(20) PRIMARY KEY,
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(100)
);

-- =========================
-- 2. ORDERS TABLE
-- =========================

CREATE TABLE orders_transformed (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    order_status VARCHAR(50),

    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,

    purchase_month VARCHAR(20),
    purchase_quarter INT,
    purchase_weekday VARCHAR(20),

    delivery_delay INT,
    processing_time INT,

    FOREIGN KEY (customer_id)
        REFERENCES customers_transformed(customer_id)
);
-- =========================
-- 3. CHILD TABLES
-- =========================

CREATE TABLE order_items_transformed (
    order_id VARCHAR(20),
    order_item_id INT,

    product_id VARCHAR(20),
    seller_id VARCHAR(20),

    shipping_limit_date DATETIME,

    price FLOAT,
    freight_value FLOAT,
    total_item_value FLOAT,
    estimated_profit FLOAT,

    PRIMARY KEY (order_id, order_item_id),

    FOREIGN KEY (order_id)
        REFERENCES orders_transformed(order_id),

    FOREIGN KEY (product_id)
        REFERENCES products_transformed(product_id),

    FOREIGN KEY (seller_id)
        REFERENCES sellers_transformed(seller_id)
);

CREATE TABLE payments_transformed (
    order_id VARCHAR(20),
    payment_sequential INT,

    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value FLOAT,

    is_installment INT,
    high_value_payment INT,

    PRIMARY KEY (order_id, payment_sequential),

    FOREIGN KEY (order_id)
        REFERENCES orders_transformed(order_id)
);

truncate table payments_transformed;

CREATE TABLE reviews_transformed (
    review_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(20),

    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,

    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,

    FOREIGN KEY (order_id)
        REFERENCES orders_transformed(order_id)
);

TRUNCATE TABLE reviews_transformed;




-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Total Revenue
SELECT SUM(total_item_value) AS total_revenue
FROM order_items_transformed;


-- Monthly Revenue Trend
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    SUM(oi.price) AS revenue
FROM orders_transformed o
JOIN order_items_transformed oi
ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;


-- Top Revenue Categories
SELECT 
    p.product_category_name,
    SUM(oi.price) AS revenue
FROM order_items_transformed oi
JOIN products_transformed p
ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY revenue DESC;


-- Top Selling Products
SELECT 
    product_id,
    COUNT(*) AS units_sold,
    SUM(price) AS revenue
FROM order_items_transformed
GROUP BY product_id
ORDER BY revenue DESC;


-- Payment Method Analysis
SELECT 
    payment_type,
    COUNT(*) AS transactions,
    SUM(payment_value) AS revenue
FROM payments_transformed
GROUP BY payment_type
ORDER BY revenue DESC;


-- Top States by Revenue
SELECT 
    c.customer_state,
    SUM(oi.price) AS revenue
FROM orders_transformed o
JOIN order_items_transformed oi ON o.order_id = oi.order_id
JOIN customers_transformed c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY revenue DESC;


-- Top Cities by Sales
SELECT 
    c.customer_city,
    SUM(oi.price) AS revenue
FROM orders_transformed o
JOIN order_items_transformed oi ON o.order_id = oi.order_id
JOIN customers_transformed c ON o.customer_id = c.customer_id
GROUP BY c.customer_city
ORDER BY revenue DESC;


-- Average Order Value
SELECT 
    AVG(order_total) AS avg_order_value
FROM (
    SELECT 
        o.order_id,
        SUM(oi.price) AS order_total
    FROM orders_transformed o
    JOIN order_items_transformed oi
    ON o.order_id = oi.order_id
    GROUP BY o.order_id
) t;


-- Repeat Customers
SELECT 
    customer_id,
    COUNT(order_id) AS total_orders
FROM orders_transformed
GROUP BY customer_id
HAVING COUNT(order_id) > 1
ORDER BY total_orders DESC;


-- Customer Purchase Frequency
SELECT 
    customer_id,
    COUNT(order_id) AS purchase_count
FROM orders_transformed
GROUP BY customer_id
ORDER BY purchase_count DESC;


-- Delivery Delay Analysis
SELECT 
    AVG(delivery_delay) AS avg_delay
FROM orders_transformed;


-- Seller Performance Analysis
SELECT 
    seller_id,
    SUM(price) AS revenue,
    COUNT(*) AS items_sold
FROM order_items_transformed
GROUP BY seller_id
ORDER BY revenue DESC;


-- Region-wise Customer Distribution
SELECT 
    customer_state,
    COUNT(customer_id) AS customers
FROM customers_transformed
GROUP BY customer_state
ORDER BY customers DESC;


-- Order Status Analysis (Cancellation etc.)
SELECT 
    order_status,
    COUNT(*) AS total_orders
FROM orders_transformed
GROUP BY order_status;


-- Peak Purchase Time Analysis
SELECT 
    HOUR(order_purchase_timestamp) AS hour,
    COUNT(*) AS total_orders
FROM orders_transformed
GROUP BY hour
ORDER BY total_orders DESC;


-- New vs Returning Customers
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'New'
        ELSE 'Returning'
    END AS customer_type,
    COUNT(*) AS customers
FROM (
    SELECT customer_id, COUNT(order_id) AS order_count
    FROM orders_transformed
    GROUP BY customer_id
) t
GROUP BY customer_type;


-- Seasonal Sales Trends
SELECT 
    MONTH(o.order_purchase_timestamp) AS month,
    SUM(oi.price) AS revenue
FROM orders_transformed o
JOIN order_items_transformed oi
ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;


-- Highest Rated Products
SELECT 
    oi.product_id,
    AVG(r.review_score) AS avg_rating
FROM reviews_transformed r
JOIN order_items_transformed oi ON r.order_id = oi.order_id
GROUP BY oi.product_id
ORDER BY avg_rating DESC;


-- Lowest Rated Products
SELECT 
    oi.product_id,
    AVG(r.review_score) AS avg_rating
FROM reviews_transformed r
JOIN order_items_transformed oi ON r.order_id = oi.order_id
GROUP BY oi.product_id
ORDER BY avg_rating ASC;


-- Product Review Distribution
SELECT 
    review_score,
    COUNT(*) AS total_reviews
FROM reviews_transformed
GROUP BY review_score
ORDER BY review_score;


-- Most Profitable Categories
SELECT 
    p.product_category_name,
    SUM(oi.estimated_profit) AS profit
FROM order_items_transformed oi
JOIN products_transformed p
ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY profit DESC;

-- done






