-- ***********************
-- Name: Dongchan Oh
-- Student ID: 128975190
-- Date: 2020/11/07
-- Purpose: Lab 5 DBS311
-- ***********************

SET SERVEROUTPUT ON 

-- Question 1 - Write a stored procedure that get an integer number and prints
-- Q1 SOLUTION ?
CREATE OR REPLACE PROCEDURE evenodd(inputValue in number) as
BEGIN 
    IF mod(inputValue, 2) = 0
    THEN dbms_output.put_line('The number is even.');
    ELSE dbms_output.put_line('The number is odd!');
    END IF;
EXCEPTION
WHEN OTHERS
THEN dbms_output.put_line('Error!');
END evenodd;
--BEGIN
--evenodd(&input);  -- asks for input from user
--END;


-- Question 2 - Create a stored procedure named find_employee. This procedure gets an employee number and prints the following employee information:
-- First name, Last name, Email, Phone, Hire date, Job title
-- Q2 SOLUTION ?
CREATE OR REPLACE PROCEDURE find_employee(employeeID in number) as
--DECLARE  -- define variables
  firstName VARCHAR2(20 BYTE);
  lastName VARCHAR2(25 BYTE);
  email VARCHAR2(25 BYTE);
  phoneNo VARCHAR2(20 BYTE);
  hireDate DATE;
  jobTitle VARCHAR2(10 BYTE);
BEGIN
    SELECT first_name, last_name, email, phone_number, hire_date, job_id
    INTO firstName, lastName, email, phoneNo, hireDate, jobTitle
    FROM employees
    WHERE employee_id = employeeID;
IF  SQL%ROWCOUNT = 0
    THEN 
        dbms_output.put_line('Employee with ID ' || employeeId || ' does not exist');
ELSIF SQL%ROWCOUNT = 1 
    THEN
   		dbms_output.put_line('First name: ' || firstName);
        dbms_output.put_line('Last name: ' || lastName);
        dbms_output.put_line('Email: ' || email);
        dbms_output.put_line('Phone: ' || PhoneNo);
        dbms_output.put_line('Hire date: ' || hireDate);
        dbms_output.put_line('Job title: ' || jobTitle);
ELSE
    DBMS_OUTPUT.PUT_LINE ('More than one employee with employeeId!');
END IF;
EXCEPTION
WHEN OTHERS
  THEN 
      DBMS_OUTPUT.PUT_LINE ('Error!');
END find_employee;
--BEGIN
--find_employee(107);  -- asks for input from user
--END;



-- Question 3 -	Every year, the company increases the price of all products in one product type. 
-- Write a procedure named "update_price_tents" to update the price of all products in a given type 
-- and the given amount to be added to the current selling price if the price is greater than 0. 
-- The procedure shows the number of updated rows if the update is successful.
-- Q3 SOLUTION ?
CREATE OR REPLACE PROCEDURE update_price_tents(prod_type products.prod_type%type) as  
    amount 	products.prod_cost%type;
    productName products.prod_name%type;
    Rows_updated NUMBER;
CURSOR cursor IS
    SELECT prod_name, prod_cost+5 INTO productName, amount
    FROM products
    WHERE (prod_cost > 0) AND (prod_type LIKE 'Tents');
BEGIN
    OPEN cursor;
    LOOP
        FETCH cursor INTO productName, amount;
        Rows_updated := Rows_updated + SQL%rowcount;
        EXIT WHEN cursor%notfound;  
        dbms_output.put_line(productName || '   ' || amount);  
    END LOOP;
    Rows_updated := cursor%ROWCOUNT;
    dbms_output.put_line('The number of updated row(s) : ' || Rows_updated);
EXCEPTION
WHEN NO_DATA_FOUND
    THEN 
        dbms_output.put_line('No Data Found!');
WHEN OTHERS
    THEN 
        dbms_output.put_line('Error!');
END update_price_tents;
--BEGIN
--update_price_tents('Tents');  -- asks for input from user
--END;
ROLLBACK;



-- Question 4 -	Every year, the company increases the price of products by 1 or 2% (Example of 2% -- prod_sell * 1.02) 
-- based on if the selling price (prod_sell) is less than the average price of all products. 
-- Q4 SOLUTION ?
CREATE OR REPLACE PROCEDURE update_low_prices_128975190 as
    avgSellPrice products.prod_sell%type;  
    updatePrice products.prod_sell%type;
    productName products.prod_name%type;
    Rows_updated NUMBER;
CURSOR cursor IS
    SELECT prod_name,
        CASE WHEN avgSellPrice <= 1000 
             THEN
                CASE WHEN prod_sell < avgSellPrice THEN prod_sell * 1.01 ELSE prod_sell * 1.02 END
             ELSE
                CASE WHEN prod_sell < avgSellPrice THEN prod_sell * 1.02 ELSE prod_sell * 1.01 END
        END
    INTO productName, updatePrice
    FROM products;
BEGIN
    dbms_output.put_line('*** OUTPUT update_low_prices_128975190  STARTED ***');
    SELECT avg(prod_sell) INTO avgSellPrice FROM products;
    OPEN cursor;
    LOOP
        FETCH cursor INTO productName, updatePrice;
        Rows_updated := Rows_updated + 1;
        EXIT WHEN cursor%notfound;   
        --dbms_output.put_line(productName || ' ' || updatePrice);
    END LOOP;
    Rows_updated := cursor%ROWCOUNT;
    dbms_output.put_line('Number of updates: ' || Rows_updated);
    dbms_output.put_line('----ENDED --------');
EXCEPTION
WHEN NO_DATA_FOUND
    THEN 
        dbms_output.put_line('No Data Found!');
WHEN OTHERS
    THEN 
        dbms_output.put_line('Error!');
END update_low_prices_128975190;
--BEGIN
--update_low_prices_128975190();
--END;
ROLLBACK;



-- Question 5 -	The company needs a report that shows three categories of products based their prices. 
-- The company needs to know if the product price is cheap, fair, or expensive. 
-- Q1 SOLUTION ?
CREATE OR REPLACE PROCEDURE price_report_128975190 as
    avg_price products.prod_sell%type; 
    min_price products.prod_sell%type; 
    max_price products.prod_sell%type; 
    low_count NUMBER;
    fair_count NUMBER;
    high_count NUMBER;
BEGIN
    SELECT 
        AVG(prod_cost), MIN(prod_cost), MAX(prod_cost)
        INTO avg_price, min_price, max_price
    FROM products;
    
    SELECT 
        COUNT(CASE WHEN prod_cost < (avg_price - min_price)/2 THEN 1 END) as low_count,
        COUNT(CASE WHEN prod_cost > (max_price - avg_price)/2 THEN 1 END) as high_count,
        COUNT(CASE WHEN prod_cost > (avg_price - min_price)/2 AND 
                        prod_cost < (max_price - avg_price)/2 THEN 1 END)
    INTO low_count, high_count, fair_count
    FROM products;  
    dbms_output.put_line('Low:  ' || low_count);
    dbms_output.put_line('Fair: ' || fair_count);
    dbms_output.put_line('High: ' || high_count);
END;
--BEGIN
--price_report_128975190();
--END;
ROLLBACK;