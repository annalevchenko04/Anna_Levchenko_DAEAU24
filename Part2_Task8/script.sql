CREATE OR REPLACE PROCEDURE bl_cl.load_dim_customers()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rows_affected INTEGER;
BEGIN
    -- Log the start of the procedure execution
    PERFORM bl_cl.insert_log('load_dim_customers', 0, 'START', 'Procedure execution started');

    -- Insert or update customers in DIM_CUSTOMERS
    WITH upsert AS (
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
            NEXTVAL('BL_DM.seq_dim_customers') AS Customer_SURR_ID,  -- Generate surrogate key
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
    -- Count the rows affected
    SELECT COUNT(*) INTO rows_affected FROM upsert;

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


-- ALTER PROCEDURE bl_cl.load_dim_customers()
-- OWNER TO postgres;


-- ALTER TABLE BL_DM.DIM_CUSTOMERS 
-- ADD CONSTRAINT dim_customers_unique UNIQUE (Customer_SRC_ID, SOURCE_System);

-- Call bl_cl.load_dim_customers();


-- CREATE OR REPLACE FUNCTION bl_cl.insert_dates()
-- RETURNS VOID AS
-- $$
-- BEGIN
--     INSERT INTO BL_DM.DIM_DATES (
--         Date_Full,
--         Date_Year,
--         Date_Quarter,
--         Date_Month,
--         Date_Week,
--         Date_Day,
--         Date_Day_of_Week
--     )
--     SELECT
--         datum AS Date_Full,
--         EXTRACT(YEAR FROM datum) AS Date_Year,
--         EXTRACT(QUARTER FROM datum) AS Date_Quarter,
--         EXTRACT(MONTH FROM datum) AS Date_Month,
--         EXTRACT(WEEK FROM datum) AS Date_Week,
--         EXTRACT(DAY FROM datum) AS Date_Day,
--         TO_CHAR(datum, 'Day') AS Date_Day_of_Week
--     FROM
--         GENERATE_SERIES('2010-01-01'::DATE, '2030-12-31'::DATE, '1 day'::INTERVAL) AS datum;
    
--     RAISE NOTICE 'Dates inserted into DIM_DATES table successfully.';
-- END;
-- $$ LANGUAGE plpgsql;

-- SELECT bl_cl.insert_dates();


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

    -- Record variable to hold row values
    sales_channel_rec RECORD;

    -- Dynamic SQL variable
    v_sql TEXT;
    
BEGIN
    -- Loop through cursor results
    FOR sales_channel_rec IN cur_sales_channels LOOP
        
        -- Construct dynamic SQL for upsert
        v_sql := FORMAT(
            'INSERT INTO BL_DM.DIM_SALES_CHANNELS (
                Channel_SURR_ID, Channel_SRC_ID, Channel_Type, Channel_Description, 
                SOURCE_System, SOURCE_Entity, SOURCE_ID
            ) VALUES (
                NEXTVAL(''BL_DM.SEQ_DIM_SALES_CHANNELS''), %L, %L, %L, %L, %L, %L
            ) ON CONFLICT (Channel_SRC_ID, SOURCE_System) 
            DO UPDATE SET 
                Channel_Type = EXCLUDED.Channel_Type,
                Channel_Description = EXCLUDED.Channel_Description,
                SOURCE_Entity = EXCLUDED.SOURCE_Entity,
                SOURCE_ID = EXCLUDED.SOURCE_ID;',
            sales_channel_rec.sales_channel_id,
            sales_channel_rec.channel_type,
            sales_channel_rec.channel_description,
            sales_channel_rec.source_system,
            sales_channel_rec.source_entity,
            sales_channel_rec.source_id
        );

        -- Execute the dynamic SQL
        EXECUTE v_sql;
    END LOOP;

    -- Notify that process is complete
    RAISE NOTICE 'Sales channel dimension loaded successfully';

END;
$BODY$;


-- ALTER TABLE BL_DM.DIM_sales_channels
-- ADD CONSTRAINT dim_sales_channels_unique UNIQUE (channel_SRC_ID, SOURCE_System);


-- Call bl_cl.load_dim_sales_channels();


CREATE OR REPLACE PROCEDURE bl_cl.load_dim_employees_scd(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Insert new employees or update existing ones in BL_DM.DIM_EMPLOYEES_SCD
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
    ON CONFLICT (Employee_SRC_ID, SOURCE_System) DO UPDATE 
    SET 
        Employee_Name = EXCLUDED.Employee_Name,
        Employee_Email = EXCLUDED.Employee_Email,
        Employee_Phone = EXCLUDED.Employee_Phone,
        IS_ACTIVE = EXCLUDED.IS_ACTIVE,
        SOURCE_Entity = EXCLUDED.SOURCE_Entity,
        SOURCE_ID = EXCLUDED.SOURCE_ID,
        TA_UPDATE_DT = CURRENT_TIMESTAMP;  -- Set the update timestamp

    -- Handle the logic to mark historical records as inactive for the same employee if necessary
    -- Mark the previous record as inactive if a new active record is inserted
    UPDATE BL_DM.DIM_EMPLOYEES_SCD
	SET 
	    END_DT = CURRENT_DATE,
	    TA_UPDATE_DT = CURRENT_TIMESTAMP
	WHERE Employee_SRC_ID IN (
	    SELECT DISTINCT Employee_SRC_ID 
	    FROM BL_3NF.CE_EMPLOYEES_SCD ce
	    WHERE ce.START_DT > (
	        SELECT MAX(START_DT) FROM BL_DM.DIM_EMPLOYEES_SCD d
	        WHERE d.Employee_SRC_ID = ce.Employee_SRC_ID
	    )
	)
	AND IS_ACTIVE = FALSE;

    RAISE NOTICE 'Employee dimension (SCD) loaded successfully';
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_dim_employees_scd()
    OWNER TO postgres;


-- ALTER TABLE BL_DM.DIM_employees_scd
-- ADD CONSTRAINT dim_employees_scd_unique UNIQUE (employee_SRC_ID, SOURCE_System);

-- Call bl_cl.load_dim_employees_scd();



-- CREATE OR REPLACE PROCEDURE bl_cl.load_dim_locations()
-- LANGUAGE 'plpgsql'
-- AS $BODY$
-- BEGIN
--     -- Insert or update locations in BL_DM.DIM_LOCATIONS
--     INSERT INTO BL_DM.DIM_LOCATIONS (
--         Location_Postal_Code_SRC_ID,
--         Location_City_ID,
--         Location_City_Name,
--         Location_State_ID,
--         Location_State_Name,
--         SOURCE_System,
--         SOURCE_Entity,
--         SOURCE_ID
--     )
--     SELECT 
--         l.Location_ID,  -- Postal Code Source ID
--         c.City_ID,                      -- City ID from CE_CITIES
--         c.City_Name,                    -- City Name from CE_CITIES
--         s.State_ID,                     -- State ID from CE_STATES
--         s.State_Name,                   -- State Name from CE_STATES
--         l.SOURCE_System,                -- Source system
--         l.SOURCE_Entity,                -- Source entity
--         l.SOURCE_ID                     -- Source ID
--     FROM BL_3NF.CE_LOCATIONS l
--     JOIN BL_3NF.CE_CITIES c ON l.City_ID_FK = c.City_ID        -- Join CE_LOCATIONS to CE_CITIES
--     JOIN BL_3NF.CE_STATES s ON c.State_ID_FK = s.State_ID       -- Join CE_CITIES to CE_STATES
--     ON CONFLICT (Location_Postal_Code_SRC_ID, SOURCE_System) DO UPDATE
--     SET 
--         Location_City_Name = EXCLUDED.Location_City_Name,
--         Location_State_Name = EXCLUDED.Location_State_Name,
--         SOURCE_Entity = EXCLUDED.SOURCE_Entity,
--         SOURCE_ID = EXCLUDED.SOURCE_ID,
--         TA_UPDATE_DT = CURRENT_TIMESTAMP;  -- Set the update timestamp
    
--     RAISE NOTICE 'Location dimension loaded successfully';
-- END;
-- $BODY$;


-- ALTER TABLE BL_DM.DIM_locations
-- ADD CONSTRAINT dim_locations_unique UNIQUE (Location_Postal_Code_SRC_ID, SOURCE_System);

-- CALL bl_cl.load_dim_locations();


-- CREATE OR REPLACE PROCEDURE bl_cl.load_dim_vehicles()
-- LANGUAGE 'plpgsql'
-- AS $BODY$
-- BEGIN
--     -- Insert or update vehicles in BL_DM.DIM_VEHICLES
--     INSERT INTO BL_DM.DIM_VEHICLES (
--         VIN_SRC_ID,
--         Vehicle_Color,
--         Vehicle_Transmission_Type,
--         Vehicle_Year,
--         Vehicle_Producer_ID,
--         Vehicle_Producer_Name,
--         Vehicle_Model_ID,
--         Vehicle_Model_Name,
--         Vehicle_Model_Electric_Type,
--         Vehicle_Model_Electric_Range,
--         Vehicle_Model_Type_CAFV,
--         SOURCE_System,
--         SOURCE_Entity,
--         SOURCE_ID
--     )
--     SELECT 
--         v.Vehicle_ID,                     -- Vehicle VIN from CE_VEHICLES
--         v.Vehile_Color,                   -- Vehicle Color from CE_VEHICLES
--         v.Vehile_Transmission_Type,      -- Vehicle Transmission Type from CE_VEHICLES
--         v.Vehile_Year,                   -- Vehicle Year from CE_VEHICLES
--         p.Producer_ID,                -- Producer ID from CE_MODELS
--         p.Producer_Name,                 -- Producer Name from CE_PRODUCERS
--         m.Model_ID,                      -- Model ID from CE_MODELS
--         m.Model_Name,                    -- Model Name from CE_MODELS
--         m.Model_Electric_Type,           -- Electric Type from CE_MODELS
--         m.Model_Electric_Range,          -- Electric Range from CE_MODELS
--         m.Model_Type_CAFV,               -- CAFV Type from CE_MODELS
--         v.SOURCE_System,                 -- Source system from CE_VEHICLES
--         v.SOURCE_Entity,                 -- Source entity from CE_VEHICLES
--         v.SOURCE_ID                      -- Source ID from CE_VEHICLES
--     FROM BL_3NF.CE_VEHICLES v
--     JOIN BL_3NF.CE_MODELS m ON v.Model_ID_FK = m.Model_ID          -- Join CE_VEHICLES to CE_MODELS
--     JOIN BL_3NF.CE_PRODUCERS p ON m.Producer_ID_FK = p.Producer_ID  -- Join CE_MODELS to CE_PRODUCERS
--     ON CONFLICT (VIN_SRC_ID, Vehicle_Producer_ID, Vehicle_Model_ID, SOURCE_System) DO UPDATE
--     SET 
--         Vehicle_Color = EXCLUDED.Vehicle_Color,
--         Vehicle_Transmission_Type = EXCLUDED.Vehicle_Transmission_Type,
--         Vehicle_Year = EXCLUDED.Vehicle_Year,
--         Vehicle_Producer_Name = EXCLUDED.Vehicle_Producer_Name,
--         Vehicle_Model_Name = EXCLUDED.Vehicle_Model_Name,
--         Vehicle_Model_Electric_Type = EXCLUDED.Vehicle_Model_Electric_Type,
--         Vehicle_Model_Electric_Range = EXCLUDED.Vehicle_Model_Electric_Range,
--         Vehicle_Model_Type_CAFV = EXCLUDED.Vehicle_Model_Type_CAFV,
--         SOURCE_Entity = EXCLUDED.SOURCE_Entity,
--         SOURCE_ID = EXCLUDED.SOURCE_ID,
--         TA_UPDATE_DT = CURRENT_TIMESTAMP;  -- Set the update timestamp
    
--     RAISE NOTICE 'Vehicle dimension loaded successfully';
-- END;
-- $BODY$;

-- Create a unique constraint on the columns involved in the ON CONFLICT clause
-- ALTER TABLE BL_DM.DIM_VEHICLES
-- ADD CONSTRAINT unique_vehicle UNIQUE (VIN_SRC_ID, Vehicle_Producer_ID, Vehicle_Model_ID, SOURCE_System);


-- CALL bl_cl.load_dim_vehicles();


-- It tooks 8 minutes to load fact_transactions

CREATE OR REPLACE PROCEDURE bl_cl.load_fact_transactions(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
        -- Insert or update data into FACT_TRANSACTIONS
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
        ON CONFLICT (Transaction_SRC_ID, Customer_SURR_ID_FK, Vehicle_SURR_ID_FK, Location_SURR_ID_FK, Employee_SURR_ID_FK, Channel_SURR_ID_FK, SOURCE_System) DO UPDATE
        SET 
            Transaction_Payment_Method_ID = EXCLUDED.Transaction_Payment_Method_ID,
            Transaction_Payment_Method_Name = EXCLUDED.Transaction_Payment_Method_Name,
            Transaction_Amount = EXCLUDED.Transaction_Amount,
            Transaction_Quantity = EXCLUDED.Transaction_Quantity,
            Transaction_Discount = EXCLUDED.Transaction_Discount,
            SOURCE_Entity = EXCLUDED.SOURCE_Entity,
            SOURCE_ID = EXCLUDED.SOURCE_ID,
            TA_UPDATE_DT = CURRENT_TIMESTAMP;  -- Set the update timestamp
        
        RAISE NOTICE 'Transaction fact loaded successfully';

    EXCEPTION
        WHEN OTHERS THEN
            -- In case of any error, rollback the transaction
            ROLLBACK;
            RAISE NOTICE 'Error occurred, transaction rolled back: %', SQLERRM;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_fact_transactions()
    OWNER TO postgres;


ALTER TABLE BL_DM.FACT_TRANSACTIONS 
ADD CONSTRAINT fact_transactions_unique 
UNIQUE (Transaction_SRC_ID, Customer_SURR_ID_FK, Vehicle_SURR_ID_FK, Location_SURR_ID_FK, Employee_SURR_ID_FK, Channel_SURR_ID_FK, SOURCE_System);

--CALL bl_cl.load_fact_transactions()
