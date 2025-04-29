--Test 1

SELECT COUNT(DISTINCT CLIENT_ID) AS distinct_clients_s1 FROM S1_CLIENTS;
SELECT COUNT(DISTINCT CLIENT_ID) AS distinct_clients_s2 FROM S2_CLIENTS;
SELECT COUNT(DISTINCT CLIENT_ID) AS distinct_clients_dwh FROM DWH_CLIENTS;

SELECT *
FROM DWH_CLIENTS
WHERE CLIENT_ID IS NULL
   OR first_NAME IS NULL
   OR EMAIL IS NULL
   OR CLIENT_SRC_ID IS NULL
   OR IS_VALID IS NULL;

SELECT DISTINCT IS_VALID
FROM DWH_CLIENTS;

--TEST 2
SELECT COUNT(DISTINCT PRODUCT_ID) AS products_s1 FROM S1_PRODUCTS;
SELECT COUNT(DISTINCT PRODUCT_ID) AS products_s2 FROM S2_Client_sales;
SELECT COUNT(DISTINCT PRODUCT_ID) AS products_dwh FROM DWH_PRODUCTS;

SELECT *
FROM DWH_PRODUCTS
WHERE PRODUCT_ID IS NULL
   OR PRODUCT_NAME IS NULL
   OR PRODUCT_COST IS NULL;

   
--Test 3

SELECT COUNT(DISTINCT CHANNEL_ID) AS channels_s1 FROM S1_CHANNELS;
SELECT COUNT(DISTINCT CHANNEL_ID) AS channels_s2 FROM S2_CHANNELS;
SELECT COUNT(DISTINCT CHANNEL_ID) AS channels_dwh FROM DWH_CHANNELS;

SELECT *
FROM DWH_CHANNELS
WHERE LOCATION_ID IS NULL;

--Expected: 0 rows — all location IDs used in DWH_CHANNELS must exist in DWH_LOCATIONS.
SELECT LOCATION_ID
FROM DWH_CHANNELS
EXCEPT
SELECT LOCATION_ID
FROM DWH_LOCATIONS;


--Test 4

SELECT DISTINCT CLIENT_ID
FROM DWH_SALES
WHERE CLIENT_ID NOT IN (SELECT CLIENT_ID FROM DWH_CLIENTS);

SELECT DISTINCT PRODUCT_ID
FROM DWH_SALES
WHERE PRODUCT_ID NOT IN (SELECT PRODUCT_ID FROM DWH_PRODUCTS);

SELECT COUNT(*) AS total_sales FROM DWH_SALES;

SELECT COUNT(*) AS joined_sales
FROM DWH_SALES s
LEFT JOIN DWH_CLIENTS c ON s.CLIENT_ID = c.CLIENT_ID
LEFT JOIN DWH_PRODUCTS p ON s.PRODUCT_ID = p.PRODUCT_ID
WHERE c.CLIENT_ID IS NOT NULL AND p.PRODUCT_ID IS NOT NULL;

--Test 5

SELECT p.PRODUCT_ID, p.PRODUCT_COST AS dwh_cost, CAST(s.COST AS numeric) AS source_cost
FROM DWH_PRODUCTS p
JOIN S1_PRODUCTS s ON p.PRODUCT_ID = CAST(s.PRODUCT_ID AS INTEGER)
WHERE p.PRODUCT_COST != CAST(s.COST AS numeric);

SELECT p.PRODUCT_ID, p.PRODUCT_COST AS dwh_cost, CAST(s.PRODUCT_PRICE AS numeric) AS source_cost
FROM DWH_PRODUCTS p
JOIN S2_CLIENT_SALES s 
ON CAST(p.PRODUCT_ID AS CHARACTER VARYING) = s.PRODUCT_ID  -- Cast DWH_PRODUCT ID to text to match S2_CLIENT_SALES
WHERE p.PRODUCT_COST != CAST(s.PRODUCT_PRICE AS numeric);

SELECT PRODUCT_ID, PRODUCT_COST
FROM DWH_PRODUCTS
WHERE PRODUCT_COST <= 0;

SELECT PRODUCT_ID, PRODUCT_COST
FROM DWH_PRODUCTS
WHERE PRODUCT_COST != ROUND(PRODUCT_COST, 2);


--TEST 6
-- Get the first purchase date (minimum SALES_DATE) for each client from DWH_SALES
SELECT CLIENT_ID, MIN(order_completed) AS first_purchase_date
FROM DWH_SALES
GROUP BY CLIENT_ID;

-- Compare first purchase date between DWH_SALES and DWH_CLIENTS
SELECT c.CLIENT_ID, 
       MIN(s.order_completed) AS calculated_first_purchase_date, 
       c.FIRST_PURRCHASE_DATE AS dwh_first_purchase_date
FROM DWH_SALES s
JOIN DWH_CLIENTS c ON s.CLIENT_ID = c.CLIENT_ID
GROUP BY c.CLIENT_ID, c.FIRST_PURRCHASE_DATE
HAVING MIN(s.order_completed) != c.FIRST_PURRCHASE_DATE;  -- Check for discrepancies

-- Check for NULL values in FIRST_PURCHASE_DATE in DWH_CLIENTS
SELECT CLIENT_ID
FROM DWH_CLIENTS
WHERE FIRST_PURRCHASE_DATE IS NULL;

--Test 7 

SELECT 
    'S1' AS source_system,
    s.client_id AS source_client_id,
    dc.client_id AS dwh_client_id,
    s.sale_date,
    SUM(CAST(s.units AS INTEGER)) AS source_quantity,
    SUM(CAST(d.quantity AS INTEGER)) AS dwh_quantity
FROM dwh_sales d
JOIN dwh_clients dc 
    ON d.client_id = dc.client_id
JOIN dwh_products dp 
    ON d.product_id = dp.product_id
JOIN s1_sales s 
    ON dc.client_src_id = s.client_id
    AND dp.product_src_id = s.product_id
    AND d.order_created = TO_DATE(s.sale_date, 'DD-MON-YY')
WHERE d.quantity IS NOT NULL
  AND d.quantity >= 0
GROUP BY s.client_id, dc.client_id, s.sale_date
HAVING SUM(CAST(d.quantity AS INTEGER)) != SUM(CAST(s.units AS INTEGER))

UNION ALL

SELECT 
    'S2' AS source_system,
    s.client_id AS source_client_id,
    dc.client_id AS dwh_client_id,
    s.sold_date,
    SUM(CAST(s.product_amount AS INTEGER)) AS source_quantity,
    SUM(CAST(d.quantity AS INTEGER)) AS dwh_quantity
FROM dwh_sales d
JOIN dwh_clients dc 
    ON d.client_id = dc.client_id
JOIN dwh_products dp 
    ON d.product_id = dp.product_id
JOIN s2_client_sales s 
    ON dc.client_src_id = s.client_id
    AND dp.product_src_id = s.product_id
    AND d.order_created = TO_DATE(s.sold_date, 'DD-MON-YY')
WHERE d.quantity IS NOT NULL
  AND d.quantity >= 0
GROUP BY s.client_id, dc.client_id, s.sold_date
HAVING SUM(CAST(d.quantity AS INTEGER)) != SUM(CAST(s.product_amount AS INTEGER));


--Test 8
SELECT CLIENT_ID, EMAIL
FROM DWH_CLIENTS
WHERE EMAIL IS NULL
   OR EMAIL !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

SELECT EMAIL, COUNT(*)
FROM DWH_CLIENTS
GROUP BY EMAIL
HAVING COUNT(*) > 1;


--Test 9
SELECT PRODUCT_ID, PRODUCT_COST
FROM DWH_PRODUCTS
WHERE PRODUCT_COST != ROUND(PRODUCT_COST, 2);


SELECT PRODUCT_ID, PRODUCT_COST
FROM DWH_PRODUCTS
WHERE PRODUCT_COST <= 0;
