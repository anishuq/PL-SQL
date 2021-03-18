
--Q3.
SELECT 
    cm.name AS "Company Name", 
    css.current_authorized AS "Number of Authorized Shares",
    css.total_outstanding AS "Total Shares outstanding",
    round(css.total_outstanding/css.current_authorized * 100,2) AS "% of Authorized"
    FROM company cm
        INNER JOIN current_stock_stats css
        ON cm.stock_id = css.stock_id
    ORDER BY cm.name;
        
        
-- Q4.

SELECT 
    dh.first_name,
    dh.last_name,
    cm.name,
    cshs.shares,
    round(cshs.shares/css.total_outstanding * 100,2) AS "% of Outstanding",
    round(cshs.shares/css.current_authorized * 100,2) AS "% of Authorized"
    FROM direct_holder dh
        INNER JOIN current_shareholder_shares cshs
        ON dh.direct_holder_id = cshs.shareholder_id
        
        INNER JOIN current_stock_stats css
        ON cshs.stock_id = css.stock_id
    
        INNER JOIN company cm
        ON css.stock_id = cm.stock_id
        
    ORDER BY dh.last_name, dh.first_name, cm.name;
    
-- Q5

SELECT 
    owner_cm.name AS "Owner Company",
    owned_cm.name AS "Owned Company",
    cshs.shares AS "Shares held by Owner Company",
    round(cshs.shares/css.total_outstanding * 100,2) AS "% of Outstanding",
    round(cshs.shares/css.current_authorized * 100,2) AS "% of Authorized"
    FROM company owner_cm
        INNER JOIN current_shareholder_shares cshs
        ON owner_cm.company_id = cshs.shareholder_id 
        
        INNER JOIN current_stock_stats css
        ON cshs.stock_id = css.stock_id

        INNER JOIN company owned_cm
        ON owned_cm.stock_id = cshs.stock_id    
    ORDER BY owner_cm.name, owned_cm.name;
    
-- Q6.

SELECT  
        td.trade_id AS "Trade ID",
        sl.stock_symbol AS "Stock Symbol",
        cm.name AS "Company Traded",
        se.symbol AS "Stock Exchange Symbol",
        td.shares AS "Number of Shares Traded",
        td.price_total AS "Trade Price Total",
        cr.symbol AS "Currency Symbol"
        FROM trade td
            INNER JOIN stock_exchange se
            ON ((td.stock_ex_id = se.stock_ex_id) AND (td.shares > 50000))
            
            INNER JOIN company cm
            ON td.stock_id = cm.stock_id
            
            INNER JOIN stock_listing sl
            ON ( (se.stock_ex_id = sl.stock_ex_id) AND (cm.stock_id = sl.stock_id) )
            
            INNER JOIN currency cr
            ON se.currency_id = cr.currency_id
        ORDER BY td.trade_id;
    
    
-- Q7


SELECT 
    se.name AS "Stock Exchange Name",
    sl.stock_symbol AS "Stock Symbol",
    (to_char (MAX(td.transaction_time), 'dd-mm-yyyy hh:mm:ss') )
    FROM stock_listing sl
        INNER JOIN stock_exchange se
        ON sl.stock_ex_id = se.stock_ex_id
        
        LEFT JOIN trade td
        ON sl.stock_ex_id = td.stock_ex_id AND sl.stock_id = td.stock_id
    GROUP BY se.name, sl.stock_symbol 
    ORDER BY se.name, sl.stock_symbol; 
        
        
    
    
-- Q8

SELECT 
    td_outer.trade_id AS "Trade ID",
    cm_outer.name AS "Company Name",
    td_outer.shares AS "Number of Shares"
    FROM trade td_outer
        INNER JOIN company cm_outer
        ON ( (td_outer.stock_ex_id IS NOT NULL) AND (td_outer.stock_id = cm_outer.stock_id) )  
    WHERE td_outer.shares = (SELECT 
                                 MAX(td_inner.shares)
                                 FROM trade td_inner
                                 WHERE td_inner.stock_ex_id IS NOT NULL);
/*
SELECT 
    td_outer.trade_id,
    cm.name,
    td_outer.shares
    FROM trade td_outer
        INNER JOIN company cm
        ON ( (cm.stock_id IS NOT NULL) AND (td_outer.stock_id = cm.stock_id)  ) 
    WHERE td_outer.stock_ex_id IS NOT NULL AND td_outer.shares = (
                                                                    SELECT 
                                                                         MAX(td_inner.shares)
                                                                         FROM trade td_inner
                                                                         WHERE td_inner.stock_ex_id IS NOT NULL);
*/
/*                                 
SELECT * FROM trade WHERE trade.stock_ex_id IS NOT NULL;
SELECT * FROM company;
*/


-- Q9

INSERT INTO shareholder (shareholder_id, type) VALUES ((SELECT MAX(sh.shareholder_id)+1 FROM shareholder sh), 'Direct_Holder');
INSERT INTO direct_holder (direct_holder_id, first_name, last_name) VALUES ( (SELECT MAX(sh.shareholder_id) FROM shareholder sh), 'Jeff', 'Adams'  );
    
-- Q10

INSERT INTO shareholder (shareholder_id, type) VALUES ((SELECT MAX(sh.shareholder_id)+1 FROM shareholder sh), 'Company');
INSERT INTO company (company_id, name, place_id, stock_id, starting_price, currency_id) VALUES (
                                (SELECT MAX(sh.shareholder_id) FROM shareholder sh), 
                                 'Makoto Investing',
                                 (SELECT pl.place_id FROM place pl WHERE pl.city = 'Tokyo'),
                                  NULL,
                                  NULL,
                                  NULL
                                 );    
    
    
 -- Q11
 
UPDATE company 
        SET stock_id = (SELECT MAX(com_inner.stock_id)+1 FROM company com_inner),
            starting_price = 50,
            currency_id = (SELECT cur.currency_id FROM currency cur WHERE cur.name = 'Yen')
        WHERE name = 'Makoto Investing';
            

INSERT INTO shares_authorized (stock_id, time_start, time_end, authorized) VALUES 
                                ( (SELECT cm.stock_id FROM company cm WHERE cm.name = 'Makoto Investing'), 
                                    SYSDATE,
                                    NULL,
                                    100000
                                );


-- Q12

INSERT INTO stock_listing (stock_id, stock_ex_id, stock_symbol) VALUES
                           ( (SELECT cm.stock_id FROM company cm WHERE cm.name = 'Makoto Investing'),
                             (SELECT se.stock_ex_id FROM stock_exchange se WHERE se.name = 'Tokyo Stock Exchange'),
                             'TYO:8602'                                
                           ); 
    
INSERT INTO stock_price (stock_id, stock_ex_id, price, time_start, time_end) VALUES
                           ( (SELECT cm.stock_id FROM company cm WHERE cm.name = 'Makoto Investing'),
                             (SELECT se.stock_ex_id FROM stock_exchange se WHERE se.name = 'Tokyo Stock Exchange'),
                             (SELECT cm.starting_price FROM company cm WHERE cm.name = 'Makoto Investing'),
                              SYSDATE,
                              NULL
                           ); 

COMMIT;    
 
       