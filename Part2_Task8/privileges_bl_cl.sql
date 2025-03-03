DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bl_cl') THEN
        CREATE ROLE bl_cl;
    END IF;
END $$;

GRANT EXECUTE ON PROCEDURE bl_cl.load_dim_locations TO BL_CL;
GRANT EXECUTE ON PROCEDURE bl_cl.load_dim_customers TO BL_CL;
GRANT EXECUTE ON PROCEDURE bl_cl.load_dim_employees_scd TO BL_CL;
GRANT EXECUTE ON PROCEDURE bl_cl.load_dim_sales_channels TO BL_CL;
GRANT EXECUTE ON PROCEDURE bl_cl.load_dim_vehicles TO BL_CL;
GRANT EXECUTE ON PROCEDURE bl_cl.load_fact_transactions TO BL_CL;
GRANT EXECUTE ON FUNCTION bl_cl.insert_dates TO BL_CL;
GRANT EXECUTE ON FUNCTION bl_cl.insert_log TO BL_CL;

GRANT SELECT, INSERT, UPDATE, DELETE ON BL_DM.DIM_LOCATIONS TO BL_CL;
GRANT SELECT, INSERT, UPDATE, DELETE ON BL_DM.DIM_SALES_CHANNELS TO BL_CL;
GRANT SELECT, INSERT, UPDATE, DELETE ON BL_DM.DIM_CUSTOMERS TO BL_CL;
GRANT SELECT, INSERT, UPDATE, DELETE ON BL_DM.DIM_DATES TO BL_CL;
GRANT SELECT, INSERT, UPDATE, DELETE ON BL_DM.DIM_EMPLOYEES_SCD TO BL_CL;
GRANT SELECT, INSERT, UPDATE, DELETE ON BL_DM.DIM_VEHICLES TO BL_CL;
GRANT SELECT, INSERT, UPDATE, DELETE ON BL_DM.FACT_TRANSACTIONS TO BL_CL;

-- Just for cheking
-- SELECT grantee, routine_name, privilege_type 
-- FROM information_schema.role_routine_grants 
-- WHERE grantee = 'bl_cl';

-- SELECT grantee, table_schema, table_name, privilege_type 
-- FROM information_schema.role_table_grants 
-- WHERE grantee = 'bl_cl';



