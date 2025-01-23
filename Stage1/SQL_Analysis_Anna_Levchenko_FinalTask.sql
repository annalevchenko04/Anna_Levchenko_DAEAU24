---------------------------------------Task 1 ---------------------------------------
WITH Ranked_Regions AS (
    SELECT 
        ch.channel_desc AS "CHANNEL_DESC",
        c.country_region AS "COUNTRY_REGION",
        SUM(s.quantity_sold) AS total_sales,  -- Total sales per region per channel
        SUM(SUM(s.quantity_sold)) OVER (PARTITION BY ch.channel_desc) AS channel_total_sales,  -- Total sales for the channel
        RANK() OVER (PARTITION BY ch.channel_desc ORDER BY SUM(s.quantity_sold) DESC) AS rank,  -- Rank regions within each channel
        ROUND(100.0 * SUM(s.quantity_sold) / SUM(SUM(s.quantity_sold)) OVER (PARTITION BY ch.channel_desc), 2) || '%' AS "SALES %"
    FROM 
        sh.sales s
    JOIN 
        sh.channels ch ON s.channel_id = ch.channel_id
    JOIN 
        sh.customers cu ON s.cust_id = cu.cust_id  
    JOIN 
        sh.countries c ON cu.country_id = c.country_id 
    GROUP BY 
        ch.channel_desc, c.country_region
)
SELECT 
    "CHANNEL_DESC",
    "COUNTRY_REGION",
    ROUND(total_sales, 2) AS "SALES",  -- Rounded to two decimals
    "SALES %"
FROM 
    Ranked_Regions
WHERE 
    rank = 1  -- Include only the top-ranked region for each channel
ORDER BY 
    total_sales DESC;
---------------------------------------Task 2 ---------------------------------------
WITH sales_data AS (
    SELECT 
        t.calendar_year,
        p.prod_subcategory, 
        SUM(s.amount_sold) AS sales,
        LAG(SUM(s.amount_sold)) OVER (PARTITION BY p.prod_subcategory ORDER BY t.calendar_year) AS prev_year_sales
    FROM 
        sh.sales s
    JOIN 
        sh.products p ON p.prod_id = s.prod_id
    JOIN 
        sh.times t ON t.time_id = s.time_id
    WHERE 
        t.calendar_year BETWEEN 1997 AND 2001
    GROUP BY 
        t.calendar_year, p.prod_subcategory
)
SELECT 
    prod_subcategory
FROM 
    sales_data
WHERE 
    (calendar_year > 1997 AND sales > COALESCE(prev_year_sales, 0))  -- Sales greater than previous year
GROUP BY 
    prod_subcategory
HAVING 
    -- Ensure sales increased for each year (1998, 1999, 2000, 2001)
    COUNT(CASE WHEN calendar_year = 1998 AND sales > COALESCE(prev_year_sales, 0) THEN 1 END) = 1
    AND COUNT(CASE WHEN calendar_year = 1999 AND sales > COALESCE(prev_year_sales, 0) THEN 1 END) = 1
    AND COUNT(CASE WHEN calendar_year = 2000 AND sales > COALESCE(prev_year_sales, 0) THEN 1 END) = 1
    AND COUNT(CASE WHEN calendar_year = 2001 AND sales > COALESCE(prev_year_sales, 0) THEN 1 END) = 1
ORDER BY 
    prod_subcategory;
---------------------------------------Task 3 ---------------------------------------
SELECT 
    t.calendar_year, 
    t.calendar_quarter_desc, 
    p.prod_category, 
    TO_CHAR(ROUND(SUM(s.amount_sold), 2), 'FM999,999,999.00') AS sales, 
    CASE 
        WHEN ROW_NUMBER() OVER (
            PARTITION BY p.prod_category, t.calendar_year 
            ORDER BY t.calendar_quarter_desc
        ) = 1 THEN 'N/A'
        ELSE 
            ROUND(
                100.0 * (SUM(s.amount_sold) - FIRST_VALUE(SUM(s.amount_sold)) OVER (
                    PARTITION BY p.prod_category, t.calendar_year 
                    ORDER BY t.calendar_quarter_desc
					ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                )) / 
                FIRST_VALUE(SUM(s.amount_sold)) OVER (
                    PARTITION BY p.prod_category, t.calendar_year 
                    ORDER BY t.calendar_quarter_desc
					ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ), 2
            ) || '%'
    END AS diff_percent,
    TO_CHAR(ROUND(SUM(SUM(s.amount_sold)) OVER (
        PARTITION BY t.calendar_year 
        ORDER BY t.calendar_quarter_desc
        GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2), 'FM999,999,999.00') AS cum_sum$
FROM 
    sh.sales s
JOIN 
    sh.products p ON p.prod_id = s.prod_id
JOIN 
    sh.channels ch ON ch.channel_id = s.channel_id
JOIN 
    sh.times t ON t.time_id = s.time_id
WHERE 
    t.calendar_year IN (1999, 2000)
    AND LOWER(ch.channel_desc) IN (LOWER('Partners'), LOWER('Internet'))
    AND LOWER(p.prod_category) IN (LOWER('Electronics'), LOWER('Hardware'), LOWER('Software/Other'))
GROUP BY 
    t.calendar_year, t.calendar_quarter_desc, p.prod_category
ORDER BY 
    t.calendar_year ASC, 
    t.calendar_quarter_desc ASC, 
    sales DESC;
