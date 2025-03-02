CREATE OR REPLACE PROCEDURE bl_cl.load_payment_methods()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
    v_rows_affected INT := 0;  -- Initialize a counter for rows affected
BEGIN
    -- Log the start of the procedure
    PERFORM BL_CL.insert_log('load_payment_methods', 0, 'START', 'Procedure execution started.');
    
    FOR rec IN 
        SELECT 
            COALESCE(payment_method, 'N/A') AS Payment_Method_SRC_ID, 
            COALESCE(payment_method_name, 'N/A') AS Payment_Method_Name,  
            CASE
                WHEN source = 'sales_data_1' THEN 'SALES_DATA_1'
                ELSE 'SALES_DATA_2'
            END AS SOURCE_System,
            CASE 
                WHEN source = 'sales_data_1' THEN 'SRC_SALES_1'
                ELSE 'SRC_SALES_2'
            END AS SOURCE_Entity,
            CASE 
                WHEN source = 'sales_data_1' THEN '1'
                ELSE '2'
            END AS SOURCE_ID
        FROM (
            SELECT * FROM (
                SELECT DISTINCT 
                    'N/A' AS payment_method,  
                    'N/A' AS payment_method_name,  
                    'sales_data_1' AS source
                FROM sa_v_sales_data_wa.src_sales_wa
                LIMIT 1
            ) AS subquery1

            UNION

            SELECT DISTINCT 
                payment_method,  
                payment_method AS payment_method_name,  
                'sales_data_2' AS source
            FROM sa_v_sales_data_fl.src_sales_fl
            WHERE payment_method IS NOT NULL
        ) s
        WHERE NOT EXISTS (
            SELECT 1 
            FROM BL_3NF.CE_PAYMENT_METHODS p
            WHERE p.Payment_Method_SRC_ID = COALESCE(s.payment_method, 'N/A')
              AND p.SOURCE_System = CASE WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1' ELSE 'SALES_DATA_2' END
              AND p.SOURCE_Entity = CASE WHEN s.source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END
        )
    LOOP
        BEGIN
            INSERT INTO BL_3NF.CE_PAYMENT_METHODS (
                Payment_Method_SRC_ID,
                Payment_Method_Name,
                SOURCE_System,
                SOURCE_Entity,
                SOURCE_ID
            ) VALUES (
                rec.Payment_Method_SRC_ID,
                rec.Payment_Method_Name,
                rec.SOURCE_System,
                rec.SOURCE_Entity,
                rec.SOURCE_ID
            );
            
            -- Increment the row count for each successful insert
            v_rows_affected := v_rows_affected + 1;

        EXCEPTION WHEN OTHERS THEN
            -- Log any errors encountered
            RAISE NOTICE 'Error inserting payment method %: %', rec.Payment_Method_SRC_ID, SQLERRM;
            PERFORM BL_CL.insert_log('load_payment_methods', 0, 'ERROR', 'Error inserting payment method ' || rec.Payment_Method_SRC_ID || ': ' || SQLERRM);
        END;
    END LOOP;
    
    -- Log the end of the procedure with the number of rows affected
    PERFORM BL_CL.insert_log('load_payment_methods', v_rows_affected, 'SUCCESS', 'Procedure execution completed. Rows affected: ' || v_rows_affected);
    
    COMMIT;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_payment_methods()
    OWNER TO postgres;




CREATE OR REPLACE PROCEDURE bl_cl.load_sales_channels()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
    v_rows_affected INT := 0;  -- Initialize a counter for rows affected
BEGIN
    -- Log the start of the procedure
    PERFORM BL_CL.insert_log('load_sales_channels', 0, 'START', 'Procedure execution started.');
    
    FOR rec IN 
        SELECT 
            COALESCE(channel_id, 'N/A') AS Channel_SRC_ID,  
            COALESCE(channel_type, 'N/A') AS Channel_Type,  
            COALESCE(channel_description, 'N/A') AS Channel_Description,  
            CASE
                WHEN source = 'sales_data_1' THEN 'SALES_DATA_1'
                ELSE 'SALES_DATA_2'
            END AS SOURCE_System,
            CASE 
                WHEN source = 'sales_data_1' THEN 'SRC_SALES_1'
                ELSE 'SRC_SALES_2'
            END AS SOURCE_Entity,
            CASE 
                WHEN source = 'sales_data_1' THEN '1'
                ELSE '2'
            END AS SOURCE_ID
        FROM (
            SELECT DISTINCT
                channel_id,  
                channel_type,  
                channel_description,  
                'sales_data_1' AS source
            FROM sa_v_sales_data_wa.src_sales_wa

            UNION

            SELECT DISTINCT
                'N/A' AS channel_id,  
                'N/A' AS channel_type,  
                'N/A' AS channel_description,  
                'sales_data_2' AS source
            FROM (SELECT DISTINCT 1 FROM sa_v_sales_data_fl.src_sales_fl) sub
        ) s
        WHERE NOT EXISTS (
            SELECT 1 
            FROM BL_3NF.CE_SALES_CHANNELS c
            WHERE c.Channel_SRC_ID = COALESCE(s.channel_id, 'N/A')
              AND c.SOURCE_Entity = CASE WHEN s.source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END
        )
    LOOP
        BEGIN
            INSERT INTO BL_3NF.CE_SALES_CHANNELS (
                Channel_SRC_ID,
                Channel_Type,
                Channel_Description,
                SOURCE_System,
                SOURCE_Entity,
                SOURCE_ID
            ) VALUES (
                rec.Channel_SRC_ID,
                rec.Channel_Type,
                rec.Channel_Description,
                rec.SOURCE_System,
                rec.SOURCE_Entity,
                rec.SOURCE_ID
            );
            
            -- Increment the row count for each successful insert
            v_rows_affected := v_rows_affected + 1;

        EXCEPTION WHEN OTHERS THEN
            -- Log any errors encountered
            RAISE NOTICE 'Error inserting sales channel %: %', rec.Channel_SRC_ID, SQLERRM;
            PERFORM BL_CL.insert_log('load_sales_channels', 0, 'ERROR', 'Error inserting sales channel ' || rec.Channel_SRC_ID || ': ' || SQLERRM);
        END;
    END LOOP;
    
    -- Log the end of the procedure with the number of rows affected
    PERFORM BL_CL.insert_log('load_sales_channels', v_rows_affected, 'SUCCESS', 'Procedure execution completed. Rows affected: ' || v_rows_affected);
    
    COMMIT;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_sales_channels()
    OWNER TO postgres;





CREATE OR REPLACE PROCEDURE bl_cl.load_states()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
    v_rows_affected INT := 0;
BEGIN
    -- Log procedure start
    PERFORM BL_CL.insert_log('load_states', 0, 'START', 'Procedure execution started.');

    FOR rec IN 
        SELECT 
            state AS State_SRC_ID,
            state AS State_Name,
            CASE
                WHEN source = 'sales_data_1' THEN 'SALES_DATA_1'
                ELSE 'SALES_DATA_2'
            END AS SOURCE_System,
            CASE 
                WHEN source = 'sales_data_1' THEN 'SRC_SALES_1'
                ELSE 'SRC_SALES_2'
            END AS SOURCE_Entity,
            CASE 
                WHEN source = 'sales_data_1' THEN '1'
                ELSE '2'
            END AS SOURCE_ID
        FROM (
            SELECT DISTINCT state, 'sales_data_1' AS source
            FROM sa_v_sales_data_wa.src_sales_wa
            WHERE state IS NOT NULL 

            UNION

            SELECT DISTINCT state, 'sales_data_2' AS source
            FROM sa_v_sales_data_fl.src_sales_fl
            WHERE state IS NOT NULL 
        ) s
        WHERE NOT EXISTS (
            SELECT 1 FROM BL_3NF.CE_STATES st
            WHERE st.State_SRC_ID = s.state
        )
    LOOP
        BEGIN
            -- Insert into CE_STATES
            INSERT INTO BL_3NF.CE_STATES (
                State_SRC_ID,
                State_Name,
                SOURCE_System,
                SOURCE_Entity,
                SOURCE_ID
            ) VALUES (
                rec.State_SRC_ID,
                rec.State_Name,
                rec.SOURCE_System,
                rec.SOURCE_Entity,
                rec.SOURCE_ID
            );

            -- Increment counter
            v_rows_affected := v_rows_affected + 1;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting state %: %', rec.State_Name, SQLERRM;
            PERFORM BL_CL.insert_log('load_states', 0, 'ERROR', 'Error inserting state ' || rec.State_Name || ': ' || SQLERRM);
        END;
    END LOOP;

    -- Log procedure completion
    PERFORM BL_CL.insert_log('load_states', v_rows_affected, 'SUCCESS', 'Procedure execution completed. Rows affected: ' || v_rows_affected);

    COMMIT;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_states()
OWNER TO postgres;



CREATE OR REPLACE PROCEDURE bl_cl.load_cities()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
    v_rows_affected INT := 0;
BEGIN
    -- Log procedure start
    PERFORM BL_CL.insert_log('load_cities', 0, 'START', 'Procedure execution started.');

    FOR rec IN 
        SELECT 
            city AS City_SRC_ID,
            city AS City_Name,
            st.State_ID,
            CASE
                WHEN source = 'sales_data_1' THEN 'SALES_DATA_1'
                ELSE 'SALES_DATA_2'
            END AS SOURCE_System,
            CASE 
                WHEN source = 'sales_data_1' THEN 'SRC_SALES_1'
                ELSE 'SRC_SALES_2'
            END AS SOURCE_Entity,
            CASE 
                WHEN source = 'sales_data_1' THEN '1'
                ELSE '2'
            END AS SOURCE_ID
        FROM (
            -- Extract distinct cities and states, removing NULL cities
            SELECT DISTINCT city, state, 'sales_data_1' AS source
            FROM sa_v_sales_data_wa.src_sales_wa
            WHERE city IS NOT NULL  

            UNION

            SELECT DISTINCT city, state, 'sales_data_2' AS source
            FROM sa_v_sales_data_fl.src_sales_fl
            WHERE city IS NOT NULL  
        ) s
    JOIN BL_3NF.CE_STATES st 
        ON st.State_Name = s.state
        AND st.SOURCE_System = CASE 
                                   WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
                                   ELSE 'SALES_DATA_2'
                               END
    WHERE NOT EXISTS (
        SELECT 1
        FROM BL_3NF.CE_CITIES c
        WHERE c.City_SRC_ID = s.city
        AND c.SOURCE_System = CASE 
                                  WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
                                  ELSE 'SALES_DATA_2'
                              END
    )
    LOOP
        BEGIN
            -- Insert new city record
            INSERT INTO BL_3NF.CE_CITIES (
                City_SRC_ID,
                City_Name,
                State_ID_FK,
                SOURCE_System,
                SOURCE_Entity,
                SOURCE_ID
            ) VALUES (
                rec.City_SRC_ID,
                rec.City_Name,
                rec.State_ID,
                rec.SOURCE_System,
                rec.SOURCE_Entity,
                rec.SOURCE_ID
            );

            -- Increment counter
            v_rows_affected := v_rows_affected + 1;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting city %: %', rec.City_Name, SQLERRM;
            PERFORM BL_CL.insert_log('load_cities', 0, 'ERROR', 'Error inserting city ' || rec.City_Name || ': ' || SQLERRM);
        END;
    END LOOP;

    -- Log procedure completion
    PERFORM BL_CL.insert_log('load_cities', v_rows_affected, 'SUCCESS', 'Procedure execution completed. Rows inserted: ' || v_rows_affected);

    COMMIT;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_cities()
OWNER TO postgres;


CREATE OR REPLACE PROCEDURE bl_cl.load_locations()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
    v_rows_affected INT := 0;
BEGIN
    -- Log procedure start
    PERFORM BL_CL.insert_log('load_locations', 0, 'START', 'Procedure execution started.');

    FOR rec IN 
        SELECT 
            COALESCE(NULLIF(CAST(postal_code AS INTEGER), NULL), -1) AS Location_Postal_Code_SRC_ID,
            c.City_ID,
            CASE
                WHEN source = 'sales_data_1' THEN 'SALES_DATA_1'
                ELSE 'SALES_DATA_2'
            END AS SOURCE_System,
            CASE 
                WHEN source = 'sales_data_1' THEN 'SRC_SALES_1'
                ELSE 'SRC_SALES_2'
            END AS SOURCE_Entity,
            CASE 
                WHEN source = 'sales_data_1' THEN '1'
                ELSE '2'
            END AS SOURCE_ID
        FROM (
            -- Extract distinct locations, filtering out NULL postal codes
            SELECT DISTINCT postal_code, city, 'sales_data_1' AS source
            FROM sa_v_sales_data_wa.src_sales_wa
            WHERE postal_code IS NOT NULL

            UNION

            SELECT DISTINCT postal_code, city, 'sales_data_2' AS source
            FROM sa_v_sales_data_fl.src_sales_fl
            WHERE postal_code IS NOT NULL
        ) s
    JOIN BL_3NF.CE_CITIES c 
        ON c.City_SRC_ID = s.city
        AND c.SOURCE_System = CASE 
                                 WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
                                 ELSE 'SALES_DATA_2'
                               END
    WHERE NOT EXISTS (
        -- Check for existing records
        SELECT 1
        FROM BL_3NF.CE_LOCATIONS l
        WHERE l.Location_Postal_Code_SRC_ID = COALESCE(NULLIF(CAST(s.postal_code AS INTEGER), NULL), -1)
          AND l.City_ID_FK = c.City_ID
          AND l.SOURCE_System = CASE 
                                  WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
                                  ELSE 'SALES_DATA_2'
                                END
    )
    LOOP
        BEGIN
            -- Insert new location record
            INSERT INTO BL_3NF.CE_LOCATIONS (
                Location_Postal_Code_SRC_ID,
                City_ID_FK,
                SOURCE_System,
                SOURCE_Entity,
                SOURCE_ID
            ) VALUES (
                rec.Location_Postal_Code_SRC_ID,  
                rec.City_ID,                      
                rec.SOURCE_System,                
                rec.SOURCE_Entity,                
                rec.SOURCE_ID                     
            );

            -- Increment row count
            v_rows_affected := v_rows_affected + 1;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting location %: %', rec.Location_Postal_Code_SRC_ID, SQLERRM;
            PERFORM BL_CL.insert_log('load_locations', 0, 'ERROR', 'Error inserting location ' || rec.Location_Postal_Code_SRC_ID || ': ' || SQLERRM);
        END;
    END LOOP;

    -- Log procedure completion
    PERFORM BL_CL.insert_log('load_locations', v_rows_affected, 'SUCCESS', 'Procedure execution completed. Rows inserted: ' || v_rows_affected);

    COMMIT;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_locations()
OWNER TO postgres;



CREATE OR REPLACE PROCEDURE bl_cl.load_customers()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
    v_rows_affected INT := 0;
BEGIN
    -- Log procedure start
    PERFORM BL_CL.insert_log('load_customers', 0, 'START', 'Procedure execution started.');

    FOR rec IN 
        -- Your current SELECT logic to pull data
        SELECT 
            COALESCE(customer_id::INT, -1) AS Customer_SRC_ID,
            COALESCE(customer_passport, 'N/A') AS Customer_Passport,
            COALESCE(customer_name, 'N/A') AS Customer_Name,
            COALESCE(gender, 'N/A') AS Customer_Gender,
            COALESCE(NULLIF(NULLIF(customer_age, ''), 'NULL')::INT, -1) AS Customer_Age,
            CASE 
                WHEN source = 'sales_data_1' THEN 'SALES_DATA_1'
                ELSE 'SALES_DATA_2'
            END AS SOURCE_System,
            CASE 
                WHEN source = 'sales_data_1' THEN 'SRC_SALES_1'
                ELSE 'SRC_SALES_2'
            END AS SOURCE_Entity,
            CASE 
                WHEN source = 'sales_data_1' THEN '1'
                ELSE '2'
            END AS SOURCE_ID
        FROM (
            -- First source: sa_v_sales_data_wa.src_sales_wa (with passport and gender)
            SELECT 
                NULL AS customer_id, 
                customer_passport, 
                customer_name, 
                gender, 
                NULL AS customer_age,
                'sales_data_1' AS source
            FROM sa_v_sales_data_wa.src_sales_wa
            GROUP BY customer_passport, customer_name, gender  -- Grouping duplicates
            
            UNION ALL
            
            -- Second source: sa_v_sales_data_fl.src_sales_fl (with customer_id and customer_age)
            SELECT 
                customer_id, 
                NULL AS customer_passport,  
                customer_name, 
                NULL AS gender,  
                customer_age, 
                'sales_data_2' AS source
            FROM sa_v_sales_data_fl.src_sales_fl
        ) s
        WHERE NOT EXISTS (
            -- Check for duplicates in BL_3NF
            SELECT 1
            FROM BL_3NF.CE_CUSTOMERS c
            WHERE 
                (s.source = 'sales_data_1' 
                 AND c.Customer_Passport = COALESCE(s.customer_passport, 'N/A') 
                 AND c.Customer_Name = COALESCE(s.customer_name, 'N/A')
                 AND c.Customer_Gender = COALESCE(s.gender, 'N/A'))
                
                OR
                
                (s.source = 'sales_data_2' 
                 AND c.Customer_SRC_ID = COALESCE(s.customer_id::INT, -1) 
                 AND c.Customer_Name = COALESCE(s.customer_name, 'N/A') 
                 AND c.Customer_Age = COALESCE(s.customer_age::INT, -1))
            
            AND c.SOURCE_System = CASE 
                WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
                ELSE 'SALES_DATA_2'
            END
        )
    LOOP
        BEGIN
            INSERT INTO BL_3NF.CE_CUSTOMERS (
                Customer_SRC_ID,
                Customer_Passport,
                Customer_Name,
                Customer_Gender,
                Customer_Age,
                SOURCE_System,
                SOURCE_Entity,
                SOURCE_ID
            ) VALUES (
                rec.Customer_SRC_ID,
                rec.Customer_Passport,
                rec.Customer_Name,
                rec.Customer_Gender,
                rec.Customer_Age,
                rec.SOURCE_System,
                rec.SOURCE_Entity,
                rec.SOURCE_ID
            );

            -- Increment row count
            v_rows_affected := v_rows_affected + 1;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting customer %: %', rec.Customer_Name, SQLERRM;
            PERFORM BL_CL.insert_log('load_customers', 0, 'ERROR', 'Error inserting customer ' || rec.Customer_Name || ': ' || SQLERRM);
        END;
    END LOOP;

    -- Log procedure completion
    PERFORM BL_CL.insert_log('load_customers', v_rows_affected, 'SUCCESS', 'Procedure execution completed. Rows inserted: ' || v_rows_affected);

    COMMIT;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_customers()
OWNER TO postgres;


CREATE OR REPLACE PROCEDURE bl_cl.load_producers()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
    v_rows_affected INT := 0;
BEGIN
    -- Log procedure start
    PERFORM BL_CL.insert_log('load_producers', 0, 'START', 'Procedure execution started.');

    FOR rec IN 
        SELECT 
            COALESCE(make, 'N/A') AS Producer_Name, 
            COALESCE(make, 'N/A') AS Producer_SRC_ID, 
            CASE WHEN source = 'sales_data_1' THEN 'SALES_DATA_1' ELSE 'SALES_DATA_2' END AS SOURCE_System,
            CASE WHEN source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END AS SOURCE_Entity,
            CASE WHEN source = 'sales_data_1' THEN '1' ELSE '2' END AS SOURCE_ID
        FROM (
            SELECT DISTINCT make, 'sales_data_1' AS source 
            FROM sa_v_sales_data_wa.src_sales_wa
            WHERE make IS NOT NULL  -- Exclude NULL makes
            UNION
            SELECT DISTINCT make, 'sales_data_2' AS source 
            FROM sa_v_sales_data_fl.src_sales_fl
            WHERE make IS NOT NULL  -- Exclude NULL makes
        ) AS makes
    WHERE NOT EXISTS (
        SELECT 1
        FROM BL_3NF.CE_PRODUCERS p
        WHERE p.Producer_Name = makes.make
    )
    LOOP
        BEGIN
            -- Skip if Producer_Name is 'N/A'
            IF rec.Producer_Name <> 'N/A' THEN
                INSERT INTO BL_3NF.CE_PRODUCERS (
                    Producer_Name,
                    Producer_SRC_ID, 
                    SOURCE_System,
                    SOURCE_Entity,
                    SOURCE_ID
                ) VALUES (
                    rec.Producer_Name, 
                    rec.Producer_SRC_ID, 
                    rec.SOURCE_System,
                    rec.SOURCE_Entity,
                    rec.SOURCE_ID
                );

                -- Increment row count
                v_rows_affected := v_rows_affected + 1;
            END IF;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting producer %: %', rec.Producer_Name, SQLERRM;
            PERFORM BL_CL.insert_log('load_producers', 0, 'ERROR', 'Error inserting producer ' || rec.Producer_Name || ': ' || SQLERRM);
        END;
    END LOOP;

    -- Log procedure completion
    PERFORM BL_CL.insert_log('load_producers', v_rows_affected, 'SUCCESS', 'Procedure execution completed. Rows inserted: ' || v_rows_affected);

    COMMIT;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_producers()
OWNER TO postgres;



CREATE OR REPLACE PROCEDURE bl_cl.load_models()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
    v_rows_affected INT := 0;
BEGIN
    -- Log procedure start
    PERFORM BL_CL.insert_log('load_models', 0, 'START', 'Procedure execution started.');

    FOR rec IN 
        SELECT 
            vin AS Model_SRC_ID,  
            COALESCE(model, 'N/A') AS Model_Name,
            COALESCE(electric_vehicle_type, 'N/A') AS Model_Electric_Type,  
            electric_range::INT AS Model_Electric_Range,  
            cafv_eligibility AS Model_Type_CAFV,  
            p.Producer_ID AS Producer_ID_FK,  
            CASE WHEN source = 'sales_data_1' THEN 'SALES_DATA_1' ELSE 'SALES_DATA_2' END AS SOURCE_System,
            CASE WHEN source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END AS SOURCE_Entity,
            CASE WHEN source = 'sales_data_1' THEN '1' ELSE '2' END AS SOURCE_ID
        FROM (
            SELECT vin, model, electric_vehicle_type, electric_range, cafv_eligibility, make, 'sales_data_1' AS source
            FROM sa_v_sales_data_wa.src_sales_wa
            UNION
            SELECT vin, model, electric_vehicle_type, electric_range, cafv_eligibility, make, 'sales_data_2' AS source
            FROM sa_v_sales_data_fl.src_sales_fl
        ) AS models
    JOIN BL_3NF.CE_PRODUCERS p 
        ON p.Producer_Name = models.make 
        AND p.SOURCE_System = CASE 
            WHEN models.source = 'sales_data_1' THEN 'SALES_DATA_1' 
            ELSE 'SALES_DATA_2' 
        END  
    WHERE NOT EXISTS (
        SELECT 1
        FROM BL_3NF.CE_MODELS m
        WHERE m.Model_SRC_ID = models.vin
    )
    LOOP
        BEGIN
            -- Skip if Model_Name is 'N/A'
            IF rec.Model_Name <> 'N/A' THEN
                INSERT INTO BL_3NF.CE_MODELS (
                    Model_SRC_ID,
                    Model_Name,
                    Model_Electric_Type,
                    Model_Electric_Range,
                    Model_Type_CAFV,
                    Producer_ID_FK,
                    SOURCE_System,
                    SOURCE_Entity,
                    SOURCE_ID
                ) VALUES (
                    rec.Model_SRC_ID,
                    rec.Model_Name,
                    rec.Model_Electric_Type,
                    rec.Model_Electric_Range,
                    rec.Model_Type_CAFV,
                    rec.Producer_ID_FK,
                    rec.SOURCE_System,
                    rec.SOURCE_Entity,
                    rec.SOURCE_ID
                );

                -- Increment row count
                v_rows_affected := v_rows_affected + 1;
            END IF;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting model %: %', rec.Model_Name, SQLERRM;
            PERFORM BL_CL.insert_log('load_models', 0, 'ERROR', 'Error inserting model ' || rec.Model_Name || ': ' || SQLERRM);
        END;
    END LOOP;

    -- Log procedure completion
    PERFORM BL_CL.insert_log('load_models', v_rows_affected, 'SUCCESS', 'Procedure execution completed. Rows inserted: ' || v_rows_affected);

    COMMIT;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_models()
OWNER TO postgres;



CREATE OR REPLACE PROCEDURE bl_cl.load_vehicles()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
    v_rows_affected INT := 0;
BEGIN
    -- Log procedure start
    PERFORM BL_CL.insert_log('load_vehicles', 0, 'START', 'Procedure execution started.');

    FOR rec IN 
        SELECT DISTINCT
            vin AS VIN_SRC_ID,  
            COALESCE(color, 'N/A') AS Vehile_Color,  
            COALESCE(transmission, 'N/A') AS Vehile_Transmission_Type,  
            model_year::INT AS Vehile_Year,  
            m.Model_ID AS Model_ID_FK,  
            CASE WHEN source = 'sales_data_1' THEN 'SALES_DATA_1' ELSE 'SALES_DATA_2' END AS SOURCE_System,
            CASE WHEN source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END AS SOURCE_Entity,
            CASE WHEN source = 'sales_data_1' THEN '1' ELSE '2' END AS SOURCE_ID
        FROM (
            SELECT vin, 
                   NULL AS color,  
                   NULL AS transmission,  
                   model_year, 
                   'sales_data_1' AS source
            FROM sa_v_sales_data_wa.src_sales_wa
            UNION
            SELECT vin, 
                   color, 
                   transmission, 
                   model_year, 
                   'sales_data_2' AS source
            FROM sa_v_sales_data_fl.src_sales_fl
        ) AS vehicles
    JOIN BL_3NF.CE_MODELS m ON m.Model_SRC_ID = vehicles.vin  
    WHERE NOT EXISTS (
        SELECT 1
        FROM BL_3NF.CE_VEHICLES v
        WHERE v.VIN_SRC_ID = vehicles.vin
          AND v.Model_ID_FK = m.Model_ID
          AND v.SOURCE_System = CASE 
              WHEN vehicles.source = 'sales_data_1' THEN 'SALES_DATA_1' 
              ELSE 'SALES_DATA_2' 
          END
    )
    LOOP
        BEGIN
            -- Skip if VIN_SRC_ID is 'N/A'
            IF rec.VIN_SRC_ID IS NOT NULL THEN
                INSERT INTO BL_3NF.CE_VEHICLES (
                    VIN_SRC_ID,
                    Vehile_Color,
                    Vehile_Transmission_Type,
                    Vehile_Year,
                    Model_ID_FK,
                    SOURCE_System,
                    SOURCE_Entity,
                    SOURCE_ID
                ) VALUES (
                    rec.VIN_SRC_ID,  
                    rec.Vehile_Color,  
                    rec.Vehile_Transmission_Type,  
                    rec.Vehile_Year,  
                    rec.Model_ID_FK,  
                    rec.SOURCE_System,
                    rec.SOURCE_Entity,
                    rec.SOURCE_ID
                );

                -- Increment row count
                v_rows_affected := v_rows_affected + 1;
            END IF;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting vehicle %: %', rec.VIN_SRC_ID, SQLERRM;
            PERFORM BL_CL.insert_log('load_vehicles', 0, 'ERROR', 'Error inserting vehicle ' || rec.VIN_SRC_ID || ': ' || SQLERRM);
        END;
    END LOOP;

    -- Log procedure completion
    PERFORM BL_CL.insert_log('load_vehicles', v_rows_affected, 'SUCCESS', 'Procedure execution completed. Rows inserted: ' || v_rows_affected);

    COMMIT;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_vehicles()
OWNER TO postgres;

-- PROCEDURE: bl_cl.load_employees_scd()

-- DROP PROCEDURE IF EXISTS bl_cl.load_employees_scd();

CREATE OR REPLACE PROCEDURE bl_cl.load_employees_scd(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_rows_affected INT := 0;  -- Initialize a counter for rows affected
    v_affected_rows RECORD;    -- To hold rows returned from MERGE statement
BEGIN
    -- Log the start of the procedure
    PERFORM BL_CL.insert_log('load_employees_scd', 0, 'START', 'Procedure execution started.');

    -- Create a temporary table to hold the source data
    CREATE TEMP TABLE temp_source_data AS
    WITH source_data AS (
        SELECT 
            COALESCE(employee_id, 'N/A') AS Employee_SRC_ID,  
            COALESCE(employee_name, 'N/A') AS Employee_Name,  
            COALESCE(employee_email, 'N/A') AS Employee_Email,  
            COALESCE(employee_phone, 'N/A') AS Employee_Phone,  
            CURRENT_DATE AS START_DT,  
            NULL::DATE AS END_DT,  
            TRUE AS IS_ACTIVE,  
            CASE 
                WHEN source = 'sales_data_1' THEN 'SALES_DATA_1' 
                ELSE 'SALES_DATA_2' 
            END AS SOURCE_System,
            CASE 
                WHEN source = 'sales_data_1' THEN 'SRC_SALES_1' 
                ELSE 'SRC_SALES_2' 
            END AS SOURCE_Entity,
            CASE 
                WHEN source = 'sales_data_1' THEN '1' 
                ELSE '2' 
            END AS SOURCE_ID
        FROM (
            SELECT DISTINCT employee_id, employee_name, NULL AS employee_email, employee_phone, 'sales_data_1' AS source
            FROM sa_v_sales_data_wa.src_sales_wa
            UNION
            SELECT DISTINCT employee_id, employee_name, employee_email, NULL AS employee_phone, 'sales_data_2' AS source
            FROM sa_v_sales_data_fl.src_sales_fl
        ) s
    )
    SELECT * FROM source_data;

    -- Use MERGE to perform both INSERT and UPDATE operations in a single statement
    -- Capture the affected rows using RETURNING
    FOR v_affected_rows IN
        MERGE INTO BL_3NF.CE_EMPLOYEES_SCD AS target
        USING temp_source_data AS source
        ON target.Employee_SRC_ID = source.Employee_SRC_ID
           AND target.SOURCE_Entity = source.SOURCE_Entity
           AND target.IS_ACTIVE = TRUE
        WHEN MATCHED AND (
                target.Employee_Name != source.Employee_Name
            OR target.Employee_Email != source.Employee_Email
            OR target.Employee_Phone != source.Employee_Phone
        ) THEN 
            UPDATE SET 
                END_DT = CURRENT_DATE,
                IS_ACTIVE = FALSE,
		TA_UPDATE_DT = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (
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
            ) VALUES (
                source.Employee_SRC_ID,
                source.Employee_Name,
                source.Employee_Email,
                source.Employee_Phone,
                source.START_DT,
                NULL::DATE,
                source.IS_ACTIVE,
                source.SOURCE_System,
                source.SOURCE_Entity,
                source.SOURCE_ID
            )
        RETURNING * -- Get the affected rows
    LOOP
	RAISE NOTICE 'Inserted Row: %', v_affected_rows;
        v_rows_affected := v_rows_affected + 1;
    END LOOP;

    -- Log the number of rows affected
    PERFORM BL_CL.insert_log('load_employees_scd', v_rows_affected, 'SUCCESS', 'Procedure execution completed. Rows affected: ' || v_rows_affected);

    -- Clean up: Drop the temporary table
    DROP TABLE IF EXISTS temp_source_data;

    COMMIT;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_employees_scd()
    OWNER TO postgres;




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







-- CALL bl_cl.load_payment_methods();

-- CALL bl_cl.load_sales_channels();

-- CALL BL_CL.load_states();
-- CALL BL_CL.load_cities();
-- CALL BL_CL.load_locations();

-- CALL BL_CL.load_customers();

-- CALL BL_CL.load_producers();
-- CALL BL_CL.load_models();
-- CALL BL_CL.load_vehicles();

-- CALL bl_cl.load_employees_scd();

-- CALL BL_CL.load_transactions_sales_data_1();
-- CALL BL_CL.load_transactions_sales_data_2();