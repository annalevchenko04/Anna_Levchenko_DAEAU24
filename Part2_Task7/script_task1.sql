
CREATE OR REPLACE PROCEDURE bl_cl.load_payment_methods(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        -- Your current SELECT logic to pull data for CE_PAYMENT_METHODS
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
            -- Ensure 'N/A' row is included only once for sales_data_1
            SELECT * FROM (
	        	SELECT DISTINCT 
	            	'N/A' AS payment_method,  
	            	'N/A' AS payment_method_name,  
	            	'sales_data_1' AS source
	       		FROM sa_v_sales_data_wa.src_sales_wa
	        	LIMIT 1
	    	) AS subquery1

            UNION

            -- Select unique payment methods from sales_data_2
            SELECT DISTINCT 
                payment_method,  
                payment_method AS payment_method_name,  
                'sales_data_2' AS source
            FROM sa_v_sales_data_fl.src_sales_fl
            WHERE payment_method IS NOT NULL
        ) s
        WHERE NOT EXISTS (
            -- Check for duplicates in BL_3NF.CE_PAYMENT_METHODS
            SELECT 1 
            FROM BL_3NF.CE_PAYMENT_METHODS p
            WHERE p.Payment_Method_SRC_ID = COALESCE(s.payment_method, 'N/A')
              AND p.SOURCE_System = CASE WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1' ELSE 'SALES_DATA_2' END
              AND p.SOURCE_Entity = CASE WHEN s.source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END
        )
    LOOP
        BEGIN
            -- Insert data into CE_PAYMENT_METHODS
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

            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Error inserting payment method %: %', rec.Payment_Method_SRC_ID, SQLERRM;
        END;
    END LOOP;
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_payment_methods()
    OWNER TO postgres;




CREATE OR REPLACE PROCEDURE bl_cl.load_sales_channels(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        -- Your current SELECT logic to pull data for CE_SALES_CHANNELS
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
            -- Data from sales_data_1 (has the channel columns)
            SELECT DISTINCT
                channel_id,  
                channel_type,  
                channel_description,  
                'sales_data_1' AS source
            FROM sa_v_sales_data_wa.src_sales_wa

            UNION

            -- Data from sales_data_2 (insert 'N/A' since these columns don't exist)
            SELECT DISTINCT
                'N/A' AS channel_id,  
                'N/A' AS channel_type,  
                'N/A' AS channel_description,  
                'sales_data_2' AS source
            FROM (SELECT DISTINCT 1 FROM sa_v_sales_data_fl.src_sales_fl) sub
        ) s
        WHERE NOT EXISTS (
            -- Check for duplicates in BL_3NF.CE_SALES_CHANNELS
            SELECT 1 
            FROM BL_3NF.CE_SALES_CHANNELS c
            WHERE c.Channel_SRC_ID = COALESCE(s.channel_id, 'N/A')
              AND c.SOURCE_Entity = CASE WHEN s.source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END
        )
    LOOP
        BEGIN
            -- Insert data into CE_SALES_CHANNELS
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

            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Error inserting sales channel %: %', rec.Channel_SRC_ID, SQLERRM;
        END;
    END LOOP;
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_sales_channels()
    OWNER TO postgres;





CREATE OR REPLACE PROCEDURE bl_cl.load_employees_scd(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        -- Your current SELECT logic to pull data for CE_EMPLOYEES_SCD
        SELECT 
            COALESCE(employee_id, 'N/A') AS Employee_SRC_ID,  
            COALESCE(employee_name, 'N/A') AS Employee_Name,  
            COALESCE(employee_email, 'N/A') AS Employee_Email,  
            COALESCE(employee_phone, 'N/A') AS Employee_Phone,  
            CURRENT_DATE AS START_DT,  
            CAST(NULL AS DATE) AS END_DT,  
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
            -- Data from sales_data_1
            SELECT DISTINCT
                employee_id,
                employee_name,
                NULL AS employee_email,  
                employee_phone,
                'sales_data_1' AS source
            FROM sa_v_sales_data_wa.src_sales_wa

            UNION

            -- Data from sales_data_2
            SELECT DISTINCT
                employee_id,
                employee_name,
                employee_email,
                NULL AS employee_phone,  
                'sales_data_2' AS source
            FROM sa_v_sales_data_fl.src_sales_fl
        ) s
        WHERE NOT EXISTS (
            -- Check for duplicates in BL_3NF.CE_EMPLOYEES_SCD
            SELECT 1 
            FROM BL_3NF.CE_EMPLOYEES_SCD e
            WHERE e.Employee_SRC_ID = COALESCE(s.employee_id, 'N/A')  
              AND e.SOURCE_Entity = CASE WHEN s.source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END
              AND e.IS_ACTIVE = TRUE
        )
    LOOP
        BEGIN
            -- Insert data into CE_EMPLOYEES_SCD
            INSERT INTO BL_3NF.CE_EMPLOYEES_SCD (
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
                rec.Employee_SRC_ID,
                rec.Employee_Name,
                rec.Employee_Email,
                rec.Employee_Phone,
                rec.START_DT,
                rec.END_DT,
                rec.IS_ACTIVE,
                rec.SOURCE_System,
                rec.SOURCE_Entity,
                rec.SOURCE_ID
            );

            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Error inserting employee %: %', rec.Employee_Name, SQLERRM;
        END;
    END LOOP;
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_employees_scd()
    OWNER TO postgres;


CREATE OR REPLACE PROCEDURE bl_cl.load_states(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT 
            COALESCE(state, 'N/A') AS State_SRC_ID,
            COALESCE(state, 'N/A') AS State_Name,
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
            SELECT state, 'sales_data_1' AS source
            FROM sa_v_sales_data_wa.src_sales_wa
            UNION
            SELECT state, 'sales_data_2' AS source
            FROM sa_v_sales_data_fl.src_sales_fl
        ) s
        WHERE NOT EXISTS (
            SELECT 1
            FROM BL_3NF.CE_STATES st
            WHERE st.State_SRC_ID = s.state
        )
    LOOP
        BEGIN
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
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting state %: %', rec.State_Name, SQLERRM;
        END;
    END LOOP;
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_states()
    OWNER TO postgres;



CREATE OR REPLACE PROCEDURE bl_cl.load_cities(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT 
            COALESCE(city, 'N/A') AS City_SRC_ID,
            COALESCE(city, 'N/A') AS City_Name,
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
            SELECT city, state, 'sales_data_1' AS source
            FROM sa_v_sales_data_wa.src_sales_wa
            UNION
            SELECT city, state, 'sales_data_2' AS source
            FROM sa_v_sales_data_fl.src_sales_fl
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
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting city %: %', rec.City_Name, SQLERRM;
        END;
    END LOOP;
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_cities()
    OWNER TO postgres;



CREATE OR REPLACE PROCEDURE bl_cl.load_locations(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
BEGIN
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
            SELECT postal_code, city, 'sales_data_1' AS source
            FROM sa_v_sales_data_wa.src_sales_wa
            UNION
            SELECT postal_code, city, 'sales_data_2' AS source
            FROM sa_v_sales_data_fl.src_sales_fl
        ) s
    JOIN BL_3NF.CE_CITIES c 
        ON c.City_SRC_ID = s.city
        AND c.SOURCE_System = CASE 
                                 WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
                                 ELSE 'SALES_DATA_2'
                               END
    WHERE NOT EXISTS (
        SELECT 1
        FROM BL_3NF.CE_LOCATIONS l
        WHERE l.Location_Postal_Code_SRC_ID = CAST(s.postal_code AS INTEGER)
          AND l.City_ID_FK = c.City_ID
          AND l.SOURCE_System = CASE 
                                  WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
                                  ELSE 'SALES_DATA_2'
                                END
    )
    LOOP
        BEGIN
            -- Insert into CE_LOCATIONS
            INSERT INTO BL_3NF.CE_LOCATIONS (
                Location_Postal_Code_SRC_ID,
                City_ID_FK,
                SOURCE_System,
                SOURCE_Entity,
                SOURCE_ID
            ) VALUES (
                rec.Location_Postal_Code_SRC_ID,  -- This is now correct
                rec.City_ID,                      -- This is now correct
                rec.SOURCE_System,                -- This is now correct
                rec.SOURCE_Entity,                -- This is now correct
                rec.SOURCE_ID                     -- This is now correct
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting location %: %', rec.Location_Postal_Code_SRC_ID, SQLERRM;
        END;
    END LOOP;
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_locations()
    OWNER TO postgres;



CREATE OR REPLACE PROCEDURE bl_cl.load_customers(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
BEGIN
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

            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Error inserting customer %: %', rec.Customer_Name, SQLERRM;
        END;
    END LOOP;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_customers()
    OWNER TO postgres;



CREATE OR REPLACE PROCEDURE bl_cl.load_producers(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
BEGIN
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
            UNION
            SELECT DISTINCT make, 'sales_data_2' AS source 
            FROM sa_v_sales_data_fl.src_sales_fl
        ) AS makes
    WHERE NOT EXISTS (
        SELECT 1
        FROM BL_3NF.CE_PRODUCERS p
        WHERE p.Producer_Name = makes.make
    )
    LOOP
        BEGIN
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
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting producer %: %', rec.Producer_Name, SQLERRM;
        END;
    END LOOP;
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_producers()
    OWNER TO postgres;




CREATE OR REPLACE PROCEDURE bl_cl.load_models(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
BEGIN
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
    JOIN BL_3NF.CE_PRODUCERS p ON p.Producer_Name = models.make  
    WHERE NOT EXISTS (
        SELECT 1
        FROM BL_3NF.CE_MODELS m
        WHERE m.Model_SRC_ID = models.vin
    )
    LOOP
        BEGIN
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
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting model %: %', rec.Model_Name, SQLERRM;
        END;
    END LOOP;
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_models()
    OWNER TO postgres;




CREATE OR REPLACE PROCEDURE bl_cl.load_vehicles(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
BEGIN
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
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting vehicle %: %', rec.VIN_SRC_ID, SQLERRM;
        END;
    END LOOP;
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_vehicles()
    OWNER TO postgres;







CREATE OR REPLACE PROCEDURE bl_cl.load_transactions_sales_data_1(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
BEGIN
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
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting transaction %: %', rec.Transaction_SRC_ID, SQLERRM;
        END;
    END LOOP;
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_transactions_sales_data_1()
    OWNER TO postgres; 



CREATE OR REPLACE PROCEDURE bl_cl.load_transactions_sales_data_2(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
BEGIN
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
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error inserting transaction %: %', rec.Transaction_SRC_ID, SQLERRM;
        END;
    END LOOP;
    COMMIT;
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_transactions_sales_data_2()
    OWNER TO postgres;


-- CALL bl_cl.load_payment_methods();

-- CALL bl_cl.load_sales_channels();

-- CALL bl_cl.load_employees_scd();

-- CALL BL_CL.load_states();
-- CALL BL_CL.load_cities();
-- CALL BL_CL.load_locations();

-- CALL BL_CL.load_customers();

-- CALL BL_CL.load_producers();
-- CALL BL_CL.load_models();
-- CALL BL_CL.load_vehicles();

-- CALL BL_CL.load_transactions_sales_data_1();
-- CALL BL_CL.load_transactions_sales_data_2();


