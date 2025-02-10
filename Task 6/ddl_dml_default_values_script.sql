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


-- Insert Default Row for CE_PRODUCERS
INSERT INTO BL_3NF.CE_PRODUCERS (Producer_ID, Producer_SRC_ID, Producer_Name, SOURCE_System, SOURCE_Entity, SOURCE_ID)
SELECT -1, 'n.a.', 'n.a.', 'MANUAL', 'MANUAL', 'n.a.'
WHERE NOT EXISTS (SELECT 1 FROM BL_3NF.CE_PRODUCERS WHERE Producer_ID = -1);

-- Insert Default Row for CE_MODELS
INSERT INTO BL_3NF.CE_MODELS (Model_ID, Model_SRC_ID, Model_Name, Model_Electric_Type, Model_Electric_Range, Model_Type_CAFV, Producer_ID_FK, SOURCE_System, SOURCE_Entity, SOURCE_ID)
SELECT -1, 'n.a.', 'n.a.', 'n.a.', -1, 'n.a.', -1, 'MANUAL', 'MANUAL', 'n.a.'
WHERE NOT EXISTS (SELECT 1 FROM BL_3NF.CE_MODELS WHERE Model_ID = -1);

-- Insert Default Row for CE_VEHICLES
INSERT INTO BL_3NF.CE_VEHICLES (Vehicle_ID, VIN_SRC_ID, Vehile_Color, Vehile_Transmission_Type, Vehile_Year, Model_ID_FK, SOURCE_System, SOURCE_Entity, SOURCE_ID)
SELECT -1, 'n.a.', 'n.a.', 'n.a.', 1900, -1, 'MANUAL', 'MANUAL', 'n.a.'
WHERE NOT EXISTS (SELECT 1 FROM BL_3NF.CE_VEHICLES WHERE Vehicle_ID = -1);

-- Insert Default Row for CE_STATES
INSERT INTO BL_3NF.CE_STATES (State_ID, State_SRC_ID, State_Name, SOURCE_System, SOURCE_Entity, SOURCE_ID)
SELECT -1, 'n.a.', 'n.a.', 'MANUAL', 'MANUAL', 'n.a.'
WHERE NOT EXISTS (SELECT 1 FROM BL_3NF.CE_STATES WHERE State_ID = -1);

-- Insert Default Row for CE_CITIES
INSERT INTO BL_3NF.CE_CITIES (City_ID, City_SRC_ID, City_Name, State_ID_FK, SOURCE_System, SOURCE_Entity, SOURCE_ID)
SELECT -1, 'n.a.', 'n.a.', -1, 'MANUAL', 'MANUAL', 'n.a.'
WHERE NOT EXISTS (SELECT 1 FROM BL_3NF.CE_CITIES WHERE City_ID = -1);

-- Insert Default Row for CE_LOCATIONS
INSERT INTO BL_3NF.CE_LOCATIONS (Location_ID, Location_Postal_Code_SRC_ID, City_ID_FK, SOURCE_System, SOURCE_Entity, SOURCE_ID)
SELECT -1, -1, -1, 'MANUAL', 'MANUAL', 'n.a.'
WHERE NOT EXISTS (SELECT 1 FROM BL_3NF.CE_LOCATIONS WHERE Location_ID = -1);

-- Insert Default Row for CE_CUSTOMERS
INSERT INTO BL_3NF.CE_CUSTOMERS (Customer_ID, Customer_SRC_ID, Customer_Passport, Customer_Name, Customer_Gender, Customer_Age, SOURCE_System, SOURCE_Entity, SOURCE_ID)
SELECT -1, -1, 'n.a.', 'n.a.', 'n.a.', -1, 'MANUAL', 'MANUAL', 'n.a.'
WHERE NOT EXISTS (SELECT 1 FROM BL_3NF.CE_CUSTOMERS WHERE Customer_ID = -1);

-- Insert Default Row for CE_PAYMENT_METHODS
INSERT INTO BL_3NF.CE_PAYMENT_METHODS (Payment_Method_ID, Payment_Method_SRC_ID, Payment_Method_Name, SOURCE_System, SOURCE_Entity, SOURCE_ID)
SELECT -1, 'n.a.', 'n.a.', 'MANUAL', 'MANUAL', 'n.a.'
WHERE NOT EXISTS (SELECT 1 FROM BL_3NF.CE_PAYMENT_METHODS WHERE Payment_Method_ID = -1);

-- Insert Default Row for CE_EMPLOYEES_SCD
INSERT INTO BL_3NF.CE_EMPLOYEES_SCD (Employee_ID, Employee_SRC_ID, Employee_Name, Employee_Email, Employee_Phone, START_DT, END_DT, IS_ACTIVE, SOURCE_System, SOURCE_Entity, SOURCE_ID)
SELECT -1, 'n.a.', 'n.a.', 'n.a.', 'n.a.', '1900-01-01', '9999-12-31', TRUE, 'MANUAL', 'MANUAL', 'n.a.'
WHERE NOT EXISTS (SELECT 1 FROM BL_3NF.CE_EMPLOYEES_SCD WHERE Employee_ID = -1);

-- Insert Default Row for CE_SALES_CHANNELS
INSERT INTO BL_3NF.CE_SALES_CHANNELS (Sales_Channel_ID, Channel_SRC_ID, Channel_Type, Channel_Description, SOURCE_System, SOURCE_Entity, SOURCE_ID)
SELECT -1, 'n.a.', 'n.a.', 'n.a.', 'MANUAL', 'MANUAL', 'n.a.'
WHERE NOT EXISTS (SELECT 1 FROM BL_3NF.CE_SALES_CHANNELS WHERE Sales_Channel_ID = -1);

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
    SELECT 1 
    FROM BL_3NF.CE_SALES_CHANNELS c
    WHERE c.Channel_SRC_ID = COALESCE(s.channel_id, 'N/A')
      AND c.SOURCE_Entity = CASE WHEN s.source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END
);
COMMIT;

--INSERT INTO CE_EMPLOYEES_SCD
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

--INSERT INTO CE_CITIES
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
    AND st.SOURCE_System = CASE 
                               WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
                               ELSE 'SALES_DATA_2'
                           END  -- Join on the SOURCE_System too
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_CITIES c
    WHERE c.City_SRC_ID = s.city
    AND c.SOURCE_System = CASE 
                              WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
                              ELSE 'SALES_DATA_2'
                          END  -- Ensure the correct SOURCE_System is checked
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
    AND c.SOURCE_System = CASE 
                             WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
                             ELSE 'SALES_DATA_2'
                           END  -- Ensure the join includes SOURCE_System
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_LOCATIONS l
    WHERE l.Location_Postal_Code_SRC_ID = CAST(s.postal_code AS INTEGER)
      AND l.City_ID_FK = c.City_ID
      AND l.SOURCE_System = CASE 
                              WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
                              ELSE 'SALES_DATA_2'
                            END  -- Ensure the correct SOURCE_System is checked in the WHERE NOT EXISTS
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
    -- Check for duplicates based on source system and either passport/name/gender or customer_id/name/age
    SELECT 1
    FROM BL_3NF.CE_CUSTOMERS c
    WHERE 
        -- For sales_data_1, check if passport, name, and gender already exist
        (s.source = 'sales_data_1' 
         AND c.Customer_Passport = COALESCE(s.customer_passport, 'N/A') 
         AND c.Customer_Name = COALESCE(s.customer_name, 'N/A')
         AND c.Customer_Gender = COALESCE(s.gender, 'N/A'))
        
        OR
        
        -- For sales_data_2, check if customer_id, name, and age already exist
        (s.source = 'sales_data_2' 
         AND c.Customer_SRC_ID = COALESCE(s.customer_id::INT, -1) 
         AND c.Customer_Name = COALESCE(s.customer_name, 'N/A') 
         AND c.Customer_Age = COALESCE(s.customer_age::INT, -1))
    
    -- Ensure the source system matches
    AND c.SOURCE_System = CASE 
        WHEN s.source = 'sales_data_1' THEN 'SALES_DATA_1'
        ELSE 'SALES_DATA_2'
    END
);
COMMIT;


INSERT INTO BL_3NF.CE_PRODUCERS (
    Producer_Name,
    Producer_SRC_ID, 
    SOURCE_System,
    SOURCE_Entity,
    SOURCE_ID
)
SELECT 
    COALESCE(make, 'N/A') AS Producer_Name, 
    COALESCE(make, 'N/A') AS Producer_SRC_ID, 
    CASE WHEN source = 'sales_data_1' THEN 'SALES_DATA_1' ELSE 'SALES_DATA_2' END AS SOURCE_System,
    CASE WHEN source = 'sales_data_1' THEN 'SRC_SALES_1' ELSE 'SRC_SALES_2' END AS SOURCE_Entity,
    CASE WHEN source = 'sales_data_1' THEN '1' ELSE '2' END AS SOURCE_ID
FROM (
    -- Select unique 'make' from both sources
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
SELECT 
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
    -- Select unique models from both sources
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
    -- Select vehicle data from the first source (sales_data_1)
    SELECT vin, 
           NULL AS color,  -- Set 'color' as NULL in the first dataset (since it's missing)
           NULL AS transmission,  -- Set 'transmission' as NULL in the first dataset (since it's missing)
           model_year, 
           'sales_data_1' AS source
    FROM sa_v_sales_data_wa.src_sales_wa
    
    UNION
    
    -- Select vehicle data from the second source (sales_data_2)
    SELECT vin, 
           color, 
           transmission, 
           model_year, 
           'sales_data_2' AS source
    FROM sa_v_sales_data_fl.src_sales_fl
) AS vehicles
JOIN BL_3NF.CE_MODELS m ON m.Model_SRC_ID = vehicles.vin  -- Linking to the model
WHERE NOT EXISTS (
    -- Ensure there are no duplicate entries for VIN, Model_ID_FK, and SOURCE_System
    SELECT 1
    FROM BL_3NF.CE_VEHICLES v
    WHERE v.VIN_SRC_ID = vehicles.vin
      AND v.Model_ID_FK = m.Model_ID
      AND v.SOURCE_System = CASE 
          WHEN vehicles.source = 'sales_data_1' THEN 'SALES_DATA_1' 
          ELSE 'SALES_DATA_2' 
      END
);
COMMIT;


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
)
SELECT DISTINCT ON (t.transactionid)
    t.transactionid AS Transaction_SRC_ID,
    t.date::DATE AS Transaction_DT,
    t.selling_price::FLOAT AS Transaction_Price,
    
    v.Vehicle_ID AS VIN_FK,  
    
    COALESCE(
        c.Customer_ID, 
        -1  -- Default value for unknown customer
    ) AS Customer_ID_FK,

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
	
LEFT JOIN 
    BL_3NF.CE_CUSTOMERS c 
    ON c.customer_passport = t.customer_passport
    AND c.customer_name = t.customer_name
    AND c.customer_gender = t.gender
    AND c.SOURCE_System = 'SALES_DATA_1'
    AND c.SOURCE_Entity = 'SRC_SALES_1'

LEFT JOIN 
    BL_3NF.CE_LOCATIONS l 
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

LEFT JOIN 
    BL_3NF.CE_EMPLOYEES_SCD e 
    ON e.Employee_SRC_ID = t.employee_id
    AND e.SOURCE_System = 'SALES_DATA_1'
    AND e.SOURCE_Entity = 'SRC_SALES_1'

LEFT JOIN 
    BL_3NF.CE_SALES_CHANNELS ch 
    ON ch.channel_src_id = t.channel_id
    AND ch.SOURCE_System = 'SALES_DATA_1'
    AND ch.SOURCE_Entity = 'SRC_SALES_1'

WHERE 
    t.transactionid IS NOT NULL  
    AND NOT EXISTS (
        SELECT 1 
        FROM BL_3NF.CE_TRANSACTIONS tran 
        WHERE tran.Transaction_SRC_ID = t.transactionid
    );

COMMIT;

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
)
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
	
    LEFT JOIN 
    BL_3NF.CE_CUSTOMERS c 
    ON c.customer_SRC_ID = CAST(t.customer_id AS INTEGER)
    AND c.SOURCE_System = 'SALES_DATA_2'
    AND c.SOURCE_Entity = 'SRC_SALES_2'

	LEFT JOIN 
    BL_3NF.CE_PAYMENT_METHODS pm 
    ON pm.Payment_Method_Name = t.payment_method
    AND pm.SOURCE_System = 'SALES_DATA_2'

	LEFT JOIN 
    BL_3NF.CE_LOCATIONS l 
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

	LEFT JOIN 
    BL_3NF.CE_EMPLOYEES_SCD e 
    ON e.Employee_SRC_ID = t.employee_id
    AND e.SOURCE_System = 'SALES_DATA_2'
    AND e.SOURCE_Entity = 'SRC_SALES_2'
	
WHERE t.transactionid IS NOT NULL 
AND t.selling_price IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_TRANSACTIONS tran
    WHERE tran.Transaction_SRC_ID = t.transactionid
);

COMMIT;