COPY user_dilab_student51.customer
FROM 's3://levchenko-bucket-2025/di_dwh_database/bl_dm/table1/customer_data.csv'
CREDENTIALS 'aws_iam_role=arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION  'us-east-1'
DELIMITER ','
CSV
IGNOREHEADER 1


COPY user_dilab_student51.transactions
FROM 's3://levchenko-bucket-2025/di_dwh_database/bl_dm/table6/transaction_data.csv'
CREDENTIALS 'aws_iam_role=arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION  'us-east-1'
DELIMITER ','
CSV
IGNOREHEADER 1



COPY user_dilab_student51.location
FROM 's3://levchenko-bucket-2025/di_dwh_database/bl_dm/table4/location_data.csv'
CREDENTIALS 'aws_iam_role=arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION  'us-east-1'
DELIMITER ','
CSV
IGNOREHEADER 1



-- Create table for first COPY command
CREATE TABLE user_dilab_student51.lineorder_1
(
  lo_orderkey         INTEGER NOT NULL,
  lo_linenumber       INTEGER NOT NULL,
  lo_custkey          INTEGER NOT NULL,
  lo_partkey          INTEGER NOT NULL,
  lo_suppkey          INTEGER NOT NULL,
  lo_orderdate        INTEGER NOT NULL,
  lo_orderpriority    VARCHAR(15) NOT NULL,
  lo_shippriority     VARCHAR(1) NOT NULL,
  lo_quantity         INTEGER NOT NULL,
  lo_extendedprice    INTEGER NOT NULL,
  lo_ordertotalprice  INTEGER NOT NULL,
  lo_discount         INTEGER NOT NULL,
  lo_revenue          INTEGER NOT NULL,
  lo_supplycost       INTEGER NOT NULL,
  lo_tax              INTEGER NOT NULL,
  lo_commitdate       INTEGER NOT NULL,
  lo_shipmode         VARCHAR(10) NOT NULL
);

-- Create table for second COPY command
CREATE TABLE user_dilab_student51.lineorder_2
(
  lo_orderkey         INTEGER NOT NULL,
  lo_linenumber       INTEGER NOT NULL,
  lo_custkey          INTEGER NOT NULL,
  lo_partkey          INTEGER NOT NULL,
  lo_suppkey          INTEGER NOT NULL,
  lo_orderdate        INTEGER NOT NULL,
  lo_orderpriority    VARCHAR(15) NOT NULL,
  lo_shippriority     VARCHAR(1) NOT NULL,
  lo_quantity         INTEGER NOT NULL,
  lo_extendedprice    INTEGER NOT NULL,
  lo_ordertotalprice  INTEGER NOT NULL,
  lo_discount         INTEGER NOT NULL,
  lo_revenue          INTEGER NOT NULL,
  lo_supplycost       INTEGER NOT NULL,
  lo_tax              INTEGER NOT NULL,
  lo_commitdate       INTEGER NOT NULL,
  lo_shipmode         VARCHAR(10) NOT NULL
);



COPY user_dilab_student51.lineorder_1
FROM 's3://dilabbucket/files/lineorder_file/lineorder_00.gz'
CREDENTIALS 'aws_iam_role=arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION  'eu-central-1'
GZIP
DELIMITER ',';

COPY user_dilab_student51.lineorder_2
FROM 's3://dilabbucket/files/lineorders'
CREDENTIALS 'aws_iam_role=arn:aws:iam::260586643565:role/dilab-redshift-role'
FORMAT AS PARQUET;


Select * from pg_catalog.stl_load_errors;


CREATE TABLE user_dilab_student51.date (
    date_id BIGINT,
    date_full VARCHAR(255),
    date_year BIGINT,
    date_quarter BIGINT,
    date_month BIGINT,
    date_week BIGINT,
    date_day BIGINT,
    date_day_of_week VARCHAR(255)
);


COPY user_dilab_student51.date
FROM 's3://levchenko-bucket-2025/di_dwh_database/bl_dm/table2/dates_data.csv'
CREDENTIALS 'aws_iam_role=arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION  'us-east-1'
DELIMITER ','
CSV
IGNOREHEADER 1


UNLOAD ('
    SELECT t.* 
    FROM user_dilab_student51.transactions t
    JOIN user_dilab_student51.date d ON t.event_dt_fk = d.date_id
    WHERE d.date_full >= ''2022-01-01'' AND d.date_full < ''2022-02-01''
')
TO 's3://levchenko-bucket-2025/di_dwh_database/bl_dm/table6/event_dt_fk=2022-01-01/'
IAM_ROLE 'arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION 'us-east-1'
FORMAT AS PARQUET;

UNLOAD ('
    SELECT t.* 
    FROM user_dilab_student51.transactions t
    JOIN user_dilab_student51.date d ON t.event_dt_fk = d.date_id
    WHERE d.date_full >= ''2022-02-01'' AND d.date_full < ''2022-03-01''
')
TO 's3://levchenko-bucket-2025/di_dwh_database/bl_dm/table6/event_dt_fk=2022-02-01/'
IAM_ROLE 'arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION 'us-east-1'
FORMAT AS PARQUET;


UNLOAD ('
    SELECT t.* 
    FROM user_dilab_student51.transactions t
    JOIN user_dilab_student51.date d ON t.event_dt_fk = d.date_id
    WHERE d.date_full >= ''2022-03-01'' AND d.date_full < ''2022-04-01''
')
TO 's3://levchenko-bucket-2025/di_dwh_database/bl_dm/table6/event_dt_fk=2022-03-01/'
IAM_ROLE 'arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION 'us-east-1'
FORMAT AS PARQUET;

CREATE EXTERNAL SCHEMA user_dilab_student51_ext
FROM DATA CATALOG 
DATABASE 'di_dwh_database_anna_levchenko'
IAM_ROLE 'arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION 'eu-central-1';

CREATE EXTERNAL TABLE user_dilab_student51_ext.ext_student_partitioned (
    transaction_id BIGINT,
    customer_id BIGINT,
    amount DECIMAL(10,2)
)
PARTITIONED BY (date_full DATE)  -- Partitioning by the date column
STORED AS PARQUET
LOCATION 's3://levchenko-bucket-2025/di_dwh_database/bl_dm/table6/';


SELECT * 
FROM user_dilab_student51_ext.ext_student_partitioned



SELECT Count(t.*)
FROM user_dilab_student51.transactions t
JOIN user_dilab_student51.date d ON t.event_dt_fk = d.date_id
WHERE d.date_full >= '2022-01-01' AND d.date_full < '2022-02-01'


SELECT Count(t.*)
FROM user_dilab_student51.transactions t
JOIN user_dilab_student51.date d ON t.event_dt_fk = d.date_id
WHERE d.date_full >= '2022-02-01' AND d.date_full < '2022-03-01'


SELECT Count(t.*)
FROM user_dilab_student51.transactions t
JOIN user_dilab_student51.date d ON t.event_dt_fk = d.date_id
WHERE d.date_full >= '2022-03-01' AND d.date_full < '2022-04-01'


EXPLAIN
SELECT *
FROM user_dilab_student51_ext.ext_student_partitioned
WHERE date_full >= '2022-03-01' AND date_full < '2022-04-01'

