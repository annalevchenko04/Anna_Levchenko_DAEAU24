-- DROP PROCEDURE IF EXISTS bl_cl.load_transactions_sales_data_2();

CREATE OR REPLACE PROCEDURE bl_cl.load_transactions_sales_data_2()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
    rows_affected INT := 0;  -- Variable to track the number of rows inserted
BEGIN
    -- Log the start of the procedure
    PERFORM BL_CL.insert_log('load_transactions_sales_data_2', 0, 'START', 'Procedure execution started.');

    -- Loop through the source data and insert records
    FOR rec IN 
        SELECT DISTINCT ON (t.transactionid)
            t.transactionid AS Transaction_SRC_ID,
            t.date::DATE AS Transaction_DT,
            t.selling_price::FLOAT AS Transaction_Price,
            v.Vehicle_ID AS VIN_FK,  
            COALESCE(c.Customer_ID, -1) AS Customer_ID_FK,
            pm.Payment_Method_ID AS Payment_Method_ID_FK,
            COALESCE(l.Location_ID, -1) AS Location_ID_FK,
            e.Employee_ID AS Employee_ID_FK,
            -1 AS Channel_ID_FK,
            'SALES_DATA_2' AS SOURCE_System,
            'SRC_SALES_2' AS SOURCE_Entity,
            '2' AS SOURCE_ID
        FROM sa_v_sales_data_fl.src_sales_fl t
        JOIN BL_3NF.CE_VEHICLES v 
            ON v.VIN_SRC_ID = t.vin 
            AND v.SOURCE_System = 'SALES_DATA_2' 
            AND v.SOURCE_Entity = 'SRC_SALES_2'
        LEFT JOIN BL_3NF.CE_CUSTOMERS c 
            ON c.customer_SRC_ID = CAST(t.customer_id AS INTEGER)
            AND c.SOURCE_System = 'SALES_DATA_2'
            AND c.SOURCE_Entity = 'SRC_SALES_2'
        LEFT JOIN BL_3NF.CE_PAYMENT_METHODS pm 
            ON pm.Payment_Method_Name = t.payment_method
            AND pm.SOURCE_System = 'SALES_DATA_2'
        LEFT JOIN BL_3NF.CE_LOCATIONS l 
            ON l.Location_Postal_Code_SRC_ID = CAST(t.postal_code AS INTEGER)
            AND l.City_ID_FK = (
                SELECT c.City_ID 
                FROM BL_3NF.CE_CITIES c 
                WHERE c.City_SRC_ID = t.city
                AND c.SOURCE_System = 'SALES_DATA_2' 
                LIMIT 1
            )
            AND l.SOURCE_System = 'SALES_DATA_2'
            AND l.SOURCE_Entity = 'SRC_SALES_2'
        LEFT JOIN BL_3NF.CE_EMPLOYEES_SCD e 
            ON e.Employee_SRC_ID = t.employee_id
            AND e.SOURCE_System = 'SALES_DATA_2'
            AND e.SOURCE_Entity = 'SRC_SALES_2'
        WHERE t.transactionid IS NOT NULL 
            AND t.selling_price IS NOT NULL
            AND NOT EXISTS (
                SELECT 1
                FROM BL_3NF.CE_TRANSACTIONS tran
                WHERE tran.Transaction_SRC_ID = t.transactionid
            )
    LOOP
        BEGIN
            -- Insert record into the target table
            INSERT INTO BL_3NF.CE_TRANSACTIONS (
                Transaction_SRC_ID,
                Transaction_DT,
                Transaction_Price,
                VIN_FK,
                Customer_ID_FK,
                Payment_Method_ID_FK,
                Location_ID_FK,
                Employee_ID_FK,
                Channel_ID_FK,
                SOURCE_System,
                SOURCE_Entity,
                SOURCE_ID
            ) VALUES (
                rec.Transaction_SRC_ID,
                rec.Transaction_DT,
                rec.Transaction_Price,
                rec.VIN_FK,
                rec.Customer_ID_FK,
                rec.Payment_Method_ID_FK,
                rec.Location_ID_FK,
                rec.Employee_ID_FK,
                rec.Channel_ID_FK,
                rec.SOURCE_System,
                rec.SOURCE_Entity,
                rec.SOURCE_ID
            );
            
            -- Increment the rows_affected counter
            rows_affected := rows_affected + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting transaction %: %', rec.Transaction_SRC_ID, SQLERRM;
        END;
    END LOOP;

    -- Log the procedure execution completion and number of rows affected
    IF rows_affected > 0 THEN
        PERFORM BL_CL.insert_log('load_transactions_sales_data_2', rows_affected, 'SUCCESS', 'Procedure execution completed successfully.');
    ELSE
        PERFORM BL_CL.insert_log('load_transactions_sales_data_2', rows_affected, 'SUCCESS', 'No new records to insert.');
    END IF;

    COMMIT;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_transactions_sales_data_2()
    OWNER TO postgres;
