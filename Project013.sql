
--Q 13
--DROP SEQUENCE shareholder_id_seq;
CREATE SEQUENCE shareholder_id_seq
        INCREMENT BY 1
        START WITH  50
        NOMAXVALUE
        NOMINVALUE
        NOCYCLE
        CACHE 2;


CREATE OR REPLACE PROCEDURE INSERT_DIRECT_HOLDER
(
    p_first_name        direct_holder.first_name%TYPE,
    p_last_name         direct_holder.last_name%TYPE
)

AS
    shareholder_id_seq_start  shareholder.shareholder_id%TYPE; 
BEGIN
    INSERT INTO shareholder (shareholder_id, type) VALUES (shareholder_id_seq.NEXTVAL, 'Direct_Holder');
    INSERT INTO direct_holder (direct_holder_id, first_name, last_name) VALUES ( (SELECT MAX(sh.shareholder_id) FROM shareholder sh), p_first_name, p_last_name  );
END;
/


SET SERVEROUTPUT ON;
DECLARE
BEGIN
    INSERT_DIRECT_HOLDER('Andy','Garcia');
END;
/
-- Q 14
-- SELECT shareholder_id_seq.CURRVAL FROM dual;


CREATE OR REPLACE PROCEDURE INSERT_COMPANY
(
    p_company_name        company.name%TYPE,
    p_city                place.city%TYPE,
    p_country             place.country%TYPE
)

AS
    place_id_var          place.place_id%TYPE;  
    
BEGIN
    
    INSERT INTO shareholder (shareholder_id, type) VALUES (shareholder_id_seq.NEXTVAL, 'Company');
    
    SELECT MAX(pl.place_id) + 1 INTO place_id_var FROM place pl; 
    INSERT INTO place (place_id, city, country) VALUES ( place_id_var, p_city, p_country);  
    
    INSERT INTO company (company_id, name, place_id, stock_id, starting_price, currency_id) VALUES 
            ( shareholder_id_seq.CURRVAL, p_company_name, place_id_var, NULL, NULL, NULL);
    
    
END;
/

--COMPILE THE PROCEDURE ONCE AND RUN MANY TIMES.
SET SERVEROUTPUT ON;
DECLARE
BEGIN
    INSERT_COMPANY('Acme Looney Tunes','RunnersVille', 'Coyote Country');
END;
/

--Q 15

CREATE SEQUENCE stock_id_seq
        INCREMENT BY 1
        START WITH  50
        NOMAXVALUE
        NOMINVALUE
        NOCYCLE
        CACHE 2;

CREATE OR REPLACE PROCEDURE DECLARE_STOCK
(
     company_name_param        company.name%TYPE,
     shares_authorized_param   shares_authorized.authorized%TYPE,
     starting_price_param      company.starting_price%TYPE,
     currency_name_param       currency.name%TYPE    
)

AS
    company_id_var            company.company_id%TYPE;  
    stock_id_var              company.stock_id%TYPE;   
    currency_id_var           currency.currency_id%TYPE;    
BEGIN
    --get stock ID.
    SELECT c.stock_id INTO stock_id_var FROM company c WHERE c.name = company_name_param; 
    
    IF stock_id_var IS NOT NULL THEN 
        dbms_output.put_line('Error condition.');
        RAISE_APPLICATION_ERROR(-20001, 'Error no. -20001 as stock id is NOT NULL for ' || company_name_param || '.');
    ELSE --stock ID is NULL
        dbms_output.put_line('NOT Error condition.');
        stock_id_var := stock_id_seq.NEXTVAL;
        SELECT cur.currency_id INTO currency_id_var FROM currency cur WHERE cur.name = currency_name_param;
        SELECT c.company_id INTO company_id_var FROM company c WHERE c.name = company_name_param; 
        
        UPDATE company
            SET stock_id = stock_id_var,
                starting_price = starting_price_param,
                currency_id = currency_id_var
            WHERE company_id = company_id_var;
        
        INSERT INTO shares_authorized (stock_id, time_start, time_end, authorized)
                    VALUES(stock_id_var, SYSDATE, NULL, shares_authorized_param);
        
    END IF;
END;
/

SET SERVEROUTPUT ON;
DECLARE
BEGIN
    --This is Error!
    --DECLARE_STOCK('Google', 1000, 1000, 'Dollar');
    
    --No error
    DECLARE_STOCK('Barclays', 1234, 4321, 'Dollar');
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
            dbms_output.put_line('Stock ID Error and therefore Rolling Back.');
            ROLLBACK;
            
END;
/



