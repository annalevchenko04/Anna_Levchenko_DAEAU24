-- DROP DATABASE IF EXISTS "RealEstateDB";

-- CREATE DATABASE "RealEstateDB"
--     WITH
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'English_United States.1252'
--     LC_CTYPE = 'English_United States.1252'
--     LOCALE_PROVIDER = 'libc'
--     TABLESPACE = pg_default
--     CONNECTION LIMIT = -1
--     IS_TEMPLATE = False;

DROP SCHEMA IF EXISTS RealEstate CASCADE;

CREATE SCHEMA RealEstate;

DROP TABLE IF EXISTS RealEstate.Property CASCADE;
DROP TABLE IF EXISTS RealEstate.Client CASCADE;
DROP TABLE IF EXISTS RealEstate.Agent CASCADE;
DROP TABLE IF EXISTS RealEstate.Transaction CASCADE;
DROP TABLE IF EXISTS RealEstate.FinancialRecord CASCADE;
DROP TABLE IF EXISTS RealEstate.AgentProperty CASCADE;

-- 5. Create the Property Table
CREATE TABLE IF NOT EXISTS RealEstate.Property (
  property_id SERIAL PRIMARY KEY,
  property_name VARCHAR(255) NOT NULL,
  property_description TEXT,
  property_building_type VARCHAR(50) NOT NULL,
  property_price DECIMAL(10, 2) NOT NULL,
  property_size DECIMAL(10, 2) NOT NULL,
  property_number_bedrooms INT NOT NULL,
  property_number_bathrooms INT NOT NULL,
  property_city VARCHAR(255) NOT NULL,
  property_type VARCHAR(50) NOT NULL,
  property_status VARCHAR(50) NOT NULL,
  property_area_m2 DECIMAL(10, 2) GENERATED ALWAYS AS (property_size * 0.092903) STORED,
  property_status_default VARCHAR(50) DEFAULT 'Available'
);

-- 6. Add Constraints to Property Table
ALTER TABLE RealEstate.Property
  ADD CONSTRAINT check_property_price_positive CHECK (property_price > 0),
  ADD CONSTRAINT check_property_size_non_negative CHECK (property_size >= 0),
  ADD CONSTRAINT check_property_bedrooms_non_negative CHECK (property_number_bedrooms >= 0),
  ADD CONSTRAINT check_property_bathrooms_non_negative CHECK (property_number_bathrooms >= 0),
  ADD CONSTRAINT check_property_type CHECK (property_type IN ('Sale', 'Rent')),
  ADD CONSTRAINT check_property_building_type CHECK (property_building_type IN ('Apartment', 'House'));

-- 7. Create the Client Table
CREATE TABLE IF NOT EXISTS RealEstate.Client (
  client_id SERIAL PRIMARY KEY,
  client_firstname VARCHAR(255) NOT NULL,
  client_lastname VARCHAR(255) NOT NULL,
  client_phone VARCHAR(20) NOT NULL UNIQUE,
  client_email VARCHAR(255) NOT NULL UNIQUE,
  client_role VARCHAR(50) NOT NULL,
  client_role_default VARCHAR(50) DEFAULT 'Buyer'
);

-- 8. Add Constraints to Client Table
ALTER TABLE RealEstate.Client
  ADD CONSTRAINT check_client_phone_format CHECK (client_phone ~ '^\+?\d{10,15}$'),
  ADD CONSTRAINT check_client_email_format CHECK (client_email ~ '^[^@]+@[^@]+\.[^@]+$'),
  ADD CONSTRAINT check_client_role CHECK (client_role IN ('Buyer', 'Seller', 'Landlord', 'Tenant'));

-- 9. Create the Agent Table
CREATE TABLE IF NOT EXISTS RealEstate.Agent (
  agent_id SERIAL PRIMARY KEY,
  agent_firstname VARCHAR(255) NOT NULL,
  agent_lastname VARCHAR(255) NOT NULL,
  agent_phone VARCHAR(20) NOT NULL UNIQUE,
  agent_email VARCHAR(255) NOT NULL UNIQUE,
  agent_position VARCHAR(50) NOT NULL,
  agent_position_default VARCHAR(50) DEFAULT 'Sales Agent',
  agent_full_name VARCHAR(510) GENERATED ALWAYS AS (agent_firstname || ' ' || agent_lastname) STORED
);

-- 10. Add Constraints to Agent Table
ALTER TABLE RealEstate.Agent
  ADD CONSTRAINT check_agent_phone_format CHECK (agent_phone ~ '^\+?\d{10,15}$'),
  ADD CONSTRAINT check_agent_email_format CHECK (agent_email ~ '^[^@]+@[^@]+\.[^@]+$'),
  ADD CONSTRAINT check_agent_position CHECK (agent_position IN ('Sales Agent', 'Support Staff', 'Manager'));

-- 11. Create the Transaction Table
CREATE TABLE IF NOT EXISTS RealEstate.Transaction (
  transaction_id SERIAL PRIMARY KEY,
  property_id INT NOT NULL REFERENCES RealEstate.Property(property_id),
  client_id INT NOT NULL REFERENCES RealEstate.Client(client_id),
  agent_id INT NOT NULL REFERENCES RealEstate.Agent(agent_id),
  transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  transaction_amount DECIMAL(10, 2) NOT NULL,
  transaction_type VARCHAR(50) NOT NULL,
  transaction_amount_after_fee DECIMAL(10, 2) GENERATED ALWAYS AS (transaction_amount * 0.95) STORED
);

-- 12. Add Constraints to Transaction Table
ALTER TABLE RealEstate.Transaction
  ADD CONSTRAINT check_transaction_date_valid CHECK (transaction_date > CURRENT_DATE - INTERVAL '6 months'),
  ADD CONSTRAINT check_transaction_amount_positive CHECK (transaction_amount > 0),
  ADD CONSTRAINT check_transaction_type CHECK (transaction_type IN ('Sale', 'Rental'));

-- 13. Create the FinancialRecord Table
CREATE TABLE IF NOT EXISTS RealEstate.FinancialRecord (
  record_id SERIAL PRIMARY KEY,
  transaction_id INT NOT NULL REFERENCES RealEstate.Transaction(transaction_id),
  record_commission DECIMAL(10, 2) NOT NULL,
  record_fee DECIMAL(10, 2) NOT NULL,
  record_commission_default DECIMAL(10, 2) DEFAULT 1000.00,
  record_fee_default DECIMAL(10, 2) DEFAULT 500.00
);

-- 14. Add Constraints to FinancialRecord Table
ALTER TABLE RealEstate.FinancialRecord
  ADD CONSTRAINT check_record_commission_non_negative CHECK (record_commission >= 0),
  ADD CONSTRAINT check_record_fee_non_negative CHECK (record_fee >= 0);

-- 15. Create the AgentProperty Table
CREATE TABLE IF NOT EXISTS RealEstate.AgentProperty (
  agent_property_id SERIAL PRIMARY KEY,
  agent_id INT NOT NULL REFERENCES RealEstate.Agent(agent_id),
  property_id INT NOT NULL REFERENCES RealEstate.Property(property_id),
  assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 16. Add Constraints to AgentProperty Table
ALTER TABLE RealEstate.AgentProperty
  ADD CONSTRAINT check_assigned_date_not_null CHECK (assigned_date IS NOT NULL);

-- 17. Insert Data into Property Table
INSERT INTO RealEstate.Property (property_name, property_description, property_building_type, property_price, property_size, property_number_bedrooms, property_number_bathrooms, property_city, property_type, property_status)
VALUES
('Sunset Villa', 'A luxurious villa with ocean view.', 'House', 500000.00, 3500, 5, 4, 'Los Angeles', 'Sale', 'Available'),
('Downtown Apartment', 'Modern apartment in the city center.', 'Apartment', 300000.00, 1200, 2, 2, 'New York', 'Rent', 'Available'),
('Cozy Cottage', 'Small house with a garden.', 'House', 150000.00, 900, 3, 1, 'Austin', 'Sale', 'Sold'),
('Lakeview Mansion', 'Spacious mansion by the lake.', 'House', 1000000.00, 5000, 7, 5, 'Chicago', 'Rent', 'Available'),
('Urban Loft', 'Stylish loft in the heart of the city.', 'Apartment', 250000.00, 1100, 1, 1, 'San Francisco', 'Sale', 'Sold'),
('Seaside Condo', 'Luxury condo with beach access.', 'Apartment', 600000.00, 1800, 3, 2, 'Miami', 'Rent', 'Available');
-- Insert Data into Client Table
INSERT INTO RealEstate.Client (client_firstname, client_lastname, client_phone, client_email, client_role)
VALUES
('John', 'Doe', '+1234567890', 'john.doe@example.com', 'Buyer'),
('Jane', 'Smith', '+0987654321', 'jane.smith@example.com', 'Seller'),
('Bob', 'White', '+6677889900', 'bob.white@example.com', 'Buyer'),
('Charlie', 'Black', '+7788990011', 'charlie.black@example.com', 'Tenant');

-- Insert Data into Agent Table
INSERT INTO RealEstate.Agent (agent_firstname, agent_lastname, agent_phone, agent_email, agent_position)
VALUES
('Alice', 'Jones', '+1234567890', 'alice.jones@example.com', 'Sales Agent'),
('Bob', 'Taylor', '+2345678901', 'bob.taylor@example.com', 'Support Staff'),
('Clara', 'Harris', '+3456789012', 'clara.harris@example.com', 'Sales Agent'),
('David', 'Lee', '+4567890123', 'david.lee@example.com', 'Manager');

-- Insert Data into Transaction Table
INSERT INTO RealEstate.Transaction (property_id, client_id, agent_id, transaction_date, transaction_amount, transaction_type)
VALUES
(1, 1, 1, '2024-10-01 10:00:00', 500000.00, 'Sale'),
(2, 2, 2, '2024-11-01 14:00:00', 300000.00, 'Rental'),
(3, 3, 3, '2024-09-15 09:30:00', 150000.00, 'Sale'),
(4, 3, 1, '2024-08-01 10:50:40', 500000.00, 'Sale'),
(5, 2, 2, '2024-10-21 14:00:00', 300000.00, 'Rental'),
(6, 2, 3, '2024-09-30 19:30:00', 150000.00, 'Sale');

INSERT INTO RealEstate.FinancialRecord (transaction_id, record_commission, record_fee)
VALUES
(1, 10000.00, 500.00),  -- Transaction 1 (Sale of "Sunset Villa")
(2, 2000.00, 100.00),   -- Transaction 2 (Rental of "Downtown Apartment")
(3, 9000.00, 450.00),   -- Transaction 3 (Sale of "Cozy Cottage")
(4, 15000.00, 750.00),  -- Transaction 4 (Rental of "Lakeview Mansion")
(5, 12000.00, 600.00),  -- Transaction 5 (Sale of "Urban Loft")
(6, 1400.00, 70.00);    -- Transaction 6 (Rental of "Seaside Condo")

-- Insert into AgentProperty table
INSERT INTO RealEstate.AgentProperty (agent_id, property_id)
VALUES
(1, 1),  -- Alice Green is assigned to "Sunset Villa"
(2, 2),  -- Bob White is assigned to "Downtown Apartment"
(3, 3),  -- Charlie Black is assigned to "Cozy Cottage"
(3, 4),  -- Diana Blue is assigned to "Lakeview Mansion"
(2, 5),  -- Edward Gray is assigned to "Urban Loft"
(1, 6);  -- Fiona Silver is assigned to "Seaside Condo"

-- Create or replace the function to update a column in the specified table
CREATE OR REPLACE FUNCTION realestate.update_column_in_table(
    p_table_name TEXT,           -- The table to update (parameterized)
    p_column_name TEXT,          -- The column to update (parameterized)
    p_row_id INT,                -- The primary key value to identify the row (parameterized)
    p_new_value TEXT             -- The new value to set for the specified column (parameterized)
)
RETURNS VOID AS $$
DECLARE
    query TEXT;                  -- Dynamic SQL query string
BEGIN
    -- Ensure the table exists in the realestate schema
    IF NOT EXISTS (SELECT 1 
                   FROM information_schema.tables 
                   WHERE table_schema = 'realestate' 
                     AND table_name = p_table_name) THEN
        RAISE EXCEPTION 'Table "%" does not exist in schema "realestate".', p_table_name;
    END IF;

    -- Ensure the column exists in the specified table
    IF NOT EXISTS (SELECT 1 
                   FROM information_schema.columns 
                   WHERE table_schema = 'realestate'
                     AND table_name = p_table_name 
                     AND column_name = p_column_name) THEN
        RAISE EXCEPTION 'Column "%" does not exist in table "%".', p_column_name, p_table_name;
    END IF;

    -- Build the dynamic SQL query
    query := format('UPDATE realestate.%I SET %I = %L WHERE property_id = %L;', 
                    p_table_name, 
                    p_column_name, 
                    p_new_value, 
                    p_row_id);  -- Assuming property_id as the primary key for Property table

    -- Execute the dynamic SQL query
    EXECUTE query;

    -- Optionally, raise a notice after update
    RAISE NOTICE 'Updated column "%" in table "%" where property_id = % with new value: %', 
                 p_column_name, p_table_name, p_row_id, p_new_value;
END;
$$ LANGUAGE plpgsql;

-- Test the function to update the `property_price` column in the `property` table where `property_id = 1`
SELECT realestate.update_column_in_table('property', 'property_price', 1, '555555.00');

CREATE OR REPLACE FUNCTION realestate.add_new_transaction(
    p_property_id INT,                -- The property involved in the transaction (foreign key to Property)
    p_client_id INT,                  -- The client involved in the transaction (foreign key to Client)
    p_agent_id INT,                   -- The agent handling the transaction (foreign key to Agent)
    p_transaction_date TIMESTAMP,     -- The date of the transaction
    p_transaction_amount DECIMAL(10, 2), -- The total amount of the transaction
    p_transaction_type VARCHAR(50)    -- The type of transaction (Sale or Rental)
)
RETURNS VOID AS $$
BEGIN
    -- Check if the property exists
    IF NOT EXISTS (SELECT 1 FROM realestate.property WHERE property_id = p_property_id) THEN
        RAISE EXCEPTION 'Property with ID "%" does not exist.', p_property_id;
    END IF;

    -- Check if the client exists
    IF NOT EXISTS (SELECT 1 FROM realestate.client WHERE client_id = p_client_id) THEN
        RAISE EXCEPTION 'Client with ID "%" does not exist.', p_client_id;
    END IF;

    -- Check if the agent exists
    IF NOT EXISTS (SELECT 1 FROM realestate.agent WHERE agent_id = p_agent_id) THEN
        RAISE EXCEPTION 'Agent with ID "%" does not exist.', p_agent_id;
    END IF;

    -- Check if a duplicate transaction already exists
    IF EXISTS (SELECT 1 
               FROM realestate.transaction
               WHERE property_id = p_property_id
                 AND client_id = p_client_id
                 AND transaction_date = p_transaction_date
                 AND transaction_type = p_transaction_type) THEN
        RAISE EXCEPTION 'Duplicate transaction detected for Property ID: %, Client ID: %, Date: %, Type: %.',
                         p_property_id, p_client_id, p_transaction_date, p_transaction_type;
    END IF;

    -- Insert the new transaction into the Transaction table
    INSERT INTO realestate.transaction (
        property_id,
        client_id,
        agent_id,
        transaction_date,
        transaction_amount,
        transaction_type
    )
    VALUES (
        p_property_id,
        p_client_id,
        p_agent_id,
        p_transaction_date,
        p_transaction_amount,
        p_transaction_type
    );

    -- Optionally, raise a notice after the insertion
    RAISE NOTICE 'Successfully inserted new transaction for Property ID: %, Client ID: %, Agent ID: %, Transaction Type: %', 
                 p_property_id, p_client_id, p_agent_id, p_transaction_type;
END;
$$ LANGUAGE plpgsql;

-- Example: Insert a new transaction for Property ID 1, Client ID 2, Agent ID 1, with a transaction amount of 1000000.00 for a Sale
SELECT realestate.add_new_transaction(
    p_property_id := 1, 
    p_client_id := 2, 
    p_agent_id := 1, 
    p_transaction_date := '2024-8-01 15:00:00', 
    p_transaction_amount := 1000000.00, 
    p_transaction_type := 'Sale'
);

--If you try one more time insert the same, will be error

--Create view
CREATE OR REPLACE VIEW realestate.analytics_recent_quarter AS
WITH recent_quarter AS (
    -- Identify the most recent quarter (based on transaction date)
    SELECT 
        EXTRACT(YEAR FROM transaction_date) AS year,
        EXTRACT(QUARTER FROM transaction_date) AS quarter
    FROM realestate.transaction
    WHERE transaction_date IS NOT NULL
    ORDER BY transaction_date DESC
    LIMIT 1
)
SELECT 
    -- Aggregate transaction data for the most recent quarter
    r.year,
    r.quarter,
    COUNT(t.transaction_id) AS total_transactions,         -- Total number of transactions
    SUM(t.transaction_amount) AS total_transaction_amount, -- Total transaction amount
    AVG(t.transaction_amount) AS average_transaction_amount, -- Average transaction amount
    t.transaction_type,  -- Breakdown by transaction type (Sale, Rental, etc.)
    COUNT(DISTINCT t.client_id) AS total_clients, -- Number of unique clients
    COUNT(DISTINCT t.agent_id) AS total_agents -- Number of unique agents involved
FROM realestate.transaction t
JOIN recent_quarter r
    ON EXTRACT(YEAR FROM t.transaction_date) = r.year
    AND EXTRACT(QUARTER FROM t.transaction_date) = r.quarter
GROUP BY r.year, r.quarter, t.transaction_type
ORDER BY r.year DESC, r.quarter DESC, t.transaction_type;

-- Step 1: Create the read-only role with login permission
DO
$$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'readonly_manager'
    ) THEN
        CREATE ROLE readonly_manager WITH LOGIN PASSWORD 'secure_password';
    END IF;
END
$$;

-- Step 2: Grant SELECT permission on all tables in the realestate schema
GRANT CONNECT ON DATABASE RealEstateDB TO readonly_manager; -- Allow connecting to the database
GRANT USAGE ON SCHEMA realestate TO readonly_manager; -- Allow using the schema

-- Grant SELECT permission on all current tables in the schema
GRANT SELECT ON ALL TABLES IN SCHEMA realestate TO readonly_manager;

-- Step 3: Ensure the readonly_manager role can also access future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA realestate
GRANT SELECT ON TABLES TO readonly_manager;

-- Step 4: Optionally, you can restrict the role's ability to use functions that modify data
-- Ensure that the role cannot execute any functions that modify data (like INSERT, UPDATE, DELETE)
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA realestate FROM readonly_manager;

--Create a new user
DO
$$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'some_manager_user'
    ) THEN
        CREATE ROLE readonly_manager WITH LOGIN PASSWORD 'secure_password';
    END IF;
END
$$;

-- Step 5: Grant the role to specific users as needed
GRANT readonly_manager TO some_manager_user;


