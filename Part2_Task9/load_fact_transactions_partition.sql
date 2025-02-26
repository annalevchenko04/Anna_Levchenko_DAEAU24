// It takes 4 minutes to execute

CREATE OR REPLACE PROCEDURE bl_cl.load_fact_transactions()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
    v_date_iter DATE; 
    v_partition_suffix TEXT;
    v_partition_start_id INT;
    v_partition_next_id INT;
    v_date_start DATE;
    v_date_end DATE;
    v_date_next DATE;
BEGIN
    -- Define the rolling window dates
    SELECT date_trunc('month', MIN(Date_Full))
    INTO v_date_start
    FROM BL_DM.DIM_DATES
    WHERE Date_Full >= CURRENT_DATE - INTERVAL '3 months';

    v_date_end := date_trunc('month', CURRENT_DATE);
    v_date_next := v_date_end + INTERVAL '1 month';

    -- Start iteration from v_date_start
    v_date_iter := v_date_start;

    -- Iterate through months to ensure partitions exist
    WHILE v_date_iter <= v_date_next LOOP
        v_partition_suffix := to_char(v_date_iter, 'YYYYMM');

        -- Get partition boundary IDs
        SELECT Date_ID INTO v_partition_start_id 
        FROM BL_DM.DIM_DATES 
        WHERE Date_Full = v_date_iter 
        LIMIT 1;

        SELECT Date_ID INTO v_partition_next_id 
        FROM BL_DM.DIM_DATES 
        WHERE Date_Full = v_date_iter + INTERVAL '1 month'
        LIMIT 1;

        -- Ensure partition exists
        IF NOT EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE schemaname = 'bl_dm' 
            AND tablename = 'fact_transactions_' || v_partition_suffix
        ) THEN
            EXECUTE format(
                'CREATE TABLE BL_DM.FACT_TRANSACTIONS_%s PARTITION OF BL_DM.FACT_TRANSACTIONS 
                 FOR VALUES FROM (%s) TO (%s)',
                v_partition_suffix,
                v_partition_start_id::TEXT,
                v_partition_next_id::TEXT
            );
            RAISE NOTICE 'Partition BL_DM.FACT_TRANSACTIONS_%s created successfully', v_partition_suffix;
        ELSE
            RAISE NOTICE 'Partition BL_DM.FACT_TRANSACTIONS_%s already exists, skipping creation', v_partition_suffix;
        END IF;

        -- Ensure partition is attached
        IF NOT EXISTS (
            SELECT 1 FROM pg_inherits 
            WHERE inhparent = 'bl_dm.fact_transactions'::regclass
              AND inhrelid = ('bl_dm.fact_transactions_' || v_partition_suffix)::regclass
        ) THEN
            EXECUTE format(
                'ALTER TABLE BL_DM.FACT_TRANSACTIONS ATTACH PARTITION BL_DM.FACT_TRANSACTIONS_%s 
                 FOR VALUES FROM (%s) TO (%s)',
                v_partition_suffix,
                v_partition_start_id::TEXT,
                v_partition_next_id::TEXT
            );
            RAISE NOTICE 'Partition BL_DM.FACT_TRANSACTIONS_%s attached successfully', v_partition_suffix;
        ELSE
            RAISE NOTICE 'Partition BL_DM.FACT_TRANSACTIONS_%s already attached, skipping attach', v_partition_suffix;
        END IF;

        -- Move to the next month
        v_date_iter := v_date_iter + INTERVAL '1 month';
    END LOOP;

    -- Insert data into fact_transactions
    INSERT INTO BL_DM.FACT_TRANSACTIONS (
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
    SELECT 
        t.Transaction_SRC_ID,
        d.Date_ID,  
        c.Customer_SURR_ID,
        v.Vehicle_SURR_ID,
        l.Location_SURR_ID,
        e.Employee_SURR_ID,
        sc.Channel_SURR_ID,
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
    ON CONFLICT (Transaction_SRC_ID, Customer_SURR_ID_FK, Vehicle_SURR_ID_FK, Location_SURR_ID_FK, Employee_SURR_ID_FK, Channel_SURR_ID_FK, SOURCE_System, Event_DT_FK)
      DO UPDATE SET 
            Transaction_Payment_Method_ID = EXCLUDED.Transaction_Payment_Method_ID,
            Transaction_Payment_Method_Name = EXCLUDED.Transaction_Payment_Method_Name,
            Transaction_Amount = EXCLUDED.Transaction_Amount,
            Transaction_Quantity = EXCLUDED.Transaction_Quantity,
            Transaction_Discount = EXCLUDED.Transaction_Discount,
            SOURCE_Entity = EXCLUDED.SOURCE_Entity,
            SOURCE_ID = EXCLUDED.SOURCE_ID,
            TA_UPDATE_DT = CURRENT_TIMESTAMP;
    
    RAISE NOTICE 'Transaction fact loaded successfully';
    
EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    RAISE NOTICE 'Error occurred, transaction rolled back: %', SQLERRM;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_fact_transactions()
    OWNER TO postgres;
