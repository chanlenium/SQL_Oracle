/*QUESTION 1
The user is looking for the country code and country name. 
Prompt for a country name. 
The user is only going to type in part of the country name or all of it. 
Assume you will test it with the letter g in lowercase */
SELECT c.country_id, c.country_name
FROM countries c
WHERE LOWER(c.country_name) like '&EnterLetter%';



/* QUESTION 2
The answer requires the number of rows only ... not the code
Display cities in the locations table that is a city where no customers are in them. 
(use set operators to answer this question)
Make it ordered by city name from A to Z

You do not have to do this next part, but how would you verify it worked with SQL.
Perhaps like this ....

select distinct city
from customers
order by 1      and check if Bombay or Beijing is a city in the customer table.*/
SELECT l.city 
FROM locations l
MINUS
SELECT c.city
FROM customers c
ORDER BY 1;



/* QUESTION 3
Again using SET
Display the product type, and the number of products  
In your result, display first display Sleeping Bags, followed by Tents, followed by Sunblock */
SELECT p.prod_type, COUNT(prod_type)
FROM products p
WHERE p.prod_type IN ('Sleeping Bags', 'Tents', 'Sunblock')
GROUP BY p.prod_type;


/* QUESTION 4
Show the result of the UNION of employee_id and job_id for tables EMPLOYEES and JOB_HISTORY */
SELECT employee_id, job_id
FROM employees
UNION
SELECT employee_id, job_id
FROM job_history;
