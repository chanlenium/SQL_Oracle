/*QUESTION 1
Display the (1) employee_id,
            (2) First name Last name (as one name with a space between) and call the column Employee Name, 
            (3) hire_date
Only show employees with hire dates in July 2016 to December of 2016.  You cannot use >= or similar signs
Sort the output by top last hire_date first (December) and then by last name.
*/
SELECT e.employee_id, 
       e.first_name ||' '|| e.last_name AS "Employee Name", 
       e.hire_date
FROM employees e
WHERE e.hire_date BETWEEN DATE '2016-07-01' AND DATE '2016-12-31'
ORDER BY e.hire_date;


/*QUESTION 2
Write a query to display the tomorrow¡¯s date. 
The result will depend on the day when you RUN/EXECUTE this query.  
Label the column ¡°Next Day¡± */
SELECT sysdate + 1 AS "Next Day"
FROM dual;


/*QUESTION 3
Users will often use the name they are accustomed to using. 
You need to figure out what it is really called for the SQL to work.

Show the following: product ID, product name, list price (means selling price) , and the new list price increased by 2%.
(a) Display a new list price (selling price) as a whole number.
(b) show only product numbers greater than 50000 and less than 60000
(c) product names that start with G or AS*/
SELECT p.prod_no AS "product ID", 
       p.prod_name AS "product name",
       p.prod_cost AS "list price", 
       p.prod_cost*1.02 AS "new list price"
FROM products p
WHERE (p.prod_no > 50000 AND p.prod_no < 60000)
AND (p.prod_name like 'G%' OR p.prod_name like 'AS%');


/*QUESTION 5
Display the job titles (job_id) and full names of employees whose first name contains an ¡®e¡¯ or ¡®E¡¯  anywhere, 
and also contains an 'a' or a 'g' anywhere.*/
SELECT e.job_id, 
       e.first_name||' '||e.last_name AS "Full name"
FROM employees e
WHERE e.first_name LIKE '%e%' 
   OR e.first_name LIKE '%E%' 
   OR e.first_name LIKE '%a%' 
   OR e.first_name LIKE '%g%';


/*QUESTION 6
For employees whose manager ID is 124, 
write a query that displays the employee¡¯s Full Name and Job ID in the following format:
SUMMER, PAYNE is a Public Accountant.*/
SELECT e.first_name || ', ' || e.last_name || ' is a ' || e.job_id
FROM employees e
WHERE e.manager_id = 124;


/*QUESTION 7
For each employee hired before October 2016, display 
(a) the employee¡¯s last name, 
(b) hire date and 
(c) calculate the number of YEARS between TODAY and the date the employee was hired.
The output for column (c) should be to only 1 decimal place.
Put the output in order by column (c) 
Since there are 54 rows, this time only copy the  the first 10 to 12 rows of output.*/
SELECT e.last_name, 
       e.hire_date, 
       FLOOR((sysdate - e.hire_date)/365) AS "Number of YEARS"
FROM employees e
WHERE e.hire_date < DATE '2016-10-01'
ORDER BY FLOOR((CURRENT_DATE - e.hire_date)/365);


/*QUESTION 8
Display each employee¡¯s last name, hire date, and the review date, 
which is the first Tuesday after a year of service, but only for those hired after 2016. 
(1) Label the column REVIEW DAY.
(2) Format the dates to appear in the format like:
    TUESDAY, August the Thirty-First of year 2016
Sort by review date*/
SELECT e.last_name,  
       e.hire_date, 
       TO_CHAR(NEXT_DAY(add_months(e.hire_date, 12), 'Tuesday'), 'DAY, Month "the " fmDdspth "of year " YYYY') AS "REVIEW DAY"
FROM employees e
WHERE e.hire_date >= DATE '2016-10-01'
ORDER BY NEXT_DAY(add_months(e.hire_date, 12), 'Tuesday');