SET max_parallel_workers_per_gather = 4;

EXPLAIN ANALYZE SELECT * FROM SALES_INFO;
EXPLAIN ANALYZE SELECT * FROM SALES_INFO_DP;
EXPLAIN ANALYZE SELECT * FROM SALES_INFO_SIMPLE;

EXPLAIN ANALYZE SELECT * FROM SALES_INFO ORDER BY eventdate;
EXPLAIN ANALYZE SELECT * FROM SALES_INFO_DP ORDER BY eventdate;
EXPLAIN ANALYZE SELECT * FROM SALES_INFO_SIMPLE ORDER BY eventdate;

EXPLAIN ANALYZE SELECT COUNT(*) FROM SALES_INFO;
EXPLAIN ANALYZE SELECT COUNT(*) FROM SALES_INFO_DP;
EXPLAIN ANALYZE SELECT COUNT(*) FROM SALES_INFO_SIMPLE;

EXPLAIN ANALYZE 
SELECT * FROM SALES_INFO WHERE eventdate BETWEEN '2022-01-01' AND '2022-12-31';

EXPLAIN ANALYZE 
SELECT * FROM SALES_INFO_DP WHERE eventdate BETWEEN '2022-01-01' AND '2022-12-31';

EXPLAIN ANALYZE 
SELECT * FROM SALES_INFO_SIMPLE WHERE eventdate BETWEEN '2022-01-01' AND '2022-12-31';

EXPLAIN ANALYZE 
SELECT category, COUNT(*) FROM SALES_INFO GROUP BY category;

EXPLAIN ANALYZE 
SELECT category, COUNT(*) FROM SALES_INFO_DP GROUP BY category;

EXPLAIN ANALYZE 
SELECT category, COUNT(*) FROM SALES_INFO_SIMPLE GROUP BY category;

EXPLAIN ANALYZE 
SELECT COUNT(*)
FROM SALES_INFO si
JOIN SALES_INFO_DP sidp ON si.id = sidp.id
WHERE si.eventdate = '2022-06-15';

CREATE INDEX idx_sales_info_eventdate ON SALES_INFO(eventdate);
CREATE INDEX idx_sales_info_dp_eventdate ON SALES_INFO_DP(eventdate);
CREATE INDEX idx_sales_info_simple_eventdate ON SALES_INFO_SIMPLE(eventdate);

EXPLAIN ANALYZE SELECT * FROM SALES_INFO_DP WHERE eventdate = '2022-06-15';
EXPLAIN ANALYZE SELECT * FROM SALES_INFO ORDER BY eventdate;
SELECT * FROM SALES_INFO_SIMPLE WHERE eventdate BETWEEN '2022-01-01' AND '2022-12-31';

--During this homework, I learned how to perform different types of partitioning
--such as inheritance and declartive. Also I tried a parallel quering for
--comparing execution plans for SALES_INFO (inheritance-based partitioning), 
--SALES_INFO_DP (declarative partitioning), and SALES_INFO_SIMPLE (unpartitioned). 
--In conclusion, I firgured out that Partitioning + Indexing + Parallel Queries gives the best performance.


