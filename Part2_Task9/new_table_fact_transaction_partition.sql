-- -- Create the FACT_TRANSACTIONS table with partitioning
-- CREATE TABLE IF NOT EXISTS BL_DM.FACT_TRANSACTIONS (
--     Transaction_SURR_ID BIGINT NOT NULL DEFAULT NEXTVAL('BL_DM.SEQ_FACT_TRANSACTIONS'),
--     Transaction_SRC_ID TEXT NOT NULL,
--     Event_DT_FK BIGINT NOT NULL REFERENCES BL_DM.DIM_DATES(Date_ID),  -- Foreign key reference to DIM_DATES
--     Customer_SURR_ID_FK BIGINT NOT NULL REFERENCES BL_DM.DIM_CUSTOMERS(Customer_SURR_ID),  -- Foreign key to DIM_CUSTOMERS
--     Vehicle_SURR_ID_FK BIGINT NOT NULL REFERENCES BL_DM.DIM_VEHICLES(Vehicle_SURR_ID),  -- Foreign key to DIM_VEHICLES
--     Location_SURR_ID_FK BIGINT NOT NULL REFERENCES BL_DM.DIM_LOCATIONS(Location_SURR_ID),  -- Foreign key to DIM_LOCATIONS
--     Employee_SURR_ID_FK BIGINT NOT NULL REFERENCES BL_DM.DIM_EMPLOYEES_SCD(Employee_SURR_ID),  -- Foreign key to DIM_EMPLOYEES_SCD
--     Channel_SURR_ID_FK BIGINT NOT NULL REFERENCES BL_DM.DIM_SALES_CHANNELS(Channel_SURR_ID),  -- Foreign key to DIM_SALES_CHANNELS
--     Transaction_Payment_Method_ID BIGINT DEFAULT -1,
--     Transaction_Payment_Method_Name TEXT DEFAULT 'N/A',
--     Transaction_Amount FLOAT NOT NULL,
--     Transaction_Quantity INT DEFAULT 1,
--     Transaction_Discount FLOAT DEFAULT 0,
--     Transaction_Total_Amount FLOAT GENERATED ALWAYS AS ((Transaction_Amount * Transaction_Quantity) - Transaction_Discount) STORED,
--     SOURCE_System TEXT NOT NULL,
--     SOURCE_Entity TEXT NOT NULL,
--     SOURCE_ID TEXT NOT NULL,
--     TA_INSERT_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
--     TA_UPDATE_DT TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
--     PRIMARY KEY (Transaction_SURR_ID, Event_DT_FK)  -- Include Event_DT_FK as part
-- )
-- PARTITION BY RANGE (Event_DT_FK);  -- Partition by Event_DT_FK

-- ALTER TABLE BL_DM.FACT_TRANSACTIONS 
-- ADD CONSTRAINT fact_transactions_unique_key 
-- UNIQUE (Transaction_SRC_ID, Customer_SURR_ID_FK, Vehicle_SURR_ID_FK, 
--         Location_SURR_ID_FK, Employee_SURR_ID_FK, Channel_SURR_ID_FK, 
--         SOURCE_System, Event_DT_FK);


-- CREATE TABLE BL_DM.FACT_TRANSACTIONS_DEFAULT 
-- PARTITION OF BL_DM.FACT_TRANSACTIONS DEFAULT;


-- CALL bl_cl.load_fact_transactions();