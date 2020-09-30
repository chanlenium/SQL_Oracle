/*QUESTION 1
No alias column names needed
You may need to do these 2 things each time you log in, so that the output look a little better
SET PAGESIZE 200
SET LINESIZE 100
Write a SQL query to display the last name and hire date of all employees who were hired before the employee with ID 107 got hired. 
Sort the result by the hire date with the employee that was there the longest going first on list.*/
--SET PAGESIZE 200
--SET LINESIZE 100
SELECT c.last_name, 
       c.hire_date
FROM employees c
WHERE c.hire_date < (
    SELECT hire_date
    FROM employees
    WHERE employee_id = 107);



/*QUESTION 2
Write a SQL query to display last name and salary those employees with the lowest salry 
Sort the result by name.*/
SELECT e.last_name, 
       e.salary
FROM employees e
WHERE e.salary = (
    SELECT MIN(salary)
    FROM employees)
ORDER BY 1;



/*QUESTION 3
Write a SQL query to display the 
(1)product number, 
(2)product name, 
(3)product type and 
(4)sell price of the highest paid product(s) in each product type.  
Sort by product type.*/
SELECT p.prod_no, 
       p.prod_name, 
       p.prod_type, 
       p.prod_cost
FROM products p
WHERE (p.prod_type, p.prod_cost) IN (
    SELECT prod_type, MAX(prod_cost)
    FROM products
    GROUP BY prod_type
)
ORDER BY p.prod_type;



/*QUESTION 4
Write a SQL query to display the 
(1) product line, and
(2) product sell price of the most expensive (highest sell price) product(s). 
There may be more than 1 result.*/
SELECT p.prod_line, 
       p.prod_name, 
       p.prod_cost
FROM products p
WHERE (p.prod_line, p.prod_cost) IN (
    SELECT prod_line, MAX(prod_cost)
    FROM products
    GROUP BY prod_line);



/*QUESTION 5
Write a SQL query to display 
(1)product name
(2)list price for products in category 1 which have the list price less than the lowest list price in ANY category.  
Sort the output by top list prices first and then by the product name.*/
SELECT p.prod_name, 
       p.prod_cost
FROM products p
WHERE p.prod_cost <ANY (
    SELECT MIN(prod_cost)
    FROM products
    GROUP BY prod_type
)
ORDER BY p.prod_cost, p.prod_name;



/*QUESTION 6
NOTE -- new wording
Display (1)product number, 
        (2)product name, 
        (3)product type for products that are in the same product type as the product with the lowest price */
SELECT p.prod_no, 
       p.prod_name, 
       p.prod_type
FROM products p
WHERE prod_cost = (
    SELECT MIN(prod_cost)
    FROM products);



/*QUESTION 7
Write a query to display the tomorrow¡¯s date in the following format:
September 28th of year 2006  <-- this is the format for the date you display.
Your result will depend on the day when you create this query.
     Label the column     Next Day */
SELECT INITCAP(TO_CHAR(SYSDATE+1, 'Month DDth'))||' of year '||TO_CHAR(SYSDATE+1, 'YYYY') AS "Next Day"
FROM DUAL;



/* QUESTION 8
Create a query that displays the 
(a) city names, 
(b) country codes or ID and 
(c) state/province names, 
but only for those cities that start with a lower case S and have at least 8 characters in their name. 
If city does not have a state name assigned, then put State Missing as your output on that row.*/
SELECT l.city, 
       l.country_id, 
       NVL(l.state_province, 'State Missing')
FROM locations l
WHERE l.city IN (
    SELECT city
    FROM locations
    WHERE city LIKE 's%' AND LENGTH(city) >= 8
);