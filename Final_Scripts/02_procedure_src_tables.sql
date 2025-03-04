CREATE OR REPLACE PROCEDURE public.create_and_populate_sales_data()
LANGUAGE plpgsql
AS $$
BEGIN

-- Source table for WA sales data
DROP TABLE IF EXISTS sa_v_sales_data_wa.src_sales_wa;

CREATE TABLE IF NOT EXISTS sa_v_sales_data_wa.src_sales_wa (
    vin VARCHAR(1000),
    city VARCHAR(1000),
    state VARCHAR(1000),
    postal_code VARCHAR(1000),
    model_year VARCHAR(1000),
    make VARCHAR(1000),
    model VARCHAR(1000),
    electric_vehicle_type VARCHAR(1000),
    cafv_eligibility VARCHAR(1000),
    electric_range VARCHAR(1000),
    transactionid VARCHAR(1000),
    selling_price VARCHAR(1000),
    date VARCHAR(1000),
    customer_passport VARCHAR(1000),
    customer_name VARCHAR(1000),
    gender VARCHAR(1000),
    employee_id VARCHAR(1000),
    employee_name VARCHAR(1000),
    employee_phone VARCHAR(1000),
    channel_id VARCHAR(1000),
    channel_type VARCHAR(1000),
    channel_description VARCHAR(1000)
);

-- Insert WA data into source table with deduplication
-- Insert WA data into src_sales_wa only if a row with the same values for all columns doesn't already exist
INSERT INTO sa_v_sales_data_wa.src_sales_wa
SELECT 
    vin::VARCHAR(1000),
    city::VARCHAR(1000),
    state::VARCHAR(1000),
    postal_code::VARCHAR(1000),
    model_year::VARCHAR(1000),
    make::VARCHAR(1000),
    model::VARCHAR(1000),
    electric_vehicle_type::VARCHAR(1000),
    cafv_eligibility::VARCHAR(1000),
    electric_range::VARCHAR(1000),
    transactionid::VARCHAR(1000),
    selling_price::VARCHAR(1000),
    date::VARCHAR(1000),
    customer_passport::VARCHAR(1000),
    customer_name::VARCHAR(1000),
    gender::VARCHAR(1000),
    employee_id::VARCHAR(1000),
    employee_name::VARCHAR(1000),
    employee_phone::VARCHAR(1000),
    channel_id::VARCHAR(1000),
    channel_type::VARCHAR(1000),
    channel_description::VARCHAR(1000)
FROM sa_v_sales_data_wa.ext_sales_wa ext
WHERE NOT EXISTS (
    SELECT 1
    FROM sa_v_sales_data_wa.src_sales_wa src
    WHERE src.vin                = ext.vin
      AND src.city               = ext.city
      AND src.state              = ext.state
      AND src.postal_code        = ext.postal_code
      AND src.model_year         = ext.model_year
      AND src.make               = ext.make
      AND src.model              = ext.model
      AND src.electric_vehicle_type = ext.electric_vehicle_type
      AND src.cafv_eligibility   = ext.cafv_eligibility
      AND src.electric_range     = ext.electric_range
      AND src.transactionid      = ext.transactionid
      AND src.selling_price      = ext.selling_price
      AND src.date               = ext.date
      AND src.customer_passport  = ext.customer_passport
      AND src.customer_name      = ext.customer_name
      AND src.gender             = ext.gender
      AND src.employee_id        = ext.employee_id
      AND src.employee_name      = ext.employee_name
      AND src.employee_phone     = ext.employee_phone
      AND src.channel_id         = ext.channel_id
      AND src.channel_type       = ext.channel_type
      AND src.channel_description= ext.channel_description
);

-- Source table for FL sales data
DROP TABLE IF EXISTS sa_v_sales_data_fl.src_sales_fl;

CREATE TABLE IF NOT EXISTS sa_v_sales_data_fl.src_sales_fl (
    vin VARCHAR(1000),
    city VARCHAR(1000),
    state VARCHAR(1000),
    postal_code VARCHAR(1000),
    model_year VARCHAR(1000),
    make VARCHAR(1000),
    model VARCHAR(1000),
    electric_vehicle_type VARCHAR(1000),
    cafv_eligibility VARCHAR(1000),
    electric_range VARCHAR(1000),
    transactionid VARCHAR(1000),
    selling_price VARCHAR(1000),
    date VARCHAR(1000),
    transmission VARCHAR(1000),
    color VARCHAR(1000),
    customer_name VARCHAR(1000),
    customer_age VARCHAR(1000),
    customer_id VARCHAR(1000),
    payment_method VARCHAR(1000),
    employee_id VARCHAR(1000),
    employee_name VARCHAR(1000),
    employee_email VARCHAR(1000)
);

-- Insert FL data into source table with deduplication
INSERT INTO sa_v_sales_data_fl.src_sales_fl
SELECT 
    vin::VARCHAR(1000),
    city::VARCHAR(1000),
    state::VARCHAR(1000),
    postal_code::VARCHAR(1000),
    model_year::VARCHAR(1000),
    make::VARCHAR(1000),
    model::VARCHAR(1000),
    electric_vehicle_type::VARCHAR(1000),
    cafv_eligibility::VARCHAR(1000),
    electric_range::VARCHAR(1000),
    transactionid::VARCHAR(1000),
    selling_price::VARCHAR(1000),
    date::VARCHAR(1000),
    transmission::VARCHAR(1000),
    color::VARCHAR(1000),
    customer_name::VARCHAR(1000),
    customer_age::VARCHAR(1000),
    customer_id::VARCHAR(1000),
    payment_method::VARCHAR(1000),
    employee_id::VARCHAR(1000),
    employee_name::VARCHAR(1000),
    employee_email::VARCHAR(1000)
FROM sa_v_sales_data_fl.ext_sales_fl ext
WHERE NOT EXISTS (
    SELECT 1
    FROM sa_v_sales_data_fl.src_sales_fl src
    WHERE src.vin                = ext.vin
      AND src.city               = ext.city
      AND src.state              = ext.state
      AND src.postal_code        = ext.postal_code
      AND src.model_year         = ext.model_year
      AND src.make               = ext.make
      AND src.model              = ext.model
      AND src.electric_vehicle_type = ext.electric_vehicle_type
      AND src.cafv_eligibility   = ext.cafv_eligibility
      AND src.electric_range     = ext.electric_range
      AND src.transactionid      = ext.transactionid
      AND src.selling_price      = ext.selling_price
      AND src.date               = ext.date
      AND src.transmission       = ext.transmission
      AND src.color              = ext.color
      AND src.customer_name      = ext.customer_name
      AND src.customer_age       = ext.customer_age
      AND src.customer_id        = ext.customer_id
      AND src.payment_method     = ext.payment_method
      AND src.employee_id        = ext.employee_id
      AND src.employee_name      = ext.employee_name
      AND src.employee_email     = ext.employee_email
);

END;
$$;


--CALL public.create_and_populate_sales_data()
