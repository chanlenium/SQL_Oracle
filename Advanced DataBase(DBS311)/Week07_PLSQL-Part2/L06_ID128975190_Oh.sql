-- ***********************
-- Name: Dongchan Oh
-- Student ID: 128975190
-- Date: 2020/11/16
-- Purpose: Lab 6 DBS311
-- ***********************

set serveroutput on

-- Question 1 ? 
-- The company wants to calculate the employees¡¯ annual salary:
-- The first year of employment, the amount of salary is the base salary which is $10,000.
-- Every year after that, the salary increases by 5%.
-- Write a stored procedure named calculate_salary which gets an employee ID and for that employee, 
-- calculates the salary based on the number of years the employee has been working in the company.

-- Q1 SOLUTION ?
CREATE OR REPLACE PROCEDURE calculate_salary(e_id employees.employee_id%type) as
    e_last_name employees.last_name%type;  
    e_first_name employees.first_name%type;  
    e_salary employees.salary%type; 
CURSOR emp_cursor IS
    SELECT 	first_name, last_name, round(10000*POWER(1.05, to_char(sysdate, 'YYYY')-to_char(hire_date, 'YYYY')), 2)
    FROM employees
    WHERE e_id = employee_id;
BEGIN
OPEN emp_cursor;
    LOOP  
        FETCH emp_cursor into e_last_name, e_first_name, e_salary;  
            EXIT WHEN emp_cursor%notfound;  
        dbms_output.put_line('First Name: ' || e_first_name);
        dbms_output.put_line('Last Name: ' || e_last_name);
        dbms_output.put_line('Salary: $' || e_salary);
    END LOOP;
    IF emp_cursor%ROWCOUNT>0 THEN
        dbms_output.put_line(emp_cursor%ROWCOUNT||' Rows Updated');
    ELSE
        dbms_output.put_line('There is no record with input employee ID');
    END IF;
EXCEPTION
WHEN NO_DATA_FOUND
    THEN 
        dbms_output.put_line('No Data Found!');
WHEN OTHERS
    THEN 
        dbms_output.put_line('Error!');
CLOSE emp_cursor;
END calculate_salary;
--BEGIN
--   calculate_salary(23);
--END;



-- Question 2 ? 
-- Write a stored procedure named employee_works_here to print the employee_id, employee Last name and department name.
--If the value of the department name is null or does not exist, display ¡°no department¡±.
--The value of employee ID ranges from your Oracle id's last 2 digits(ex: dbs311_203g37 would use 37) to employee 105
--You can use a loop to find and display the information of each employee inside the loop. (Do not use cursors.) 
CREATE OR REPLACE PROCEDURE employee_works_here as
    d_name departments.department_name%type;
    e_id employees.employee_id%type;
    e_lname employees.last_name%type;
BEGIN
    DBMS_OUTPUT.PUT_LINE ( RPAD('Employee #', 15) || RPAD('Last Name', 15) || RPAD('Department Name', 10)); 
    FOR i IN 29..105 LOOP
        BEGIN
            SELECT employee_id, last_name INTO e_id, e_lname FROM employees WHERE employee_id = i;
            BEGIN
                SELECT e.employee_id, e.last_name, d.department_name INTO e_id, e_lname, d_name FROM employees e, departments d 
                WHERE e.department_id = d.department_id AND e.employee_id = i;
                DBMS_OUTPUT.PUT_LINE (RPAD(e_id,14) || ' ' || RPAD(e_lname, 14) || ' ' || d_name);
                EXCEPTION WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE (e_id || ' ' || e_lname || ' ' || 'NO department');     
            END;
            EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
        END;        
    END LOOP;
END employee_works_here;
--BEGIN
--   employee_works_here();
--END;
