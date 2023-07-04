CREATE EXTERNAL TABLE activity5 (
  user_id INT,
  event_name VARCHAR(13),
  event_date DATE,
  country VARCHAR(20)
)
LOCATION 's3://credit-input/'
;


INSERT INTO activity5 VALUES
  (1, 'app-installed', DATE '2022-01-01', 'India'),
  (1, 'app-purchase', DATE '2022-01-02', 'India'),
  (2, 'app-installed', DATE '2022-01-01', 'USA'),
  (3, 'app-installed', DATE '2022-01-01', 'USA'),
  (3, 'app-purchase', DATE '2022-01-03', 'USA'),
  (4, 'app-installed', DATE '2022-01-03', 'India'),
  (4, 'app-purchase', DATE '2022-01-03', 'India'),
  (5, 'app-installed', DATE '2022-01-03', 'SL'),
  (5, 'app-purchase', DATE '2022-01-03', 'SL'),
  (6, 'app-installed', DATE '2022-01-04', 'Pakistan'),
  (6, 'app-purchase', DATE '2022-01-04', 'Pakistan');



-- 1. Find total active users each day.
select event_date, COUNT(DISTINCT user_id) as daily_users 
FROM activity5
group by event_date
ORDER BY event_date;

-- 2. Find total active users each week. 
SELECT WEEK(event_date) AS event_week, COUNT(DISTINCT user_id) AS weekly_users
FROM activity5
GROUP BY WEEK(event_date);

-- 3. Date wise total number of users who made the purchase same day they installed the app.
with cte as (
select user_id, event_date,
CASE WHEN COUNT(DISTINCT event_name)=2 THEN user_id ELSE NULL end as sameday_user
FROM activity5
GROUP BY user_id,event_date
)

SELECT event_date, count(sameday_user)
FROM cte
GROUP BY event_date
ORDER BY event_date;


-- 4. Percentage of Paid Users in India, USA and any other country should be tagged as others.
-- percent paid users means: (paid_users_countrywise/(total users including unpaid))
with cte1 as (
select CASE WHEN country NOT IN ('India', 'USA') THEN 'others' ELSE country END AS country,
count(DISTINCT user_id) as total_users_countrywise
FROM activity5
WHERE event_name = 'app-purchase'
GROUP BY CASE WHEN country NOT IN('India', 'USA') THEN 'others' ELSE country END
),

cte2 as (
select sum(total_users_countrywise) as total_paid_users
FROM cte1
)

SELECT cte1.Country, CAST((cte1.total_users_countrywise * 1.0 / cte2.total_paid_users * 100) as int) as percent_paid
FROM cte1 JOIN cte2 ON 1=1;
-- {Multiplying numerator with 1 is done to perform floating point division. If both numerator and denominator are integers 
--then division is also int which may result in loss of decimal position.
-- Finally, “CAST(... as INT)” casts result to integer.}

-- { Since the join condition is always true (1=1 is always true), every row in cte1 will be joined with every row in cte2, 
--regardless of any specific matching criteria.
-- It performs a cross join or Cartesian product between cte1 and cte2, thus matching every row from first table with second table.}
