/********************************************************
Name: DONG CHAN OH
SenecaID: 128975190
OracleID: dbs311_203d29
Email: dcoh@myseneca.ca
*********************************************************/

/* QUESTION 1
ONLY 1 person in the group actually submits. 
The rest can do the assignment, save it and come back to it, but do NOT submit it.
GROUP MEMBERS: Please enter the (1) names, (2) student id and (3) oracle id for all members in the group
Also which Oracle ID was used to do the assignment.
REMEMBER to use Oracle IDs connected to Seneca so that I can test your code if needed.
set pagesize 200
set linesize 200
Need both the SQL and the output */
set pagesize 200
set linesize 200



/* QUESTION 2
Display the (1) customer number, 
            (2) customer name,
            (3) country code for all the customers that are in the Germany. 
Look up th country code for Germany. Table used is CUSTOMERS

Please note that the user is to enter the 2 character country code AND that 
if they were doing Canade they can enter it as  CA, Ca, ca, cA meaning any combitaion.
Your SQL must allow for various user inputs of the code. 
Do not make the user enter it the way you want such as CA only. 
Be flexible and helpful. Also do not use a lot of OR statements to get around the requirements.

NOTE: the user is not entering the country name. */
SELECT c.cust_no, 
       c.cname, 
       c.country_cd
FROM customers c
where UPPER(c.country_cd) = 'DE';



/* QUESTION 3
Remember --- need both the SQL and the output to get any marks.
MUST USE the ON style of JOIN
For any customers with customer names that include Outlet provide
(1) customer number, (2) customer name and (3) order number 
but only if they ordered any of these products -- 40301, 40303, 40300, 40310, 40306.  
Put result in order number order.  */
SELECT c.cust_no, 
       c.cname, 
       o.order_no
FROM customers c
INNER JOIN orders o
ON c.cust_no = o.cust_no
INNER JOIN orderlines ol
ON o.order_no = ol.order_no
WHERE ol.prod_no IN (40301, 40303, 40300, 40310, 40306)
AND c.cname LIKE '%Outlet%'
ORDER BY o.order_no;



/* QUESTION 4
USE the ON method of join .. Be sure to layout the SQL in a readable format
Display all orders for United Kingdom. 
The COUNTRY_NAME can be either hard coded or accepted from the user -- your choice.
BUT-- You need to have United Kingdom and not UK.  

Show only cities that start with L. 
Display the (1) customer number, 
            (2) customer name, 
            (3) order number, 
            (4) product name,?
            (5) the total dollars for that line on the order.  

Give that last column the name of Line Sales
Put the output into "customer number order" from highest to lowest. 
Display only customer numbers less than 1000  */
SELECT c.cust_no, 
       c.cname, 
       o.order_no, 
       p.prod_name, 
       ol.line_no, 
       ROUND(ol.price*ol.qty*(1-ol.disc_perc/100)) AS "Line Sales" 
FROM customers c
INNER JOIN orders o
ON c.cust_no = o.cust_no
INNER JOIN orderlines ol
ON o.order_no = ol.order_no
INNER JOIN products p
ON ol.prod_no = p.prod_no
WHERE UPPER(c.country_cd) = (
SELECT	REGEXP_REPLACE ( INITCAP ('United Kingdom'), '[^A-Z]')
FROM    dual)
AND c.cust_no < 1000 
ORDER BY c.cust_no DESC;



/* QUESTION 5
Mr. King, the top person in the company, would like to see all orders in 2014 from Germany and United Kingdom  
Show the (1) customer number, (2)customer name and (3)country name */
SELECT DISTINCT c.cust_no, 
                c.cname, 
                co.country_name
FROM customers c
INNER JOIN countries co
ON c.country_cd = co.country_id
INNER JOIN orders o
ON c.cust_no = o.cust_no
INNER JOIN orderlines ol
ON o.order_no = ol.order_no
INNER JOIN products p 
ON ol.prod_no = p.prod_no 
WHERE UPPER(c.country_cd) IN ('UK', 'DE');



/* QUESTION 6
Find the total dollar value for all orders from London customers.
Each row will show (1) customer name, (2) order number and (3) total dollars for that order.  
Sort by highest total first */
SELECT c.cname, 
       o.order_no, 
       ROUND(SUM((ol.price * ol.qty)*(1-ol.disc_perc/100)))
FROM customers c
INNER JOIN orders o
ON c.cust_no = o.cust_no
INNER JOIN orderlines ol
ON o.order_no = ol.order_no
WHERE UPPER(c.city) = 'LONDON'
GROUP BY c.cname, o.order_no;



/* QUESTION 7
For all orders in the orders table 
supply order date and count of the number of orders on that date.
Only include those dates in 2015 and 2016
also only show those with more than 1 order */
SELECT o.order_dt, 
       COUNT(o.order_no)
FROM orders o
HAVING substr(o.order_dt, -4) IN ('2015', '2016')
AND COUNT(o.order_no) > 1
GROUP BY o.order_dt;



/* QUESTION 8
Display (1) Department_id, (2) Job_id and the (3) Lowest salary 
for this combination but only if that Lowest Pay falls in the range $6000 - $18000.?? 
Exclude people who
(a) work as some kind of Representative (REP)job from this query
(b) departments IT and SALES
Sort the output according to the Department_id and then by Job_id. 
You MUST NOT use the Subquery method. */
SELECT e.department_id, 
       e.job_id, 
       MIN(e.salary) 
FROM employees e
LEFT JOIN  departments d
ON e.department_id = d.department_id
WHERE e.salary BETWEEN 6000 AND 18000
AND (e.job_id NOT LIKE '%REP'
AND d.department_name NOT IN ('IT', 'Sales'))
GROUP BY e.department_id, e.job_id
ORDER BY e.department_id, e.job_id;



/* QUESTION 9
The President wants to know out of the 150 to 155 customers that are on file, 
how many customers have not placed an order? */
SELECT count(*)
FROM customers c
LEFT JOIN orders o
ON c.cust_no = o.cust_no
WHERE o.order_no IS NULL;



/* QUESTION 10
Show what customers (1) number and 
                    (2) name along with the 
                    (3) country name for all customers that are in the same countries as customers starting with Suthe Supra customers. 
Limit the list to any customer names that starts with the letters A to E. */
SELECT c.cust_no, 
       c.cname, 
       co.country_name
FROM customers c
JOIN  countries co
ON c.country_cd = co.country_id
WHERE c.country_cd IN (
SELECT DISTINCT c.country_cd
FROM customers c
JOIN countries co
ON c.country_cd = co.country_id
WHERE c.cname LIKE 'Supra%')
AND REGEXP_LIKE(c.cname, '^[A-E]');



/* QUESTION 11
List the (1) employee number, (2) last name (3) job id and (4) the modified or not modified salary for all employees.  
Show only employees -
- If the salary without the increase is outside the range $6,000 - $11,000 and who are employed as a Vice Presidents or Managers (President is not counted here).
- You should use Wild Card characters for this.
- the modified salary for a VP will be 30% higher 
- and managers a 20% salary increase.
- Sort the output by the top salaries (before this increase). 

The output lines should look "like" this sample line:
205 Higgins              15400  */
SELECT employee_id, last_name, salary*(1.3) as "modified_salary", job_id, salary
FROM employees
WHERE ((salary < 6000) OR (salary > 11000))
AND (job_id LIKE '%VP')
UNION
SELECT employee_id, last_name, salary*(1.2) as "modified_salary", job_id, salary
FROM employees
WHERE ((salary < 6000) OR (salary > 11000))
AND (job_id LIKE '%MAN')
ORDER BY salary DESC;



/* QUESTION 12
Display (1) last_name, 
        (2) salary 
        (3) job
        for all employees who earn more than all lowest paid employees in departments outside the US locations.

Exclude President and Vice Presidents from this query.
This question may be interpreted as ALL employees in the table that are lower, OR comparing those in the US to the lowest outside the US. 
Choose whichever you want.

Sort the output by job title ascending.
You need to use a Subquery and Joining with the NEWER method. (USING/JOIN or ON)? */
--SELECT e.employee_id, e.last_name, e.department_id, e.salary, l.country_id
SELECT e.last_name, 
       e.salary, 
       e.job_id
FROM employees e
WHERE (e.job_id NOT LIKE '%PRES' AND e.job_id NOT LIKE '%VP')
AND e.salary > (
SELECT MIN(e.salary) 
FROM employees e
JOIN departments d
ON e.department_id = d.department_id
JOIN locations l
ON d.location_id = l.location_id
WHERE l.country_id NOT LIKE 'US');



/* QUESTION 13
List the manager's last name and the employees last name that works for that manager */
SELECT m.employee_id AS "MANAGER ID", 
       m.last_name AS "MANAGER NAME", 
       e.last_name AS "Employees last name"
FROM employees m
INNER JOIN employees e
ON m.employee_id = e.manager_id;