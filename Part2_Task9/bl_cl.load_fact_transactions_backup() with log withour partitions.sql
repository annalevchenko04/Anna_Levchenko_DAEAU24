CREATE OR REPLACE PROCEDURE bl_cl.load_fact_transactions_backup()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_rows_affected INT := 0;  -- Initialize a counter for rows affected
    v_transaction_record RECORD;
    v_exists BOOLEAN;
BEGIN
    -- Log the start of the procedure
    PERFORM BL_CL.insert_log('load_fact_transactions', 0, 'START', 'Procedure execution started.');

    -- Loop through each record in the CE_TRANSACTIONS table
    FOR v_transaction_record IN
        SELECT 
            t.Transaction_SRC_ID,
            d.Date_ID,  -- Foreign key reference to DIM_DATES
            c.Customer_SURR_ID,  -- Foreign key reference to DIM_CUSTOMERS
            v.Vehicle_SURR_ID,  -- Foreign key reference to DIM_VEHICLES
            l.Location_SURR_ID,  -- Foreign key reference to DIM_LOCATIONS
            e.Employee_SURR_ID,  -- Foreign key reference to DIM_EMPLOYEES_SCD
            sc.Channel_SURR_ID,  -- Foreign key reference to DIM_SALES_CHANNELS
            t.payment_method_id_fk,
            pm.Payment_Method_Name,
            t.Transaction_Price,
            1 AS Transaction_Quantity,
            0 AS Transaction_Discount,
            t.SOURCE_System,
            t.SOURCE_Entity,
            t.SOURCE_ID
        FROM BL_3NF.CE_TRANSACTIONS t
        LEFT JOIN BL_DM.DIM_DATES d ON d.Date_Full = t.Transaction_DT
        LEFT JOIN BL_DM.DIM_CUSTOMERS c ON c.Customer_SRC_ID = t.Customer_ID_FK::TEXT
        LEFT JOIN BL_DM.DIM_VEHICLES v ON v.VIN_SRC_ID = t.VIN_FK::TEXT
        LEFT JOIN BL_DM.DIM_LOCATIONS l ON l.Location_Postal_Code_SRC_ID::TEXT = t.Location_ID_FK::TEXT
        LEFT JOIN BL_DM.DIM_EMPLOYEES_SCD e ON e.Employee_SRC_ID = t.Employee_ID_FK::TEXT
        LEFT JOIN BL_DM.DIM_SALES_CHANNELS sc ON sc.Channel_SRC_ID = t.Channel_ID_FK::TEXT
        LEFT JOIN BL_3NF.CE_PAYMENT_METHODS pm ON pm.Payment_Method_ID = t.payment_method_id_fk
    LOOP
        -- Check if the record already exists in the FACT_TRANSACTIONS_backup table
        SELECT EXISTS (
            SELECT 1
            FROM BL_DM.FACT_TRANSACTIONS_backup ft
            WHERE ft.Transaction_SRC_ID = v_transaction_record.Transaction_SRC_ID
              AND ft.Customer_SURR_ID_FK = v_transaction_record.Customer_SURR_ID
              AND ft.Vehicle_SURR_ID_FK = v_transaction_record.Vehicle_SURR_ID
              AND ft.Location_SURR_ID_FK = v_transaction_record.Location_SURR_ID
              AND ft.Employee_SURR_ID_FK = v_transaction_record.Employee_SURR_ID
              AND ft.Channel_SURR_ID_FK = v_transaction_record.Channel_SURR_ID
              AND ft.SOURCE_System = v_transaction_record.SOURCE_System
        ) INTO v_exists;

        IF v_exists THEN
            -- Check if any columns need updating
            IF EXISTS (
                SELECT 1
                FROM BL_DM.FACT_TRANSACTIONS_backup ft
                WHERE ft.Transaction_SRC_ID = v_transaction_record.Transaction_SRC_ID
                  AND ft.Customer_SURR_ID_FK = v_transaction_record.Customer_SURR_ID
                  AND ft.Vehicle_SURR_ID_FK = v_transaction_record.Vehicle_SURR_ID
                  AND ft.Location_SURR_ID_FK = v_transaction_record.Location_SURR_ID
                  AND ft.Employee_SURR_ID_FK = v_transaction_record.Employee_SURR_ID
                  AND ft.Channel_SURR_ID_FK = v_transaction_record.Channel_SURR_ID
                  AND ft.SOURCE_System = v_transaction_record.SOURCE_System
                  AND (ft.Transaction_Payment_Method_ID <> v_transaction_record.payment_method_id_fk
                    OR ft.Transaction_Payment_Method_Name <> v_transaction_record.Payment_Method_Name
                    OR ft.Transaction_Amount <> v_transaction_record.Transaction_Price
                    OR ft.Transaction_Quantity <> 1
                    OR ft.Transaction_Discount <> 0
                    OR ft.SOURCE_Entity <> v_transaction_record.SOURCE_Entity
                    OR ft.SOURCE_ID <> v_transaction_record.SOURCE_ID)
            ) THEN
                -- Perform the update only if there are differences
                UPDATE BL_DM.FACT_TRANSACTIONS_backup
                SET 
                    Transaction_Payment_Method_ID = v_transaction_record.payment_method_id_fk,
                    Transaction_Payment_Method_Name = v_transaction_record.Payment_Method_Name,
                    Transaction_Amount = v_transaction_record.Transaction_Price,
                    Transaction_Quantity = 1,
                    Transaction_Discount = 0,
                    SOURCE_Entity = v_transaction_record.SOURCE_Entity,
                    SOURCE_ID = v_transaction_record.SOURCE_ID,
                    TA_UPDATE_DT = CURRENT_TIMESTAMP  -- Update the timestamp
                WHERE Transaction_SRC_ID = v_transaction_record.Transaction_SRC_ID
                  AND Customer_SURR_ID_FK = v_transaction_record.Customer_SURR_ID
                  AND Vehicle_SURR_ID_FK = v_transaction_record.Vehicle_SURR_ID
                  AND Location_SURR_ID_FK = v_transaction_record.Location_SURR_ID
                  AND Employee_SURR_ID_FK = v_transaction_record.Employee_SURR_ID
                  AND Channel_SURR_ID_FK = v_transaction_record.Channel_SURR_ID
                  AND SOURCE_System = v_transaction_record.SOURCE_System;
                
                -- Increment affected rows for update
                v_rows_affected := v_rows_affected + 1;
            END IF;
        ELSE
            -- Record does not exist, perform the insert
            INSERT INTO BL_DM.FACT_TRANSACTIONS_backup (
                Transaction_SRC_ID,
                Event_DT_FK,
                Customer_SURR_ID_FK,
                Vehicle_SURR_ID_FK,
                Location_SURR_ID_FK,
                Employee_SURR_ID_FK,
                Channel_SURR_ID_FK,
                Transaction_Payment_Method_ID,
                Transaction_Payment_Method_Name,
                Transaction_Amount,
                Transaction_Quantity,
                Transaction_Discount,
                SOURCE_System,
                SOURCE_Entity,
                SOURCE_ID
            )
            VALUES (
                v_transaction_record.Transaction_SRC_ID,
                v_transaction_record.Date_ID,
                v_transaction_record.Customer_SURR_ID,
                v_transaction_record.Vehicle_SURR_ID,
                v_transaction_record.Location_SURR_ID,
                v_transaction_record.Employee_SURR_ID,
                v_transaction_record.Channel_SURR_ID,
                v_transaction_record.payment_method_id_fk,
                v_transaction_record.Payment_Method_Name,
                v_transaction_record.Transaction_Price,
                1,
                0,
                v_transaction_record.SOURCE_System,
                v_transaction_record.SOURCE_Entity,
                v_transaction_record.SOURCE_ID
            );

            -- Increment affected rows for insert
            v_rows_affected := v_rows_affected + 1;
        END IF;
    END LOOP;

    -- Log the successful completion of the procedure
    PERFORM BL_CL.insert_log('load_fact_transactions', v_rows_affected, 'SUCCESS', 'Procedure execution completed. Rows affected: ' || v_rows_affected);

EXCEPTION WHEN OTHERS THEN
    -- Log the error with affected rows as 0
    PERFORM BL_CL.insert_log('load_fact_transactions', 0, 'ERROR', 'Error during procedure execution: ' || SQLERRM);
    -- Rollback the transaction in case of error
    ROLLBACK;
    RAISE NOTICE 'Error occurred, transaction rolled back: %', SQLERRM;
    -- Exit the procedure
    RETURN;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_fact_transactions_backup()
    OWNER TO postgres;
