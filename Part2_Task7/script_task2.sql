CREATE TABLE IF NOT EXISTS BL_CL.PROCEDURE_LOGS (
    Log_ID SERIAL PRIMARY KEY,
    Log_Timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Time of log entry
    Procedure_Name VARCHAR(100),  -- Name of the procedure
    Rows_Affected INT,  -- Number of rows processed
    Status VARCHAR(20),  -- 'SUCCESS' or 'ERROR'
    Message TEXT  
);

CREATE OR REPLACE FUNCTION BL_CL.insert_log(
    Procedure_Name TEXT,           -- Name of the procedure being logged
    Rows_Affected INT,             -- Number of rows affected
    Status VARCHAR(20),            -- Status ('SUCCESS' or 'ERROR')
    Message TEXT                   -- Log message (e.g., 'Procedure started' or error message)
)
RETURNS VOID AS
$BODY$
BEGIN
    INSERT INTO BL_CL.PROCEDURE_LOGS (
        Procedure_Name, 
        Rows_Affected, 
        Status, 
        Message
    ) 
    VALUES (
        Procedure_Name, 
        Rows_Affected, 
        Status, 
        Message
    );
END;
$BODY$
LANGUAGE plpgsql;

--1st attempt
CALL BL_CL.load_transactions_sales_data_1();

SELECT * FROM BL_CL.PROCEDURE_LOGS 
WHERE Procedure_Name = 'load_transactions_sales_data_1'
ORDER BY Log_Timestamp DESC;


-- 0 because I alredy have data in ce_transactions, that's why perform delete 
DELETE FROM bl_3nf.ce_transactions;

-- 2nd attempt: 500461 rows from sales_data_1

CALL BL_CL.load_transactions_sales_data_1();

SELECT * FROM BL_CL.PROCEDURE_LOGS 
WHERE Procedure_Name = 'load_transactions_sales_data_1'
ORDER BY Log_Timestamp DESC;

-- 3rd attempt: rows_affected value is 0, which is correct
CALL BL_CL.load_transactions_sales_data_1();

SELECT * FROM BL_CL.PROCEDURE_LOGS 
WHERE Procedure_Name = 'load_transactions_sales_data_1'
ORDER BY Log_Timestamp DESC;


-- now the same with sales_data_2
-- 1st attemt: 384583 new rows to transactions_ce

CALL BL_CL.load_transactions_sales_data_2();
SELECT * 
FROM BL_CL.PROCEDURE_LOGS

-- 2nd attempt: 0 rows, which is correct

CALL BL_CL.load_transactions_sales_data_2();
SELECT * 
FROM BL_CL.PROCEDURE_LOGS




