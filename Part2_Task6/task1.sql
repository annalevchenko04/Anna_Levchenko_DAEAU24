-- Step 1: Create Parent Table
CREATE TABLE SALES_INFO (
    id INTEGER,
    category VARCHAR(1),
    ischeck BOOLEAN,
    eventdate DATE
);

-- Step 2: Create Child Tables (Partitions)
CREATE TABLE sales_info_2021 (CHECK (eventdate >= '2021-01-01' AND eventdate < '2022-01-01')) INHERITS (SALES_INFO);
CREATE TABLE sales_info_2022 (CHECK (eventdate >= '2022-01-01' AND eventdate < '2023-01-01')) INHERITS (SALES_INFO);
CREATE TABLE sales_info_2023 (CHECK (eventdate >= '2023-01-01' AND eventdate < '2024-01-01')) INHERITS (SALES_INFO);
CREATE TABLE sales_info_2024 (CHECK (eventdate >= '2024-01-01' AND eventdate < '2025-01-01')) INHERITS (SALES_INFO);
CREATE TABLE sales_info_2025 (CHECK (eventdate >= '2025-01-01' AND eventdate < '2026-01-01')) INHERITS (SALES_INFO);

-- Step 3: Create Partition Function
CREATE OR REPLACE FUNCTION partition_sales_info() RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.eventdate >= '2022-01-01' AND NEW.eventdate < '2023-01-01') THEN
        INSERT INTO sales_info_2022 VALUES (NEW.*);
    ELSIF (NEW.eventdate >= '2021-01-01' AND NEW.eventdate < '2022-01-01') THEN
        INSERT INTO sales_info_2021 VALUES (NEW.*);
    ELSIF (NEW.eventdate >= '2023-01-01' AND NEW.eventdate < '2024-01-01') THEN
        INSERT INTO sales_info_2023 VALUES (NEW.*);
    ELSIF (NEW.eventdate >= '2024-01-01' AND NEW.eventdate < '2025-01-01') THEN
        INSERT INTO sales_info_2024 VALUES (NEW.*);
    ELSIF (NEW.eventdate >= '2025-01-01' AND NEW.eventdate < '2026-01-01') THEN
        INSERT INTO sales_info_2025 VALUES (NEW.*);
    ELSE
        RAISE EXCEPTION 'Out of range';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Create Trigger for Partitioning
CREATE TRIGGER partition_sales_info_trigger
BEFORE INSERT ON SALES_INFO
FOR EACH ROW EXECUTE FUNCTION partition_sales_info();

--Step 5: Generate and Insert Test Data
INSERT INTO SALES_INFO (id, category, ischeck, eventdate)
SELECT id,
    ('{"A","B","C","D","E","F","J","H","I","J","K"}'::text[])[((RANDOM())*10)::INTEGER] category,
    ((1*(RANDOM())::INTEGER) < 1) ischeck,
    (NOW() - INTERVAL '10 day' * (RANDOM()::int * 100))::DATE eventdate
FROM generate_series(1,1000000) id;

--Step 6: Update some rows in SALES_INFO and set another eventdate. 
WITH moved_rows AS (
    DELETE FROM sales_info
    WHERE eventdate BETWEEN '2025-01-01' AND '2025-12-31'
    RETURNING *
)
INSERT INTO sales_info (id, category, ischeck, eventdate)
SELECT id, category, ischeck, '2024-06-15' FROM moved_rows;

-- Step 6: Create Unpartitioned Table for Comparison
CREATE TABLE SALES_INFO_SIMPLE AS SELECT * FROM SALES_INFO;

-- Step 7: Query Plan Comparisons
Select all records
EXPLAIN ANALYZE SELECT * FROM SALES_INFO;
EXPLAIN ANALYZE SELECT * FROM SALES_INFO_SIMPLE;

-- Select records within a range of dates
EXPLAIN ANALYZE SELECT * FROM SALES_INFO WHERE eventdate BETWEEN '2022-06-01' AND '2022-12-31';
EXPLAIN ANALYZE SELECT * FROM SALES_INFO_SIMPLE WHERE eventdate BETWEEN '2022-06-01' AND '2022-12-31';

-- Select records for an exact date
EXPLAIN ANALYZE SELECT * FROM SALES_INFO WHERE eventdate = '2022-07-15';
EXPLAIN ANALYZE SELECT * FROM SALES_INFO_SIMPLE WHERE eventdate = '2022-07-15';

-- Count all rows
EXPLAIN ANALYZE SELECT COUNT(*) FROM SALES_INFO;
EXPLAIN ANALYZE SELECT COUNT(*) FROM SALES_INFO_SIMPLE;

-- Count rows in a date range
EXPLAIN ANALYZE SELECT COUNT(*) FROM SALES_INFO WHERE eventdate BETWEEN '2022-01-01' AND '2022-12-31';
EXPLAIN ANALYZE SELECT COUNT(*) FROM SALES_INFO_SIMPLE WHERE eventdate BETWEEN '2022-01-01' AND '2022-12-31';

-- Step 8: Delete Old Partition and Add New Partition
DROP TABLE sales_info_2021;

CREATE TABLE sales_info_3000 (CHECK (eventdate >= '3000-01-01' AND eventdate < '3001-01-01')) INHERITS (SALES_INFO);