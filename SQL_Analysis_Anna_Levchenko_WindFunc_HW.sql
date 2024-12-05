*******TASK1**********

WITH TotalSalesPerChannel AS (
    -- Step 1: Calculate total sales per channel
    SELECT 
        s.channel_id, 
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    GROUP BY s.channel_id
),
CustomerSales AS (
    -- Step 2: Calculate total sales for each customer per channel
    SELECT 
        s.channel_id, 
        s.cust_id, 
        SUM(s.amount_sold) AS customer_sales
    FROM sh.sales s
    GROUP BY s.channel_id, s.cust_id
),
RankedCustomers AS (
    -- Step 3: Rank customers by sales within each sales channel
    SELECT 
        c.channel_id,
        c.cust_id,
        c.customer_sales,
        t.total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.channel_id ORDER BY c.customer_sales DESC) AS rank
    FROM CustomerSales c
    JOIN TotalSalesPerChannel t
        ON c.channel_id = t.channel_id
)
-- Step 4: Final select, filtering top 5 customers per channel and calculating the sales percentage
SELECT 
    ch.channel_desc AS sales_channel_name, 
    cu.cust_last_name || ' ' || cu.cust_first_name AS customer_name, 
    ROUND(r.customer_sales, 2) AS total_sales,
    ROUND((r.customer_sales / r.total_sales) * 100, 4) || '%' AS sales_percentage
FROM RankedCustomers r
JOIN sh.channels ch
    ON r.channel_id = ch.channel_id
JOIN sh.customers cu
    ON r.cust_id = cu.cust_id
WHERE r.rank <= 5
ORDER BY ch.channel_desc, r.customer_sales DESC, cu.cust_last_name

*******TASK2**********

CREATE EXTENSION IF NOT EXISTS tablefunc;

WITH product_sales AS (
    SELECT 
        p.prod_name,
        EXTRACT(QUARTER FROM t.time_id) AS quarter,
        SUM(s.amount_sold) AS total_sales
     FROM 
        sh.sales s
     JOIN 
        sh.products p ON s.prod_id = p.prod_id
     JOIN 
        sh.customers c ON s.cust_id = c.cust_id
     JOIN 
        sh.countries co ON c.country_id = co.country_id
     JOIN 
        sh.times t ON s.time_id = t.time_id
     WHERE 
        LOWER(p.prod_category) = LOWER('Photo')  -- Filter for 'Photo' category
        AND LOWER(co.country_subregion) = LOWER('Asia')  -- Filter for 'Asia' region
        AND t.calendar_year = 2000  -- Filter for the year 2000
     GROUP BY 
        p.prod_name, quarter
)
SELECT 
    ct.prod_name,
    COALESCE(ct.q1, 0) AS q1,
    COALESCE(ct.q2, 0) AS q2,
    COALESCE(ct.q3, 0) AS q3,
    COALESCE(ct.q4, 0) AS q4,
    ROUND((COALESCE(ct.q1, 0) + COALESCE(ct.q2, 0) + COALESCE(ct.q3, 0) + COALESCE(ct.q4, 0)), 2) AS year_sum
FROM crosstab(
    'SELECT 
        p.prod_name,
        EXTRACT(QUARTER FROM t.time_id) AS quarter,
        SUM(s.amount_sold) AS total_sales
     FROM 
        sh.sales s
     JOIN 
        sh.products p ON s.prod_id = p.prod_id
     JOIN 
        sh.customers c ON s.cust_id = c.cust_id
     JOIN 
        sh.countries co ON c.country_id = co.country_id
     JOIN 
        sh.times t ON s.time_id = t.time_id
     WHERE 
        LOWER(p.prod_category) = LOWER(''Photo'') 
        AND LOWER(co.country_subregion) = LOWER(''Asia'') 
        AND t.calendar_year = 2000 
     GROUP BY 
        p.prod_name, quarter
     ORDER BY 
        p.prod_name, quarter',
    'VALUES (1), (2), (3), (4)'  -- Define the possible quarter values (1, 2, 3, 4)
) AS ct(prod_name TEXT, q1 NUMERIC, q2 NUMERIC, q3 NUMERIC, q4 NUMERIC)
ORDER BY prod_name ASC;

*******TASK3**********

WITH CustomerSales AS (
    -- Step 1: Calculate total sales for each customer per channel per year
    SELECT 
        s.cust_id, 
        s.channel_id, 
        t.calendar_year, 
        SUM(s.amount_sold) AS total_sales
    FROM 
        sh.sales s
    JOIN 
        sh.times t ON s.time_id = t.time_id
    WHERE 
        t.calendar_year IN (1998, 1999, 2001)  -- Filter for specific years
    GROUP BY 
        s.cust_id, s.channel_id, t.calendar_year
),
RankedCustomers AS (
    -- Step 2: Rank customers by total sales within each channel and year
    SELECT 
        cs.channel_id, 
        cs.cust_id, 
        cs.calendar_year, 
        cs.total_sales, 
        ROW_NUMBER() OVER (
            PARTITION BY cs.channel_id, cs.calendar_year 
            ORDER BY cs.total_sales DESC
        ) AS rank
    FROM 
        CustomerSales cs
),
TopCustomers AS (
    -- Step 3: Filter to include only customers who ranked in the top 300 per year/channel
    SELECT 
        rc.channel_id, 
        rc.cust_id, 
        rc.calendar_year, 
        rc.total_sales
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 300
),
QualifiedCustomers AS (
    -- Step 4: Identify customers who were in the top 300 across all years
    SELECT 
        tc.channel_id, 
        tc.cust_id
    FROM 
        TopCustomers tc
    GROUP BY 
        tc.channel_id, tc.cust_id
    HAVING 
        COUNT(DISTINCT tc.calendar_year) = 3  -- Must appear in all 3 years (1998, 1999, 2001)
),
AggregatedSales AS (
    -- Step 5: Aggregate sales for each customer/channel
    SELECT 
        tc.channel_id, 
        tc.cust_id, 
        SUM(tc.total_sales) AS total_sales
    FROM 
        TopCustomers tc
    JOIN 
        QualifiedCustomers qc 
        ON tc.channel_id = qc.channel_id AND tc.cust_id = qc.cust_id
    GROUP BY 
        tc.channel_id, tc.cust_id
)
-- Step 6: Final result
SELECT 
    ch.channel_desc AS channel_name, 
    asales.cust_id, 
    cu.cust_first_name || ' ' || cu.cust_last_name AS customer_name, 
    ROUND(asales.total_sales, 2) AS amount_sold
FROM 
    AggregatedSales asales
JOIN 
    sh.channels ch 
    ON asales.channel_id = ch.channel_id
JOIN 
    sh.customers cu 
    ON asales.cust_id = cu.cust_id
ORDER BY 
    ch.channel_desc, asales.total_sales DESC;


*******TASK4**********

SELECT 
    t.calendar_year || '-' || LPAD(t.calendar_month_number::text, 2, '0') AS calendar_month,  -- Format the month as "YYYY-MM" with leading zero for single digits
    p.prod_category, 
    TO_CHAR(ROUND(SUM(CASE 
                          WHEN LOWER(co.country_region) = LOWER('Americas') 
                          THEN s.amount_sold 
                          ELSE 0 
                      END), 2), '9,999,999') AS americas_sales,  
    TO_CHAR(ROUND(SUM(CASE 
                          WHEN LOWER(co.country_region) = LOWER('Europe')
                          THEN s.amount_sold 
                          ELSE 0 
                      END), 2), '9,999,999') AS europe_sales  
FROM 
    sh.sales s
JOIN 
    sh.products p ON s.prod_id = p.prod_id  -- Join to get product category
JOIN 
    sh.customers c ON s.cust_id = c.cust_id  -- Join to get customer details
JOIN 
    sh.countries co ON c.country_id = co.country_id  -- Join to filter by region
JOIN 
    sh.times t ON s.time_id = t.time_id  -- Join to filter by date
WHERE 
    t.calendar_year = 2000  
    AND t.calendar_month_number IN (1, 2, 3)  -- Filter for January, February, and March
    AND LOWER(co.country_region) IN (LOWER('Americas'), LOWER('Europe'))  -- Filter for Europe and Americas regions
GROUP BY
    t.calendar_month_number, t.calendar_year, p.prod_category  -- Group by month number, year, and product category
ORDER BY
    t.calendar_month_number, p.prod_category;  -- Sort by month and product category

