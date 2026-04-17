PROJECT : Subscription and Churn Analytics 
TOOL : PostgreSQL(pgAdmin) 
AUTHOR : Akshit Thapa 

1) CREATE TABLES 

CREATE TABLE users (
user_id INT PRIMARY KEY, 
user_name VARCHAR(50),
signup_date DATE, 
city VARCHAR(50)
);


CREATE TABLE subscriptions (
subscription_id INT PRIMARY KEY, 
user_id INT, 
start_date DATE, 
end_date DATE,
monthly_fee NUMERIC(10,2)
);


2) INSERT DATA 

INSERT INTO users 
VALUES
(1, 'Rahul', '2022-01-10', 'Delhi'),
(2, 'Akshit', '2022-03-15', 'Mumbai'),
(3, 'Neha', '2022-06-20', 'Pune'),
(4, 'Aman', '2023-01-05', 'Delhi'),
(5, 'Priya', '2023-02-01', 'Bangalore'),
(6, 'Rohan', '2023-04-18', 'Mumbai'),
(7, 'Simran', '2023-05-22', 'Chennai');


INSERT INTO subscriptions
VALUES 
(1, 1, '2022-01-10', '2022-12-31', 500),
(2, 1, '2023-01-01', NULL, 600),
(3, 2, '2022-03-15', '2023-03-14', 700),
(4, 3, '2022-06-20', NULL, 400), 
(5, 4, '2023-01-05', '2023-09-30', 500), 
(6, 5, '2023-02-01', NULL, 800), 
(7, 6, '2023-04-18', '2023-12-31', 600),
(8, 7, '2023-05-22', NULL, 550);


3) ANALYSIS QUERIES 

(i) Identify Active v/s. Churned Users ?

SELECT c.user_id, c.user_name,
CASE 
WHEN p.end_date IS NULL THEN 'Active'
ELSE 'Churned'
END AS user_status 
FROM users AS c 
JOIN subscriptions AS p 
ON c.user_id = p.user_id;


(ii) Monthly Recurring Revenue(MRR), calculate total monthly recuring revenue based on active subscription ?

SELECT SUM(monthly_fee) AS total_mrr
FROM subscriptions 
WHERE end_date IS NULL;


(iii) Churn Rate = (number of churned users / total users) * 100 ?

SELECT ROUND (
(COUNT(CASE WHEN end_date IS NOT NULL THEN 1 END) :: decimal / COUNT(DISTINCT 
user_id)) * 100, 2 ) AS churn_percentage
FROM subscriptions;


(iv) Users with increasing subscription fee, find users whose latest subscription fee > previous subscription fee ?

SELECT user_id 
FROM ( 
SELECT user_id, monthly_fee, LAG(monthlly_fee)
OVER(PARTITION BY user_id
     ORDER BY start_date) AS previous_fee
FROM subscriptions
) t 
WHERE monthly_fee > previous_fee;


(v) Revenue Per City ?

SELECT u.city, SUM(s.monthly_fee) AS total_revenue
FROM users AS u
JOIN subscriptions AS s 
ON u.user_id = s.user_id
GROUP BY u.city
ORDER BY total_revenue DESC;


(vi) Longest Active Subscriber, find user with maximum subscription duration ?

SELECT user_id, (CURRENT_DATE - start_date) AS duration_days 
FROM subscriptions 
WHERE end_date IS NULL
ORDER BY duration_days DESC
LIMIT 1;


(vii) Rank users by Lifetime Revenue, calculate total revenue per user ? 

WITH revenue_calc AS ( 
SELECT user_id, SUM(
monthly_fee * EXTRACT(MONTH FROM AGE(COALESCE(end_date, CURRENT_DATE), start_date
))
)AS lifetime_revenue
FROM subscriptions
GROUP BY user_id
)
SELECT user_id, lifetime_revenue,
RANK() OVER(ORDER BY lifetime_revenue DESC) AS rank
FROM revenue_calc;


(viii) Users who reactivated after Churn, 
Users who : 1) Had a subscripiton with end_date
            2) Then started another subscription later ? 

SELECT DISTINCT s1.user_id
FROM subscriptions AS s1
JOIN subscriptions AS s2
ON s1.user_id = s2.user_id
WHERE s1.end_date IS NOT NULL
AND s2.start_date > s1.end_date;