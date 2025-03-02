-- Create schemas for source tables
CREATE SCHEMA IF NOT EXISTS sa_v_sales_data_wa;  -- WA for Washington
CREATE SCHEMA IF NOT EXISTS sa_v_sales_data_fl;  -- FL for Florida

-- Create the file_fdw extension
CREATE EXTENSION IF NOT EXISTS file_fdw;

-- Drop and recreate the sales_server for file_fdw connection
DROP SERVER IF EXISTS sales_server CASCADE;
CREATE SERVER sales_server FOREIGN DATA WRAPPER file_fdw;

-- External table for WA sales data (Washington)
DROP FOREIGN TABLE IF EXISTS sa_v_sales_data_wa.ext_sales_wa;

CREATE FOREIGN TABLE sa_v_sales_data_wa.ext_sales_wa (
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
) SERVER sales_server OPTIONS (
    filename 'C:/Program Files/PostgreSQL/Electric_Vehicle_Population_Data_1.csv',
    format 'csv',
    header 'true',
    delimiter ','
);

-- External table for FL sales data (Florida)
DROP FOREIGN TABLE IF EXISTS sa_v_sales_data_fl.ext_sales_fl;

CREATE FOREIGN TABLE sa_v_sales_data_fl.ext_sales_fl (
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
) SERVER sales_server OPTIONS (
    filename 'C:/Program Files/PostgreSQL/Electric_Vehicle_Population_Data_2.csv',
    format 'csv',
    header 'true',
    delimiter ','
);

