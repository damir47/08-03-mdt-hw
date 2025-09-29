# Задание 1
SELECT DISTINCT c.city
FROM city c
WHERE c.city RLIKE '^K[a-zA-Z0-9]+a$';

# Задание 2
SELECT p.payment_date, p.amount 
FROM payment p
WHERE (p.payment_date BETWEEN '2005-06-15' AND '2005-06-18') AND p.amount > '10.00';

# Задание 3
SELECT r.rental_date, r.return_date 
FROM rental r 
WHERE r.return_date IS NOT NULL
ORDER BY r.rental_date DESC
LIMIT 5;

# Задание 4
SELECT LOWER(REGEXP_REPLACE(c.first_name, 'll', 'pp')), c.last_name 
FROM customer c 
WHERE c.first_name IN ('Kelly', 'Willie');

# Задание 5
SELECT
SUBSTR(c.email, 1, POSITION('@' IN c.email) - 1) AS email_name,
SUBSTR(c.email, POSITION('@' IN c.email) + 1) AS email_domain
FROM
customer c;


# Задание 6
SELECT 
CONCAT(UPPER(SUBSTRING(SUBSTR(c.email, 1, POSITION('@' IN c.email) - 1), 1, 1)), LOWER(SUBSTRING(SUBSTR(c.email, 1, POSITION('@' IN c.email) - 1), 2))) AS email_name,
CONCAT(UPPER(SUBSTRING(SUBSTR(c.email, POSITION('@' IN c.email) + 1), 1, 1)), LOWER(SUBSTRING(SUBSTR(c.email, POSITION('@' IN c.email) + 1), 2)))  AS email_domain
FROM 
customer c;