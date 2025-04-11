-- CREATE SCHEMA IF NOT EXISTS sa_v_bank_data;
-- CREATE EXTENSION IF NOT EXISTS file_fdw;
-- DROP SERVER IF EXISTS bank_server CASCADE;

-- CREATE SERVER bank_server
-- FOREIGN DATA WRAPPER file_fdw;
-- DROP FOREIGN TABLE IF EXISTS sa_v_bank_data.ext_bank;

-- CREATE FOREIGN TABLE sa_v_bank_data.ext_bank (
--     age INTEGER,
--     job VARCHAR(100),
--     marital VARCHAR(100),
--     education VARCHAR(100),
--     default_status VARCHAR(10),
--     balance INTEGER,
--     housing VARCHAR(10),
--     loan VARCHAR(10),
--     contact VARCHAR(50),
--     duration INTEGER
-- ) SERVER bank_server OPTIONS (
--     filename 'C:/Program Files/PostgreSQL/bank.csv', 
--     format 'csv',
--     header 'true',
--     delimiter ','  
-- );


-- SELECT * FROM sa_v_bank_data.ext_bank;

-- SELECT * FROM sa_v_bank_data.ext_bank 
-- WHERE age < 0;

-- SELECT * FROM sa_v_bank_data.ext_bank
-- WHERE age > 100;

-- SELECT * FROM sa_v_bank_data.ext_bank 
-- WHERE duration <= 0;

-- SELECT * FROM sa_v_bank_data.ext_bank WHERE contact IS NULL;

-- SELECT DISTINCT job 
-- FROM sa_v_bank_data.ext_bank
-- ORDER BY job;

-- SELECT DISTINCT default_status FROM sa_v_bank_data.ext_bank;

-- SELECT DISTINCT housing FROM sa_v_bank_data.ext_bank;

-- SELECT DISTINCT loan FROM sa_v_bank_data.ext_bank;

-- SELECT age, job, marital, education, default_status, balance, housing, loan, contact, duration, COUNT(*)
-- FROM sa_v_bank_data.ext_bank
-- GROUP BY age, job, marital, education, default_status, balance, housing, loan, contact, duration
-- HAVING COUNT(*) > 1;

