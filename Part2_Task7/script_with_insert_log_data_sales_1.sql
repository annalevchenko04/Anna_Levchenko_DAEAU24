CREATE OR REPLACE PROCEDURE bl_cl.load_transactions_sales_data_1()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
    v_rows_affected INT := 0;  -- Initialize a counter for rows affected
BEGIN
    -- Log the start of the procedure
    PERFORM BL_CL.insert_log('load_transactions_sales_data_1', 0, 'START', 'Procedure execution started.');
    
    -- Loop through the source data and insert into the destination table
    FOR rec IN 
        SELECT DISTINCT ON (t.transactionid)
            t.transactionid AS Transaction_SRC_ID,
            t.date::DATE AS Transaction_DT,
            t.selling_price::FLOAT AS Transaction_Price,
            v.Vehicle_ID AS VIN_FK,  
            COALESCE(c.Customer_ID, -1) AS Customer_ID_FK,
            -1 AS Payment_Method_ID_FK, -- Default unknown Payment Method
            COALESCE(l.Location_ID, -1) AS Location_ID_FK,
            e.Employee_ID AS Employee_ID_FK,
            ch.Sales_channel_ID AS Channel_ID_FK,
            'SALES_DATA_1' AS SOURCE_System,
            'SRC_SALES_1' AS SOURCE_Entity,
            '1' AS SOURCE_ID
        FROM sa_v_sales_data_wa.src_sales_wa t
        JOIN BL_3NF.CE_VEHICLES v 
            ON v.VIN_SRC_ID = t.vin 
            AND v.SOURCE_System = 'SALES_DATA_1' 
            AND v.SOURCE_Entity = 'SRC_SALES_1'
        LEFT JOIN BL_3NF.CE_CUSTOMERS c 
            ON c.customer_passport = t.customer_passport
            AND c.customer_name = t.customer_name
            AND c.customer_gender = t.gender
            AND c.SOURCE_System = 'SALES_DATA_1'
            AND c.SOURCE_Entity = 'SRC_SALES_1'
        LEFT JOIN BL_3NF.CE_LOCATIONS l 
            ON l.Location_Postal_Code_SRC_ID = CAST(t.postal_code AS INTEGER)
            AND l.City_ID_FK = (
                SELECT c.City_ID 
                FROM BL_3NF.CE_CITIES c 
                WHERE c.City_SRC_ID = t.city
                AND c.SOURCE_System = 'SALES_DATA_1' 
                LIMIT 1
            )
            AND l.SOURCE_System = 'SALES_DATA_1'
            AND l.SOURCE_Entity = 'SRC_SALES_1'
        LEFT JOIN BL_3NF.CE_EMPLOYEES_SCD e 
            ON e.Employee_SRC_ID = t.employee_id
            AND e.SOURCE_System = 'SALES_DATA_1'
            AND e.SOURCE_Entity = 'SRC_SALES_1'
        LEFT JOIN BL_3NF.CE_SALES_CHANNELS ch 
            ON ch.channel_src_id = t.channel_id
            AND ch.SOURCE_System = 'SALES_DATA_1'
            AND ch.SOURCE_Entity = 'SRC_SALES_1'
        WHERE t.transactionid IS NOT NULL  
            AND NOT EXISTS (
                SELECT 1 
                FROM BL_3NF.CE_TRANSACTIONS tran 
                WHERE tran.Transaction_SRC_ID = t.transactionid
            )
    LOOP
        BEGIN
            -- Insert each record into the target table
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

            -- Increment the row count for each successful insert
            v_rows_affected := v_rows_affected + 1;

        EXCEPTION WHEN OTHERS THEN
            -- In case of an error, log it and continue with the next record
            RAISE NOTICE 'Error inserting transaction %: %', rec.Transaction_SRC_ID, SQLERRM;
            -- Log the error with affected rows as 0 for that record
            PERFORM BL_CL.insert_log('load_transactions_sales_data_1', 0, 'ERROR', 'Error inserting transaction ' || rec.Transaction_SRC_ID || ': ' || SQLERRM);
        END;
    END LOOP;

    -- Log the end of the procedure with the number of rows affected
    PERFORM BL_CL.insert_log('load_transactions_sales_data_1', v_rows_affected, 'SUCCESS', 'Procedure execution completed. Rows affected: ' || v_rows_affected);

    COMMIT;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_transactions_sales_data_1()
    OWNER TO postgres;
