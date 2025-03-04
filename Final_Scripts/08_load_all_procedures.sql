-- PROCEDURE: bl_cl.load_all_data()

-- DROP PROCEDURE IF EXISTS bl_cl.load_all_data();

CREATE OR REPLACE PROCEDURE bl_cl.load_all_data(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Load Data for BL_3NF and BL_DM in the correct order
    
    -- Load payment methods
    CALL bl_cl.load_payment_methods();

    -- Load sales channels
    CALL bl_cl.load_sales_channels();

    -- Load states and cities
    CALL BL_CL.load_states();
    CALL BL_CL.load_cities();
    CALL BL_CL.load_locations();

    -- Load customers
    CALL BL_CL.load_customers();

    -- Load producers and models
    CALL BL_CL.load_producers();
    CALL BL_CL.load_models();

    -- Load vehicles
    CALL BL_CL.load_vehicles();

    -- Load employee data (SCD)
    CALL bl_cl.load_employees_scd();
    CALL bl_cl.load_employees_scd();

    -- Load transaction data from sales sources
    CALL BL_CL.load_transactions_sales_data_1();
    CALL BL_CL.load_transactions_sales_data_2();

    -- Load dimension tables
    CALL bl_cl.load_dim_customers();
    CALL bl_cl.load_dim_locations();
    CALL bl_cl.load_dim_vehicles();
    CALL bl_cl.load_dim_sales_channels();
    CALL bl_cl.load_dim_employees_scd();

    -- Load fact table for transactions
    CALL BL_CL.load_fact_transactions();

    -- Optionally, log completion message or success status
    RAISE NOTICE 'All procedures executed successfully.';
END;
$BODY$;
ALTER PROCEDURE bl_cl.load_all_data()
    OWNER TO postgres;


--CALL bl_cl.load_all_data();
