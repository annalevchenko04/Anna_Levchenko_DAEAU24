CREATE SCHEMA IF NOT EXISTS BL_CL;

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