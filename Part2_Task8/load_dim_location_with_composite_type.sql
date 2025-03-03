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
