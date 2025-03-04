CREATE OR REPLACE PROCEDURE bl_cl.load_dim_customers()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rows_affected INTEGER;
    dynamic_sql TEXT;
BEGIN
    -- Log the start of the procedure execution
    PERFORM bl_cl.insert_log('load_dim_customers', 0, 'START', 'Procedure execution started');

    -- Construct dynamic SQL for the insert or update operation
    dynamic_sql := 
    'WITH upsert AS (
        INSERT INTO BL_DM.DIM_CUSTOMERS (
            Customer_SURR_ID,
            Customer_SRC_ID,
            Customer_Passport,
            Customer_Name,
            Customer_Gender,
            Customer_Age,
            SOURCE_System,
            SOURCE_Entity,
            SOURCE_ID
        )
        SELECT 
            NEXTVAL(''BL_DM.seq_dim_customers'') AS Customer_SURR_ID,  -- Generate surrogate key
            c.Customer_ID,
            c.Customer_Passport,
            c.Customer_Name,
            c.Customer_Gender,
            c.Customer_Age,
            c.SOURCE_System,
            c.SOURCE_Entity,
            c.SOURCE_ID
        FROM (
            SELECT DISTINCT ON (Customer_ID, SOURCE_System) *  
            FROM BL_3NF.CE_CUSTOMERS
            ORDER BY Customer_ID, SOURCE_System, TA_INSERT_DT DESC
        ) c
        ON CONFLICT (Customer_SRC_ID, SOURCE_System) 
        DO UPDATE SET
            Customer_Passport = EXCLUDED.Customer_Passport,
            Customer_Name = EXCLUDED.Customer_Name,
            Customer_Gender = EXCLUDED.Customer_Gender,
            Customer_Age = EXCLUDED.Customer_Age,
            SOURCE_Entity = EXCLUDED.SOURCE_Entity,
            SOURCE_ID = EXCLUDED.SOURCE_ID
        WHERE 
            DIM_CUSTOMERS.Customer_Passport IS DISTINCT FROM EXCLUDED.Customer_Passport
            OR DIM_CUSTOMERS.Customer_Name IS DISTINCT FROM EXCLUDED.Customer_Name
            OR DIM_CUSTOMERS.Customer_Gender IS DISTINCT FROM EXCLUDED.Customer_Gender
            OR DIM_CUSTOMERS.Customer_Age IS DISTINCT FROM EXCLUDED.Customer_Age
            OR DIM_CUSTOMERS.SOURCE_Entity IS DISTINCT FROM EXCLUDED.SOURCE_Entity
            OR DIM_CUSTOMERS.SOURCE_ID IS DISTINCT FROM EXCLUDED.SOURCE_ID
        RETURNING *  -- Capture rows inserted or updated
    )
    SELECT COUNT(*) FROM upsert;';

    -- Execute the dynamic SQL for insert/update
    EXECUTE dynamic_sql INTO rows_affected;

    -- Log the end of the procedure execution
    PERFORM bl_cl.insert_log('load_dim_customers', rows_affected, 'SUCCESS', 'Procedure execution completed successfully');

    RAISE NOTICE 'Customer dimension loaded successfully. Rows affected: %', rows_affected;

EXCEPTION
    WHEN OTHERS THEN
        -- Log any errors that occur
        PERFORM bl_cl.insert_log('load_dim_customers', 0, 'FAILURE', 'Error occurred: ' || SQLERRM);
        RAISE NOTICE 'Error occurred, transaction rolled back: %', SQLERRM;
        ROLLBACK;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_dim_customers()
OWNER TO postgres;



CREATE OR REPLACE FUNCTION bl_cl.insert_dates()
RETURNS VOID AS
$$
BEGIN
    INSERT INTO BL_DM.DIM_DATES (
        Date_Full,
        Date_Year,
        Date_Quarter,
        Date_Month,
        Date_Week,
        Date_Day,
        Date_Day_of_Week
    )
    SELECT
        datum AS Date_Full,
        EXTRACT(YEAR FROM datum) AS Date_Year,
        EXTRACT(QUARTER FROM datum) AS Date_Quarter,
        EXTRACT(MONTH FROM datum) AS Date_Month,
        EXTRACT(WEEK FROM datum) AS Date_Week,
        EXTRACT(DAY FROM datum) AS Date_Day,
        TO_CHAR(datum, 'Day') AS Date_Day_of_Week
    FROM
        GENERATE_SERIES('2010-01-01'::DATE, '2030-12-31'::DATE, '1 day'::INTERVAL) AS datum;
    
    RAISE NOTICE 'Dates inserted into DIM_DATES table successfully.';
END;
$$ LANGUAGE plpgsql;


DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_type 
        WHERE typname = 'location_type' 
        AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'bl_cl')
    ) THEN
        CREATE TYPE bl_cl.location_type AS (
            Location_Postal_Code_SRC_ID INT,
            Location_City_ID INT,
            Location_City_Name TEXT,
            Location_State_ID INT,
            Location_State_Name TEXT,
            SOURCE_System TEXT,
            SOURCE_Entity TEXT,
            SOURCE_ID TEXT
        );
    END IF;
END $$;

CREATE OR REPLACE PROCEDURE bl_cl.load_dim_locations()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    location_rec bl_cl.location_type;  -- Composite type for location data
    rows_affected INTEGER := 0;
    affected INTEGER := 0;  -- Temp variable to capture affected rows
BEGIN
    -- Log the start of the procedure execution
    PERFORM BL_CL.insert_log('load_dim_locations', 0, 'START', 'Procedure execution started');

    -- Cursor to fetch location data
    FOR location_rec IN 
        SELECT 
            l.Location_ID, 
            c.City_ID, 
            c.City_Name, 
            s.State_ID, 
            s.State_Name, 
            l.SOURCE_System, 
            l.SOURCE_Entity, 
            l.SOURCE_ID
        FROM BL_3NF.CE_LOCATIONS l
        JOIN BL_3NF.CE_CITIES c ON l.City_ID_FK = c.City_ID        
        JOIN BL_3NF.CE_STATES s ON c.State_ID_FK = s.State_ID   
    LOOP
        -- Insert or update locations in DIM_LOCATIONS
        INSERT INTO BL_DM.DIM_LOCATIONS (
            Location_Postal_Code_SRC_ID,
            Location_City_ID,
            Location_City_Name,
            Location_State_ID,
            Location_State_Name,
            SOURCE_System,
            SOURCE_Entity,
            SOURCE_ID
        )
        VALUES (
            location_rec.Location_Postal_Code_SRC_ID,
            location_rec.Location_City_ID,
            location_rec.Location_City_Name,
            location_rec.Location_State_ID,
            location_rec.Location_State_Name,
            location_rec.SOURCE_System,
            location_rec.SOURCE_Entity,
            location_rec.SOURCE_ID
        )
        ON CONFLICT (Location_Postal_Code_SRC_ID, SOURCE_System) 
        DO UPDATE SET
            Location_City_Name = EXCLUDED.Location_City_Name,
            Location_State_Name = EXCLUDED.Location_State_Name,
            SOURCE_Entity = EXCLUDED.SOURCE_Entity,
            SOURCE_ID = EXCLUDED.SOURCE_ID,
            TA_UPDATE_DT = CURRENT_TIMESTAMP
        WHERE 
            DIM_LOCATIONS.Location_City_Name IS DISTINCT FROM EXCLUDED.Location_City_Name
            OR DIM_LOCATIONS.Location_State_Name IS DISTINCT FROM EXCLUDED.Location_State_Name
            OR DIM_LOCATIONS.SOURCE_Entity IS DISTINCT FROM EXCLUDED.SOURCE_Entity
            OR DIM_LOCATIONS.SOURCE_ID IS DISTINCT FROM EXCLUDED.SOURCE_ID
        RETURNING 1 INTO affected;  -- Capture if a row was actually modified

        -- Only increment rows_affected if an update/insert occurred
        IF affected IS NOT NULL THEN
            rows_affected := rows_affected + affected;
        END IF;
    END LOOP;

    -- Log the end of the procedure execution
    PERFORM BL_CL.insert_log('load_dim_locations', rows_affected, 'SUCCESS', 'Procedure execution completed successfully. Rows affected: ' || rows_affected);

    -- Notify that process is complete with affected row count
    RAISE NOTICE 'Location dimension loaded successfully. Rows affected: %', rows_affected;

EXCEPTION
    WHEN OTHERS THEN
        -- Log any errors that occur
        PERFORM BL_CL.insert_log('load_dim_locations', 0, 'FAILURE', 'Error occurred: ' || SQLERRM);
        RAISE NOTICE 'Error occurred, transaction rolled back: %', SQLERRM;
        ROLLBACK;
END;
$BODY$;




CREATE OR REPLACE PROCEDURE bl_cl.load_dim_vehicles()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rows_affected INTEGER;
BEGIN
    -- Log the start of the procedure execution
    PERFORM BL_CL.insert_log('load_dim_vehicles', 0, 'START', 'Procedure execution started');

    -- Insert or update vehicles in DIM_VEHICLES
    WITH upsert AS (
        INSERT INTO BL_DM.DIM_VEHICLES (
            VIN_SRC_ID,
            Vehicle_Color,
            Vehicle_Transmission_Type,
            Vehicle_Year,
            Vehicle_Producer_ID,
            Vehicle_Producer_Name,
            Vehicle_Model_ID,
            Vehicle_Model_Name,
            Vehicle_Model_Electric_Type,
            Vehicle_Model_Electric_Range,
            Vehicle_Model_Type_CAFV,
            SOURCE_System,
            SOURCE_Entity,
            SOURCE_ID
        )
        SELECT 
            v.Vehicle_ID,                     -- Vehicle VIN from CE_VEHICLES
            v.Vehile_Color,                   -- Vehicle Color from CE_VEHICLES
            v.Vehile_Transmission_Type,      -- Vehicle Transmission Type from CE_VEHICLES
            v.Vehile_Year,                   -- Vehicle Year from CE_VEHICLES
            p.Producer_ID,                   -- Producer ID from CE_MODELS
            p.Producer_Name,                 -- Producer Name from CE_PRODUCERS
            m.Model_ID,                      -- Model ID from CE_MODELS
            m.Model_Name,                    -- Model Name from CE_MODELS
            m.Model_Electric_Type,           -- Electric Type from CE_MODELS
            m.Model_Electric_Range,          -- Electric Range from CE_MODELS
            m.Model_Type_CAFV,               -- CAFV Type from CE_MODELS
            v.SOURCE_System,                 -- Source system from CE_VEHICLES
            v.SOURCE_Entity,                 -- Source entity from CE_VEHICLES
            v.SOURCE_ID                      -- Source ID from CE_VEHICLES
        FROM BL_3NF.CE_VEHICLES v
        JOIN BL_3NF.CE_MODELS m ON v.Model_ID_FK = m.Model_ID          -- Join CE_VEHICLES to CE_MODELS
        JOIN BL_3NF.CE_PRODUCERS p ON m.Producer_ID_FK = p.Producer_ID  -- Join CE_MODELS to CE_PRODUCERS
        ON CONFLICT (VIN_SRC_ID, Vehicle_Producer_ID, Vehicle_Model_ID, SOURCE_System) 
        DO UPDATE
        SET 
            Vehicle_Color = EXCLUDED.Vehicle_Color,
            Vehicle_Transmission_Type = EXCLUDED.Vehicle_Transmission_Type,
            Vehicle_Year = EXCLUDED.Vehicle_Year,
            Vehicle_Producer_Name = EXCLUDED.Vehicle_Producer_Name,
            Vehicle_Model_Name = EXCLUDED.Vehicle_Model_Name,
            Vehicle_Model_Electric_Type = EXCLUDED.Vehicle_Model_Electric_Type,
            Vehicle_Model_Electric_Range = EXCLUDED.Vehicle_Model_Electric_Range,
            Vehicle_Model_Type_CAFV = EXCLUDED.Vehicle_Model_Type_CAFV,
            SOURCE_Entity = EXCLUDED.SOURCE_Entity,
            SOURCE_ID = EXCLUDED.SOURCE_ID,
            TA_UPDATE_DT = CURRENT_TIMESTAMP
        WHERE 
            DIM_VEHICLES.Vehicle_Color IS DISTINCT FROM EXCLUDED.Vehicle_Color
            OR DIM_VEHICLES.Vehicle_Transmission_Type IS DISTINCT FROM EXCLUDED.Vehicle_Transmission_Type
            OR DIM_VEHICLES.Vehicle_Year IS DISTINCT FROM EXCLUDED.Vehicle_Year
            OR DIM_VEHICLES.Vehicle_Producer_Name IS DISTINCT FROM EXCLUDED.Vehicle_Producer_Name
            OR DIM_VEHICLES.Vehicle_Model_Name IS DISTINCT FROM EXCLUDED.Vehicle_Model_Name
            OR DIM_VEHICLES.Vehicle_Model_Electric_Type IS DISTINCT FROM EXCLUDED.Vehicle_Model_Electric_Type
            OR DIM_VEHICLES.Vehicle_Model_Electric_Range IS DISTINCT FROM EXCLUDED.Vehicle_Model_Electric_Range
            OR DIM_VEHICLES.Vehicle_Model_Type_CAFV IS DISTINCT FROM EXCLUDED.Vehicle_Model_Type_CAFV
            OR DIM_VEHICLES.SOURCE_Entity IS DISTINCT FROM EXCLUDED.SOURCE_Entity
            OR DIM_VEHICLES.SOURCE_ID IS DISTINCT FROM EXCLUDED.SOURCE_ID
        RETURNING *  -- Capture rows inserted or updated
    )
    -- Count the rows affected
    SELECT COUNT(*) INTO rows_affected FROM upsert;

    -- Log the end of the procedure execution
    PERFORM BL_CL.insert_log('load_dim_vehicles', rows_affected, 'SUCCESS', 'Procedure execution completed successfully. Rows affected: ' || rows_affected);

    -- Notify that process is complete with affected row count
    RAISE NOTICE 'Vehicle dimension loaded successfully. Rows affected: %', rows_affected;

EXCEPTION
    WHEN OTHERS THEN
        -- Log any errors that occur
        PERFORM BL_CL.insert_log('load_dim_vehicles', 0, 'FAILURE', 'Error occurred: ' || SQLERRM);
        RAISE NOTICE 'Error occurred, transaction rolled back: %', SQLERRM;
        ROLLBACK;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_dim_vehicles()
OWNER TO postgres;



CREATE OR REPLACE PROCEDURE bl_cl.load_dim_sales_channels()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    -- Cursor to fetch distinct latest sales channels
    cur_sales_channels CURSOR FOR 
        SELECT DISTINCT ON (sales_channel_ID, SOURCE_System) 
               sales_channel_ID, Channel_Type, Channel_Description, 
               SOURCE_System, SOURCE_Entity, SOURCE_ID
        FROM BL_3NF.CE_SALES_CHANNELS
        ORDER BY sales_channel_ID, SOURCE_System, TA_INSERT_DT DESC;

    
    sales_channel_rec RECORD;
    
    -- Counter for rows affected
    rows_affected INTEGER := 0;
    
    -- Variable to check if row was actually inserted/updated
    row_count INTEGER;
    
BEGIN
    -- Log the start of the procedure execution
    PERFORM bl_cl.insert_log('load_dim_sales_channels', 0, 'START', 'Procedure execution started');
    
    -- Open the cursor and loop through results
    FOR sales_channel_rec IN cur_sales_channels LOOP
        
        -- Attempt to insert or update the row and capture affected rows
        BEGIN
            WITH upsert AS (
                INSERT INTO BL_DM.DIM_SALES_CHANNELS (
                    Channel_SURR_ID, Channel_SRC_ID, Channel_Type, Channel_Description, 
                    SOURCE_System, SOURCE_Entity, SOURCE_ID
                ) VALUES (
                    NEXTVAL('BL_DM.SEQ_DIM_SALES_CHANNELS'), sales_channel_rec.sales_channel_id, 
                    sales_channel_rec.channel_type, sales_channel_rec.channel_description, 
                    sales_channel_rec.source_system, sales_channel_rec.source_entity, 
                    sales_channel_rec.source_id
                ) 
                ON CONFLICT (Channel_SRC_ID, SOURCE_System) 
                DO UPDATE SET 
                    Channel_Type = EXCLUDED.Channel_Type,
                    Channel_Description = EXCLUDED.Channel_Description,
                    SOURCE_Entity = EXCLUDED.SOURCE_Entity,
                    SOURCE_ID = EXCLUDED.SOURCE_ID
                WHERE 
                    DIM_SALES_CHANNELS.Channel_Type IS DISTINCT FROM EXCLUDED.Channel_Type
                    OR DIM_SALES_CHANNELS.Channel_Description IS DISTINCT FROM EXCLUDED.Channel_Description
                    OR DIM_SALES_CHANNELS.SOURCE_Entity IS DISTINCT FROM EXCLUDED.SOURCE_Entity
                    OR DIM_SALES_CHANNELS.SOURCE_ID IS DISTINCT FROM EXCLUDED.SOURCE_ID
                RETURNING 1  -- Returns 1 for each affected row
            )
            SELECT COUNT(*) INTO row_count FROM upsert;
            
            -- Increment affected rows counter only if actual change occurred
            rows_affected := rows_affected + row_count;
        
        EXCEPTION WHEN OTHERS THEN
            -- Log any errors that occur during individual row processing
            PERFORM bl_cl.insert_log('load_dim_sales_channels', 0, 'FAILURE', 'Error on row with ID ' || sales_channel_rec.sales_channel_id || ': ' || SQLERRM);
        END;
        
    END LOOP;
    
    -- Log the end of the procedure execution
    PERFORM bl_cl.insert_log('load_dim_sales_channels', rows_affected, 'SUCCESS', 'Procedure execution completed successfully');
    
    RAISE NOTICE 'Sales channel dimension loaded successfully. Rows affected: %', rows_affected;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log any general errors
        PERFORM bl_cl.insert_log('load_dim_sales_channels', 0, 'FAILURE', 'Error occurred: ' || SQLERRM);
        RAISE NOTICE 'Error occurred, transaction rolled back: %', SQLERRM;
        ROLLBACK;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_dim_sales_channels()
OWNER TO postgres;



-- PROCEDURE: bl_cl.load_dim_employees_scd()

-- DROP PROCEDURE IF EXISTS bl_cl.load_dim_employees_scd();

CREATE OR REPLACE PROCEDURE bl_cl.load_dim_employees_scd(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rows_affected INTEGER;
BEGIN
    -- Log the start of the procedure execution
    PERFORM bl_cl.insert_log('load_dim_employees_scd', 0, 'START', 'Procedure execution started');

    -- Insert new employees or update existing ones in BL_DM.DIM_EMPLOYEES_SCD
    WITH upsert AS (
        INSERT INTO BL_DM.DIM_EMPLOYEES_SCD (
            Employee_SURR_ID,
            Employee_SRC_ID,
            Employee_Name,
            Employee_Email,
            Employee_Phone,
            START_DT,
            END_DT,
            IS_ACTIVE,
            SOURCE_System,
            SOURCE_Entity,
            SOURCE_ID
        )
        SELECT 
            NEXTVAL('BL_DM.SEQ_DIM_EMPLOYEES_SCD') AS Employee_SURR_ID,  -- Generate surrogate key
            e.Employee_ID,
            e.Employee_Name,
            e.Employee_Email,
            e.Employee_Phone,
            e.START_DT,
            e.END_DT,
            e.IS_ACTIVE,
            e.SOURCE_System,
            e.SOURCE_Entity,
            e.SOURCE_ID
        FROM (
            SELECT DISTINCT ON (Employee_ID, SOURCE_System) *  
            FROM BL_3NF.CE_EMPLOYEES_SCD
            ORDER BY Employee_ID, SOURCE_System, START_DT DESC
        ) e
        ON CONFLICT (Employee_SRC_ID, SOURCE_System, START_DT) 
		DO UPDATE SET
		    Employee_Name = EXCLUDED.Employee_Name,
		    Employee_Email = EXCLUDED.Employee_Email,
		    Employee_Phone = EXCLUDED.Employee_Phone,
		    IS_ACTIVE = EXCLUDED.IS_ACTIVE,
			END_DT = EXCLUDED.END_DT,
		    SOURCE_Entity = EXCLUDED.SOURCE_Entity,
		    SOURCE_ID = EXCLUDED.SOURCE_ID,
		    TA_UPDATE_DT = CURRENT_TIMESTAMP
		WHERE
		    DIM_EMPLOYEES_SCD.Employee_Name IS DISTINCT FROM EXCLUDED.Employee_Name
		    OR DIM_EMPLOYEES_SCD.Employee_Email IS DISTINCT FROM EXCLUDED.Employee_Email
		    OR DIM_EMPLOYEES_SCD.Employee_Phone IS DISTINCT FROM EXCLUDED.Employee_Phone
		    OR DIM_EMPLOYEES_SCD.IS_ACTIVE IS DISTINCT FROM EXCLUDED.IS_ACTIVE
			OR DIM_EMPLOYEES_SCD.END_DT IS DISTINCT FROM EXCLUDED.END_DT
		    OR DIM_EMPLOYEES_SCD.SOURCE_Entity IS DISTINCT FROM EXCLUDED.SOURCE_Entity
		    OR DIM_EMPLOYEES_SCD.SOURCE_ID IS DISTINCT FROM EXCLUDED.SOURCE_ID

        RETURNING *  -- Capture rows inserted or updated
    )
    -- Count the rows affected
    SELECT COUNT(*) INTO rows_affected FROM upsert;

    -- Log the end of the procedure execution
    PERFORM bl_cl.insert_log('load_dim_employees_scd', rows_affected, 'SUCCESS', 'Procedure execution completed successfully');

    RAISE NOTICE 'Employee dimension (SCD) loaded successfully. Rows affected: %', rows_affected;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log any errors that occur
        PERFORM bl_cl.insert_log('load_dim_employees_scd', 0, 'FAILURE', 'Error occurred: ' || SQLERRM);
        RAISE NOTICE 'Error occurred, transaction rolled back: %', SQLERRM;
        ROLLBACK;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_dim_employees_scd()
    OWNER TO postgres;




CREATE OR REPLACE PROCEDURE bl_cl.load_fact_transactions(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_date_iter DATE; 
    v_partition_suffix TEXT;
    v_partition_start_id INT;
    v_partition_next_id INT;
    v_date_start DATE;
    v_date_end DATE;
    rows_affected INT := 0;  -- Initialize rows_affected to 0
    v_exists BOOLEAN;        -- For checking if the record exists
    v_transaction_record RECORD;  -- Declare loop variable as RECORD type
BEGIN
    -- Log the start of the procedure
    PERFORM bl_cl.insert_log('load_fact_transactions', 0, 'START', 'Procedure execution started');

    -- Define the start date as the earliest available date, ensuring it does not go before 2022
    SELECT GREATEST(date_trunc('month', MIN(Date_Full)), '2022-01-01'::DATE) 
    INTO v_date_start
    FROM BL_DM.DIM_DATES;

    -- Define the end date as the current month
    v_date_end := date_trunc('month', CURRENT_DATE);
    
    -- Start iteration from v_date_start
    v_date_iter := v_date_start;

    -- Iterate through all months to ensure partitions exist
    WHILE v_date_iter <= v_date_end LOOP
        v_partition_suffix := to_char(v_date_iter, 'YYYYMM');

        -- Get partition boundary IDs
        SELECT MIN(Date_ID) INTO v_partition_start_id
        FROM BL_DM.DIM_DATES 
        WHERE Date_Full = v_date_iter;

        SELECT MIN(Date_ID) INTO v_partition_next_id
        FROM BL_DM.DIM_DATES 
        WHERE Date_Full = v_date_iter + INTERVAL '1 month';

        -- Skip if NULL (to avoid syntax errors)
        IF v_partition_start_id IS NULL THEN
            RAISE NOTICE 'Skipping partition % due to NULL Event_DT_FK', v_partition_suffix;
        ELSE
            -- Ensure partition exists
            IF NOT EXISTS (
                SELECT 1 FROM pg_tables 
                WHERE schemaname = 'bl_dm' 
                AND tablename = 'fact_transactions_' || v_partition_suffix
            ) THEN
                EXECUTE format(
                    'CREATE TABLE bl_dm.fact_transactions_%s PARTITION OF bl_dm.fact_transactions 
                     FOR VALUES FROM (%s) TO (%s);',
                    v_partition_suffix,
                    v_partition_start_id,
                    v_partition_next_id
                );
                RAISE NOTICE 'Partition bl_dm.fact_transactions_%s created successfully', v_partition_suffix;
            ELSE
                RAISE NOTICE 'Partition bl_dm.fact_transactions_%s already exists, skipping creation', v_partition_suffix;
            END IF;

            -- Ensure partition is attached
            IF NOT EXISTS (
                SELECT 1 FROM pg_inherits 
                WHERE inhparent = 'bl_dm.fact_transactions'::regclass
                  AND inhrelid = ('bl_dm.fact_transactions_' || v_partition_suffix)::regclass
            ) THEN
                EXECUTE format(
                    'ALTER TABLE bl_dm.fact_transactions ATTACH PARTITION bl_dm.fact_transactions_%s 
                     FOR VALUES FROM (%s) TO (%s);',
                    v_partition_suffix,
                    v_partition_start_id,
                    v_partition_next_id
                );
                RAISE NOTICE 'Partition bl_dm.fact_transactions_%s attached successfully', v_partition_suffix;
            ELSE
                RAISE NOTICE 'Partition bl_dm.fact_transactions_%s already attached, skipping attach', v_partition_suffix;
            END IF;
        END IF;

        -- Move to the next month
        v_date_iter := v_date_iter + INTERVAL '1 month';
    END LOOP;

    -- Insert or Update data into fact_transactions
    FOR v_transaction_record IN
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
    LOOP
        -- Check if the record already exists in FACT_TRANSACTIONS
        SELECT EXISTS (
            SELECT 1
            FROM BL_DM.FACT_TRANSACTIONS ft
            WHERE ft.Transaction_SRC_ID = v_transaction_record.Transaction_SRC_ID
              AND ft.Customer_SURR_ID_FK = v_transaction_record.Customer_SURR_ID
              AND ft.Vehicle_SURR_ID_FK = v_transaction_record.Vehicle_SURR_ID
              AND ft.Location_SURR_ID_FK = v_transaction_record.Location_SURR_ID
              AND ft.Employee_SURR_ID_FK = v_transaction_record.Employee_SURR_ID
              AND ft.Channel_SURR_ID_FK = v_transaction_record.Channel_SURR_ID
              AND ft.SOURCE_System = v_transaction_record.SOURCE_System
              AND ft.Event_DT_FK = v_transaction_record.Date_ID
        ) INTO v_exists;

        IF v_exists THEN
            -- Log if the record exists and will not be affected
            RAISE NOTICE 'Record exists for Transaction_SRC_ID: %, skipping insert', v_transaction_record.Transaction_SRC_ID;
        ELSE
            -- Perform the insert if it doesn't exist
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

            -- Increment rows_affected for insert
            rows_affected := rows_affected + 1;
        END IF;
    END LOOP;

    -- Log the end of the procedure execution
    PERFORM bl_cl.insert_log('load_fact_transactions', rows_affected, 'SUCCESS', 'Procedure execution completed successfully');
    
    RAISE NOTICE 'Transaction fact loaded successfully. Rows affected: %', rows_affected;

EXCEPTION
    WHEN OTHERS THEN
        -- Log any errors that occur
        PERFORM bl_cl.insert_log('load_fact_transactions', 0, 'FAILURE', 'Error occurred: ' || SQLERRM);
        RAISE NOTICE 'Error occurred: %', SQLERRM;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_fact_transactions()
    OWNER TO postgres;



--SELECT bl_cl.insert_dates();


--Call bl_cl.load_dim_customers();

--CALL bl_cl.load_dim_locations();

--CALL bl_cl.load_dim_vehicles();

-- Call bl_cl.load_dim_sales_channels();

-- Call bl_cl.load_dim_employees_scd();

--CALL bl_cl.load_fact_transactions();
