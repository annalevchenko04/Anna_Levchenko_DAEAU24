CREATE OR REPLACE PROCEDURE bl_cl.load_employees_scd(p_employee_ids TEXT[])
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
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
        WHERE COALESCE(employee_id, 'N/A') = ANY(p_employee_ids)  -- Filter specific employees
    LOOP
        BEGIN
            -- Check if the record exists with the same data
            IF NOT EXISTS (
                SELECT 1 FROM BL_3NF.CE_EMPLOYEES_SCD e
                WHERE e.Employee_SRC_ID = rec.Employee_SRC_ID
                  AND e.SOURCE_Entity = rec.SOURCE_Entity
                  AND e.IS_ACTIVE = TRUE
                  AND e.Employee_Name = rec.Employee_Name
                  AND e.Employee_Email IS NOT DISTINCT FROM rec.Employee_Email
                  AND e.Employee_Phone IS NOT DISTINCT FROM rec.Employee_Phone
            ) THEN
                -- If a previous version exists, expire it
                IF EXISTS (
                    SELECT 1 FROM BL_3NF.CE_EMPLOYEES_SCD e
                    WHERE e.Employee_SRC_ID = rec.Employee_SRC_ID
                      AND e.SOURCE_Entity = rec.SOURCE_Entity
                      AND e.IS_ACTIVE = TRUE
                ) THEN
                    UPDATE BL_3NF.CE_EMPLOYEES_SCD
                    SET END_DT = CURRENT_DATE - INTERVAL '1 day',
                        IS_ACTIVE = FALSE
                    WHERE Employee_SRC_ID = rec.Employee_SRC_ID
                      AND SOURCE_Entity = rec.SOURCE_Entity
                      AND IS_ACTIVE = TRUE;
                END IF;

                -- Insert new active record only if there is a change
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
                    NULL,  -- Set END_DT to NULL for active record
                    rec.IS_ACTIVE,
                    rec.SOURCE_System,
                    rec.SOURCE_Entity,
                    rec.SOURCE_ID
                );
            END IF;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error processing employee %: %', rec.Employee_Name, SQLERRM;
        END;
    END LOOP;
    COMMIT;
END;
$BODY$;

ALTER PROCEDURE bl_cl.load_employees_scd(TEXT[])
OWNER TO postgres;


CALL bl_cl.load_employees_scd(ARRAY['E01', 'E02', 'E03']);