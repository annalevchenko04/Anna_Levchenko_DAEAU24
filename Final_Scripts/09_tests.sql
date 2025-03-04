
--TEST 1:

SELECT Employee_SRC_ID, START_DT, SOURCE_System, COUNT(*)
FROM BL_3NF.CE_EMPLOYEES_SCD
GROUP BY Employee_SRC_ID, START_DT, SOURCE_System
HAVING COUNT(*) > 1;

SELECT Employee_SRC_ID, START_DT, COUNT(*)
FROM BL_DM.DIM_EMPLOYEES_SCD
GROUP BY Employee_SRC_ID, START_DT
HAVING COUNT(*) > 1;

--TEST 2:

SELECT transaction_src_id
FROM BL_DM.fact_transactions t
WHERE NOT EXISTS (
    SELECT 1
    FROM sa_v_sales_data_wa.src_sales_wa s
    WHERE s.transactionid = t.transaction_src_id
)
AND NOT EXISTS (
    SELECT 1
    FROM sa_v_sales_data_fl.src_sales_fl f
    WHERE f.transactionid = t.transaction_src_id
);


--Expected Result: Both tests should return no rows. 
--1)If any rows are returned, duplicates exist, violating the uniqueness constraint.
--2)If any rows are returned, it indicates that records from the src_sales_wa 
--table or src_sales_fl table are missing in the business layer.
