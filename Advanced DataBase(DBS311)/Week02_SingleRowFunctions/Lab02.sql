/* QUESTION 1
For each job title, display the job title and the number of employees with that same title. 
Change the job_title column to your last name
NOTE:  You need both the SQL code and the output to receive any marks */
SELECT e.job_id AS oh, 
       COUNT(*)
FROM employees e
GROUP BY e.job_id;


/* QUESTION 2
Display the Highest, Lowest and Average salary.  
Add a column that shows the difference between the highest and lowest salaries. 
Make sure the output looks meaningful to the user. 
EXAMPLE: Money should not be to 7 decimal places 
NOTE: DO NOT USE ALIAS COLUMN NAMES. */
SELECT MAX(e.salary) AS HighestSalary, 
       MIN(e.salary) AS LowestSalary, 
       ROUND(AVG(e.salary), 7) AS AverageSalary, 
       MAX(e.salary)-MIN(e.salary) AS Diff_btw_max_min
FROM employees e;


/* QUESTION 3
Display the customer name and the total amount the customer has ordered. 
But only show those customers where the total exceeds 50,000 */
SELECT c.cname, 
       o.order_no, 
       SUM(ol.price * ol.qty * (1-disc_perc/100)) AS "TOTAL AMOUNT"
FROM customers c
INNER JOIN orders o
ON c.cust_no = o.cust_no
INNER JOIN orderlines ol
ON o.order_no = ol.order_no
GROUP BY c.cname, o.order_no
HAVING SUM(ol.price * ol.qty * (1-disc_perc/100)) > 50000;


/* QUESTION 4
Display the product type name and the total dollar sales for that product type 
based on sales_2016 ans sales for 2015. 
Order by product type */
SELECT p.prod_type, 
       SUM(p.sales_2016 + p.sales_2015) AS "TOTAL SALES"
FROM products p
GROUP BY p.prod_type
ORDER BY p.prod_type;


/* QUESTION 5
For each customer display the name and the number of orders issued by the customer. 
However, only show those customers beginning with an A. or a G   
-- If the customer does not have any orders, the result will display 0.
Put in customer name order */
SELECT c.cname, 
       COUNT(NVL(o.order_no, 0))
FROM customers c
LEFT JOIN orders o
ON c.cust_no = o.cust_no
GROUP BY c.cname
HAVING c.cname LIKE 'A%' or c.cname LIKE 'G%';


/* QUESTION 6
Write a SQL query to show 
(a) cust_no, 
(b) cname 
(c) the total dollar sales (price * qty) and the total number of orders
Put the output in order by -- the number of orders
Output will look similar to this row
1040 Vacation Central 2                       7948               5
*/
SELECT c.cust_no, 
       c.cname, 
       SUM(ol.price*ol.qty) AS "TOTAL DOLLOR SALES", 
       COUNT(o.order_no) "TOTAL NUM OF ORDERS"
FROM customers c
INNER JOIN orders o
ON c.cust_no = o.cust_no
INNER JOIN orderlines ol
ON o.order_no = ol.order_no
GROUP BY c.cust_no, c.cname
ORDER BY COUNT(o.order_no);


/* QUESTION 7
We are going to make the previous questions a little harder.
The user wanted it for customer names starting with A. 
However, they wanted ALL customer s even if they have not ordered anything. 
Put output in order of column 4 */
SELECT c.cust_no, 
       c.cname, 
       NVL(SUM(ol.price*ol.qty),0) "TOTAL DOLLOR SALES", 
       COUNT(o.order_no) "TOTAL NUM OF ORDERS"
FROM customers c
LEFT JOIN orders o
ON c.cust_no = o.cust_no
LEFT JOIN orderlines ol
ON o.order_no = ol.order_no
GROUP BY c.cust_no, c.cname
HAVING c.cname LIKE 'A%'
ORDER BY COUNT(o.order_no);
