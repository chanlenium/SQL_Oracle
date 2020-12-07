SET SERVEROUTPUT ON 

create or replace PROCEDURE find_customer (customer_id IN NUMBER, found OUT NUMBER) AS
    searched_cust_no NUMBER;
BEGIN 
    SELECT cust_no INTO searched_cust_no FROM customers WHERE cust_no = customer_id;
    IF sql%rowcount > 0 THEN found := 1;
    END IF;
EXCEPTION
    WHEN no_data_found THEN found := 0;
    WHEN OTHERS THEN dbms_output.put_line('Error!');
END find_customer;


create or replace PROCEDURE find_product (product_id IN NUMBER, price OUT products.prod_cost%TYPE) AS
BEGIN 
    SELECT prod_cost INTO price FROM products WHERE prod_no = product_id;
EXCEPTION
    WHEN no_data_found THEN price := 0;
    WHEN OTHERS THEN dbms_output.put_line('Error!');
END find_product;


create or replace PROCEDURE add_order (customer_id IN NUMBER, new_order_id OUT NUMBER) AS
BEGIN 
    SELECT MAX(order_no)+1 INTO new_order_id FROM orders;
    INSERT INTO orders (order_no, rep_no, cust_no, order_dt, status, channel)
    VALUES (new_order_id, 56, customer_id, TO_CHAR(SYSDATE, 'DD-MON-YYYY'), 'S', 'Seneca');
END add_order;


create or replace PROCEDURE add_order_item (orderId IN orderlines.order_no%type,
                                            itemId IN orderlines.line_no%type, 
                                            productId IN orderlines.prod_no%type, 
                                            quantity IN orderlines.qty%type,
                                            price IN orderlines.price%type) AS
BEGIN 
    INSERT INTO orderlines (order_no, line_no, prod_no, price, qty, disc_perc)
    VALUES (orderId, itemId, productId, price, quantity, '');
END add_order_item;