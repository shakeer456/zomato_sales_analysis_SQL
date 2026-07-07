create database zomato;

use zomato;

-- 1. Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    reg_date DATE NOT NULL
);

-- 2. Restaurants Table
CREATE TABLE restaurants (
    restaurant_id INT PRIMARY KEY,
    restaurant_name VARCHAR(150) NOT NULL,
    city VARCHAR(50) NOT NULL,
    opening_time TIME NOT NULL,
    closing_time TIME NOT NULL,
    total_opening_hours INT NOT NULL
);

-- 3. Riders Table
CREATE TABLE riders (
    rider_id INT PRIMARY KEY,
    rider_name VARCHAR(100) NOT NULL,
    signup_date DATE NOT NULL
);

-- 4. Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    order_item TEXT NOT NULL,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);

-- 5. Delivery Table
CREATE TABLE delivery (
    delivery_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    delivery_status VARCHAR(20) NOT NULL,
    delivery_time DATETIME NOT NULL,
    rider_id INT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (rider_id) REFERENCES riders(rider_id)
);
