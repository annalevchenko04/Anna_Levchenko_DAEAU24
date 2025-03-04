-- CREATE TABLE orders AS 
-- SELECT   id AS order_id, 
-- (id * 10 * random()*10)::int AS order_cost, 
-- 'order number ' || id AS order_num 
-- FROM generate_series(1, 1000) AS id; 
-- CREATE TABLE stores ( 
-- store_id int, 
-- store_name text, 
-- max_order_cost int 
-- ); 
-- INSERT INTO stores VALUES 
-- (1, 'grossery shop', '800'), 
-- (2, 'bakery', '100'), 
-- (3, 'manufactured goods', '3000') 
-- ; 
SELECT 
    s.store_id, 
    s.store_name, 
    o.order_id, 
    o.order_cost, 
    o.order_num 
FROM stores s  
LEFT JOIN LATERAL (
    SELECT 
        o.order_id, 
        o.order_cost, 
        o.order_num 
    FROM orders o 
    WHERE o.order_cost < s.max_order_cost 
    ORDER BY o.order_cost DESC 
    LIMIT 10
) o ON true  
ORDER BY s.store_id, o.order_cost DESC;

--Alternative way just for checking
WITH ranked_orders AS (
    SELECT 
        s.store_id, 
        s.store_name, 
        o.order_id, 
        o.order_cost, 
        o.order_num, 
        ROW_NUMBER() OVER (PARTITION BY s.store_id ORDER BY o.order_cost DESC) AS rank
    FROM stores s
    JOIN orders o ON o.order_cost < s.max_order_cost
)
SELECT store_id, store_name, order_id, order_cost, order_num
FROM ranked_orders
WHERE rank <= 10
ORDER BY store_id, order_cost DESC;

WITH RECURSIVE emp_hierarchy AS (
    -- Base case: Select the company President (Top-Level)
    SELECT 
        e.empno, 
        e.ename AS employee_name, 
        e.mgr AS manager_id, 
        NULL::VARCHAR AS manager_name, 
        1 AS level_of_management
    FROM public.emp e
    WHERE e.mgr IS NULL  -- The President (No Manager)

    UNION ALL

    -- Recursive part: Find employees reporting to the managers
    SELECT 
        e.empno, 
        e.ename AS employee_name, 
        e.mgr AS manager_id, 
        eh.employee_name AS manager_name, 
        eh.level_of_management + 1 AS level_of_management
    FROM public.emp e
    JOIN emp_hierarchy eh ON e.mgr = eh.empno
)

SELECT * FROM emp_hierarchy
ORDER BY level_of_management, manager_name, employee_name;


-- CREATE TABLE order_log (
--     log_id        SERIAL PRIMARY KEY,
--     order_id      INTEGER,
--     order_cost    INTEGER,
--     order_num     TEXT,
--     action_type   VARCHAR(1) CHECK (action_type IN ('U', 'D')), 
--     log_date      TIMESTAMPTZ DEFAULT Now()
-- );

WITH updated_orders AS (
    
    UPDATE orders
    SET order_cost = order_cost / 2
    WHERE order_cost BETWEEN 100 AND 1000
    RETURNING order_id, order_cost * 2 AS old_order_cost, order_num
),
deleted_orders AS (
    
    DELETE FROM orders
    WHERE order_cost < 50
    RETURNING order_id, order_cost, order_num
)
INSERT INTO order_log (order_id, order_cost, order_num, action_type)
SELECT order_id, old_order_cost, order_num, 'U' FROM updated_orders
UNION ALL
SELECT order_id, order_cost, order_num, 'D' FROM deleted_orders;


