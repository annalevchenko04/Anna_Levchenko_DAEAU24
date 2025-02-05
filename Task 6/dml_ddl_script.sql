--It takes ~2.20 min for execution a script 

DROP SCHEMA IF EXISTS BL_3NF CASCADE;

CREATE SCHEMA IF NOT EXISTS BL_3NF;

CREATE SEQUENCE IF NOT EXISTS BL_3NF.CE_PRODUCERS_SEQ START 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.CE_MODELS_SEQ START 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.CE_VEHICLES_SEQ START 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.CE_STATES_SEQ START 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.CE_CITIES_SEQ START 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.CE_LOCATIONS_SEQ START 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.CE_CUSTOMERS_SEQ START 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.CE_PAYMENT_METHODS_SEQ START 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.CE_EMPLOYEES_SCD_SEQ START 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.CE_SALES_CHANNELS_SEQ START 1;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.CE_TRANSACTIONS_SEQ START 1;


-- Create Tables
CREATE TABLE IF NOT EXISTS BL_3NF.CE_PRODUCERS (
    Producer_ID BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.CE_PRODUCERS_SEQ'),
    Producer_SRC_ID TEXT NOT NULL,
    Producer_Name TEXT NOT NULL,
    SOURCE_System TEXT NOT NULL,
    SOURCE_Entity TEXT NOT NULL,
    SOURCE_ID TEXT NOT NULL,
    TA_INSERT_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    TA_UPDATE_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_MODELS (
    Model_ID BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.CE_MODELS_SEQ'),
    Model_SRC_ID TEXT NOT NULL,
    Model_Name TEXT NOT NULL,
    Model_Electric_Type TEXT NOT NULL,
    Model_Electric_Range INT,
    Model_Type_CAFV TEXT,
    Producer_ID_FK BIGINT NOT NULL,
    SOURCE_System TEXT NOT NULL,
    SOURCE_Entity TEXT NOT NULL,
    SOURCE_ID TEXT NOT NULL,
    TA_INSERT_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    TA_UPDATE_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (Producer_ID_FK) REFERENCES BL_3NF.CE_PRODUCERS(Producer_ID)
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_VEHICLES (
    Vehicle_ID BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.CE_VEHICLES_SEQ'),
    VIN_SRC_ID TEXT NOT NULL,
	Vehile_Color TEXT NOT NULL,
    Vehile_Transmission_Type TEXT NOT NULL,
    Vehile_Year INT NOT NULL,
	Model_ID_FK BIGINT NOT NULL,
    SOURCE_System TEXT NOT NULL,
    SOURCE_Entity TEXT NOT NULL,
    SOURCE_ID TEXT NOT NULL,
    TA_INSERT_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    TA_UPDATE_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (Model_ID_FK) REFERENCES BL_3NF.CE_MODELS(Model_ID)
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_STATES (
    State_ID BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.CE_STATES_SEQ'),
    State_SRC_ID TEXT NOT NULL,
    State_Name TEXT NOT NULL,
    SOURCE_System TEXT NOT NULL,
    SOURCE_Entity TEXT NOT NULL,
    SOURCE_ID TEXT NOT NULL,
    TA_INSERT_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    TA_UPDATE_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_CITIES (
    City_ID BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.CE_CITIES_SEQ'),
    City_SRC_ID TEXT NOT NULL,
    City_Name TEXT NOT NULL,
    State_ID_FK BIGINT NOT NULL,
    SOURCE_System TEXT NOT NULL,
    SOURCE_Entity TEXT NOT NULL,
    SOURCE_ID TEXT NOT NULL,
    TA_INSERT_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    TA_UPDATE_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (State_ID_FK) REFERENCES BL_3NF.CE_STATES(State_ID)
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_LOCATIONS (
    Location_ID BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.CE_LOCATIONS_SEQ'),
    Location_Postal_Code_SRC_ID INT NOT NULL,
    City_ID_FK BIGINT NOT NULL,
    SOURCE_System TEXT NOT NULL,
    SOURCE_Entity TEXT NOT NULL,
    SOURCE_ID TEXT NOT NULL,
    TA_INSERT_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    TA_UPDATE_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (City_ID_FK) REFERENCES BL_3NF.CE_CITIES(City_ID)
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_CUSTOMERS (
    Customer_ID BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.CE_CUSTOMERS_SEQ'),
    Customer_SRC_ID INT NOT NULL,
	Customer_Passport TEXT,
    Customer_Name TEXT NOT NULL,
    Customer_Gender TEXT,
    Customer_Age INT,
    SOURCE_System TEXT NOT NULL,
    SOURCE_Entity TEXT NOT NULL,
    SOURCE_ID TEXT NOT NULL,
    TA_INSERT_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    TA_UPDATE_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_PAYMENT_METHODS (
    Payment_Method_ID BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.CE_PAYMENT_METHODS_SEQ'),
    Payment_Method_SRC_ID TEXT NOT NULL,
    Payment_Method_Name TEXT NOT NULL,
    SOURCE_System TEXT NOT NULL,
    SOURCE_Entity TEXT NOT NULL,
    SOURCE_ID TEXT NOT NULL,
    TA_INSERT_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    TA_UPDATE_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_EMPLOYEES_SCD (
    Employee_ID BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.CE_EMPLOYEES_SCD_SEQ'),
    Employee_SRC_ID TEXT NOT NULL,
    Employee_Name TEXT NOT NULL,
    Employee_Email TEXT,
    Employee_Phone TEXT,
    START_DT DATE NOT NULL,
    END_DT DATE,
    IS_ACTIVE BOOLEAN DEFAULT TRUE NOT NULL,
    SOURCE_System TEXT NOT NULL,
    SOURCE_Entity TEXT NOT NULL,
    SOURCE_ID TEXT NOT NULL,
    TA_INSERT_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    TA_UPDATE_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_SALES_CHANNELS (
    Sales_Channel_ID BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.CE_SALES_CHANNELS_SEQ'),
    Channel_SRC_ID TEXT NOT NULL,
    Channel_Type TEXT NOT NULL,
    Channel_Description TEXT,
    SOURCE_System TEXT NOT NULL,
    SOURCE_Entity TEXT NOT NULL,
    SOURCE_ID TEXT NOT NULL,
    TA_INSERT_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    TA_UPDATE_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Create Transactions Table
CREATE TABLE IF NOT EXISTS BL_3NF.CE_TRANSACTIONS (
    Transaction_ID BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.CE_TRANSACTIONS_SEQ'),
    Transaction_SRC_ID TEXT  NOT NULL,
    Transaction_DT DATE NOT NULL,
    Transaction_Price FLOAT NOT NULL,
    VIN_FK BIGINT NOT NULL,
    Customer_ID_FK BIGINT NOT NULL,
    Payment_Method_ID_FK BIGINT NOT NULL,
    Location_ID_FK BIGINT NOT NULL,
    Employee_ID_FK BIGINT NOT NULL,
    Channel_ID_FK BIGINT NOT NULL,
    SOURCE_System TEXT NOT NULL,
    SOURCE_Entity TEXT NOT NULL,
    SOURCE_ID TEXT NOT NULL,
    TA_INSERT_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    TA_UPDATE_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (VIN_FK) REFERENCES BL_3NF.CE_VEHICLES(Vehicle_ID),
    FOREIGN KEY (Customer_ID_FK) REFERENCES BL_3NF.CE_CUSTOMERS(Customer_ID),
    FOREIGN KEY (Payment_Method_ID_FK) REFERENCES BL_3NF.CE_PAYMENT_METHODS(Payment_Method_ID),
    FOREIGN KEY (Location_ID_FK) REFERENCES BL_3NF.CE_LOCATIONS(Location_ID),
    FOREIGN KEY (Employee_ID_FK) REFERENCES BL_3NF.CE_EMPLOYEES_SCD(Employee_ID),
    FOREIGN KEY (Channel_ID_FK) REFERENCES BL_3NF.CE_SALES_CHANNELS(Sales_Channel_ID)
);

COMMIT;


-- INSERT INTO CE_PAYMENT_METHODS
INSERT INTO BL_3NF.CE_PAYMENT_METHODS (
    Payment_Method_SRC_ID,
    Payment_Method_Name,
    SOURCE_System,
    SOURCE_Entity,
    SOURCE_ID
)
SELECT 
    COALESCE(s.payment_method, 'N/A') AS Payment_Method_SRC_ID, 
    COALESCE(s.payment_method_name, 'N/A') AS Payment_Method_Name,  
    CASE
        WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
        ELSE 'SALES_DATA_2'
    END AS SOURCE_System,
    CASE 
        WHEN s.source = 'sales_data_1' THEN 'SRC_SALES_1'
        ELSE 'SRC_SALES_2'
    END AS SOURCE_Entity,
    CASE 
        WHEN s.source = 'sales_data_1' THEN '1'
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
    SELECT 1 
    FROM BL_3NF.CE_PAYMENT_METHODS p
    WHERE p.Payment_Method_SRC_ID = COALESCE(s.payment_method, 'N/A')
      AND p.SOURCE_System = CASE WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1' ELSE 'SALES_DATA_2' END
      AND p.SOURCE_Entity = CASE WHEN s.source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END
);
COMMIT;


-- INSERT INTO CE_SALES_CHANNELS
INSERT INTO BL_3NF.CE_SALES_CHANNELS (
    Channel_SRC_ID,
    Channel_Type,
    Channel_Description,
    SOURCE_System,
    SOURCE_Entity,
    SOURCE_ID
)
SELECT 
    COALESCE(s.channel_id, 'N/A') AS Channel_SRC_ID,  
    COALESCE(s.channel_type, 'N/A') AS Channel_Type,  
    COALESCE(s.channel_description, 'N/A') AS Channel_Description,  
    CASE
        WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
        ELSE 'SALES_DATA_2'
    END AS SOURCE_System,
    CASE 
        WHEN s.source = 'sales_data_1' THEN 'SRC_SALES_1'
        ELSE 'SRC_SALES_2'
    END AS SOURCE_Entity,
    CASE 
        WHEN s.source = 'sales_data_1' THEN '1'
        ELSE '2'
    END AS SOURCE_ID
FROM (
    -- Data from sales_data_1 (has the channel columns)
    SELECT 
        channel_id,  
        channel_type,  
        channel_description,  
        'sales_data_1' AS source
    FROM sa_v_sales_data_wa.src_sales_wa

    UNION

    -- Data from sales_data_2 (insert 'N/A' since these columns don't exist)
    SELECT 
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
);
COMMIT;


-- INSERT INTO CE_EMPLOYEES_SCD
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
)
SELECT 
    COALESCE(s.employee_id, 'N/A') AS Employee_SRC_ID,  
    COALESCE(s.employee_name, 'N/A') AS Employee_Name,  
    COALESCE(s.employee_email, 'N/A') AS Employee_Email,  
    COALESCE(s.employee_phone, 'N/A') AS Employee_Phone,  
    CURRENT_DATE AS START_DT,  
    CAST(NULL AS DATE) AS END_DT,  
    TRUE AS IS_ACTIVE,  
    CASE WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1' ELSE 'SALES_DATA_2' END AS SOURCE_System,
    CASE WHEN s.source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END AS SOURCE_Entity,
    CASE WHEN s.source = 'sales_data_1' THEN '1' ELSE '2' END AS SOURCE_ID
FROM (
    -- Data from sales_data_1
    SELECT 
        employee_id,
        employee_name,
        NULL AS employee_email,  
        employee_phone,
        'sales_data_1' AS source
    FROM sa_v_sales_data_wa.src_sales_wa

    UNION

    -- Data from sales_data_2
    SELECT 
        employee_id,
        employee_name,
        employee_email,
        NULL AS employee_phone,  
        'sales_data_2' AS source
    FROM sa_v_sales_data_fl.src_sales_fl
) s
WHERE NOT EXISTS (
    SELECT 1 
    FROM BL_3NF.CE_EMPLOYEES_SCD e
    WHERE e.Employee_SRC_ID = COALESCE(s.employee_id, 'N/A')  
      AND e.SOURCE_Entity = CASE WHEN s.source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END
      AND e.IS_ACTIVE = TRUE
);
COMMIT;


--INSERT INTO CE_STATES
INSERT INTO BL_3NF.CE_STATES (
    State_SRC_ID,
    State_Name,
    SOURCE_System,
    SOURCE_Entity,
    SOURCE_ID
)
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
);
COMMIT;

-- INSERT INTO CE_CITIES
INSERT INTO BL_3NF.CE_CITIES (
    City_SRC_ID,
    City_Name,
    State_ID_FK,
    SOURCE_System,
    SOURCE_Entity,
    SOURCE_ID
)
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
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_CITIES c
    WHERE c.City_SRC_ID = s.city
);
COMMIT;


-- INSERT INTO CE_LOCATIONS
INSERT INTO BL_3NF.CE_LOCATIONS (
    Location_Postal_Code_SRC_ID,
    City_ID_FK,
    SOURCE_System,
    SOURCE_Entity,
    SOURCE_ID
)
SELECT 
    COALESCE(NULLIF(CAST(postal_code AS INTEGER), NULL), -1),
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
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_LOCATIONS l
    WHERE l.Location_Postal_Code_SRC_ID = CAST(s.postal_code AS INTEGER)
      AND l.City_ID_FK = c.City_ID
);
COMMIT;

-- INSERT INTO CE_CUSTOMERS
INSERT INTO BL_3NF.CE_CUSTOMERS (
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
        postal_code, 
        city, 
        'sales_data_1' AS source
    FROM sa_v_sales_data_wa.src_sales_wa
    
    UNION ALL
    
    -- Second source: sa_v_sales_data_fl.src_sales_fl (with customer_id and customer_age)
    SELECT 
        customer_id, 
        NULL AS customer_passport,  
        customer_name, 
        NULL AS gender,  
        customer_age, 
        postal_code, 
        city, 
        'sales_data_2' AS source
    FROM sa_v_sales_data_fl.src_sales_fl
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_CUSTOMERS c
    WHERE c.Customer_SRC_ID = COALESCE(s.customer_id::INT, -1)
);
COMMIT;


INSERT INTO BL_3NF.CE_PRODUCERS (
    Producer_Name,
    Producer_SRC_ID, 
    SOURCE_System,
    SOURCE_Entity,
    SOURCE_ID
)
SELECT DISTINCT
    COALESCE(make, 'N/A') AS Producer_Name, 
    COALESCE(make, 'N/A') AS Producer_SRC_ID, 
    CASE WHEN source = 'sales_data_1' THEN 'SALES_DATA_1' ELSE 'SALES_DATA_2' END AS SOURCE_System,
    CASE WHEN source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END AS SOURCE_Entity,
    CASE WHEN source = 'sales_data_1' THEN '1' ELSE '2' END AS SOURCE_ID
FROM (
    SELECT DISTINCT make, 'sales_data_1' AS source FROM sa_v_sales_data_wa.src_sales_wa
    UNION ALL
    SELECT DISTINCT make, 'sales_data_2' AS source FROM sa_v_sales_data_fl.src_sales_fl
) AS makes
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_PRODUCERS p
    WHERE p.Producer_Name = makes.make
);
COMMIT;

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
)
SELECT DISTINCT
    vin AS Model_SRC_ID,  -- Model unique identifier (you can use `vin` or any other unique model ID)
    COALESCE(model, 'N/A') AS Model_Name,  -- Model name (e.g., Model S, Mustang)
    COALESCE(electric_vehicle_type, 'N/A') AS Model_Electric_Type,  -- Electric vehicle type (e.g., Fully Electric)
    electric_range::INT AS Model_Electric_Range,  -- Electric range in miles
    cafv_eligibility AS Model_Type_CAFV,  -- CAFV eligibility (e.g., eligible, not eligible)
    p.Producer_ID AS Producer_ID_FK,  -- Link to the producer
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
JOIN BL_3NF.CE_PRODUCERS p ON p.Producer_Name = models.make  -- Linking to the producer
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_MODELS m
    WHERE m.Model_SRC_ID = models.vin
);
COMMIT;

INSERT INTO BL_3NF.CE_VEHICLES (
    VIN_SRC_ID,
    Vehile_Color,
    Vehile_Transmission_Type,
    Vehile_Year,
    Model_ID_FK,
    SOURCE_System,
    SOURCE_Entity,
    SOURCE_ID
)
SELECT DISTINCT
    vin AS VIN_SRC_ID,  
    COALESCE(color, 'N/A') AS Vehile_Color,  -- Use 'N/A' if color is missing
    COALESCE(transmission, 'N/A') AS Vehile_Transmission_Type,  -- Use 'N/A' if transmission is missing
    model_year::INT AS Vehile_Year,  -- Manufacturing year
    m.Model_ID AS Model_ID_FK,  -- Foreign key from CE_MODELS
    CASE WHEN source = 'sales_data_1' THEN 'SALES_DATA_1' ELSE 'SALES_DATA_2' END AS SOURCE_System,
    CASE WHEN source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END AS SOURCE_Entity,
    CASE WHEN source = 'sales_data_1' THEN '1' ELSE '2' END AS SOURCE_ID
FROM (
    SELECT vin, 
           NULL AS color,  -- Set 'color' as NULL in the first dataset (since it's missing)
           NULL AS transmission,  -- Set 'transmission' as NULL in the first dataset (since it's missing)
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
JOIN BL_3NF.CE_MODELS m ON m.Model_SRC_ID = vehicles.vin  -- Linking to the model
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_VEHICLES v
    WHERE v.VIN_SRC_ID = vehicles.vin
);
COMMIT;

--!!!This part does not work, executes infinitely, spent a lot of time try to fix, but unfortunaly until deadline still can't solve it. 
-- INSERT INTO BL_3NF.CE_TRANSACTIONS (
--     Transaction_SRC_ID,
--     Transaction_DT,
--     Transaction_Price,
--     VIN_FK,
--     Customer_ID_FK,
--     Payment_Method_ID_FK,
--     Location_ID_FK,
--     Employee_ID_FK,
--     Channel_ID_FK,
--     SOURCE_System,
--     SOURCE_Entity,
--     SOURCE_ID
-- )
-- SELECT DISTINCT
--     transactionid AS Transaction_SRC_ID, 
--     date::DATE AS Transaction_DT, 
--     selling_price::FLOAT AS Transaction_Price, 
--     v.Vehicle_ID AS VIN_FK,  -- Foreign key to CE_VEHICLES
--     COALESCE(
--         CASE 
--             WHEN t.source = 'sales_data_1' AND t.customer_passport ~ '^\d+$' THEN CAST(t.customer_passport AS BIGINT)  -- Use customer_passport for sales_data_1 if numeric
--             WHEN t.source = 'sales_data_2' THEN CAST(t.customer_id AS BIGINT)  -- Use customer_id for sales_data_2
--             ELSE NULL  -- Use NULL if no value matches
--         END, NULL  -- Default to NULL if no valid customer ID found
--     ) AS Customer_ID_FK,  -- Derived Customer_ID_FK based on the source dataset
--     COALESCE(
--         CASE 
--             WHEN t.source = 'sales_data_2' AND t.payment_method IS NOT NULL THEN pm.Payment_Method_ID  -- Only look for payment_method in sales_data_2
--             ELSE NULL  -- If not present in sales_data_2, set it to NULL
--         END, NULL  -- Default to NULL if no payment method found
--     ) AS Payment_Method_ID_FK,  -- Foreign key to CE_PAYMENT_METHODS, only when available in sales_data_2
--     l.Location_ID AS Location_ID_FK,  -- Foreign key to CE_LOCATIONS
--     e.Employee_ID AS Employee_ID_FK,  -- Foreign key to CE_EMPLOYEES_SCD (Employee related to the transaction)
--     ch.Sales_channel_ID AS Channel_ID_FK,  -- Foreign key to CE_SALES_CHANNELS (Sales channel used in the transaction)
--     CASE WHEN t.source = 'sales_data_1' THEN 'SALES_DATA_1' ELSE 'SALES_DATA_2' END AS SOURCE_System,
--     CASE WHEN t.source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END AS SOURCE_Entity,
--     '1' AS SOURCE_ID  -- Assuming SOURCE_ID is constant (modify if necessary)
-- FROM (
--     SELECT vin, 
--            transactionid, 
--            selling_price, 
--            date, 
--            customer_passport,  -- Assuming customer information is in this column for sales_data_1
--            NULL AS customer_id,  -- Assuming customer information is in this column for sales_data_2
--            NULL AS payment_method,
--            postal_code,  -- Use postal_code from the dataset
--            employee_name,  -- Employee name column (corrected)
--            channel_id,  -- Channel ID for sales data
--            'sales_data_1' AS source
--     FROM sa_v_sales_data_wa.src_sales_wa
--     UNION
--     SELECT vin, 
--            transactionid, 
--            selling_price, 
--            date, 
--            NULL AS customer_passport, 
--            customer_id,  -- Assuming customer_id is in the dataset for sales_data_2
--            payment_method,  -- Available only in sales_data_2
--            postal_code,  -- Use postal_code from the dataset for sales_data_2
--            employee_name,  
--            NULL AS channel_id, 
--            'sales_data_2' AS source
--     FROM sa_v_sales_data_fl.src_sales_fl
-- ) AS t
-- JOIN BL_3NF.CE_VEHICLES v ON v.VIN_SRC_ID = t.vin  
-- LEFT JOIN BL_3NF.CE_PAYMENT_METHODS pm ON pm.Payment_Method_Name = t.payment_method  -- Only join for sales_data_2
-- JOIN BL_3NF.CE_LOCATIONS l 
--     ON l.location_postal_code_src_id = CAST(t.postal_code AS INTEGER)  
-- JOIN BL_3NF.CE_EMPLOYEES_SCD e ON e.Employee_Name = t.employee_name
-- JOIN BL_3NF.CE_SALES_CHANNELS ch ON ch.channel_src_id = t.channel_id 
-- WHERE NOT EXISTS (
--     SELECT 1
--     FROM BL_3NF.CE_TRANSACTIONS tran
--     WHERE tran.Transaction_SRC_ID = t.transactionid
-- );
