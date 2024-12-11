---------------------------------------Task 1 ---------------------------------------
WITH Sales_Per_Channel AS (
    SELECT 
        T.CALENDAR_YEAR,
        R.COUNTRY_REGION, 
        C.CHANNEL_DESC, 
        ROUND(SUM(S.AMOUNT_SOLD), 2) AS AMOUNT_SOLD
    FROM 
        SH.SALES S
    JOIN 
        SH.TIMES T ON S.TIME_ID = T.TIME_ID
    JOIN 
        SH.CHANNELS C ON S.CHANNEL_ID = C.CHANNEL_ID
    JOIN 
        SH.CUSTOMERS CUS ON S.CUST_ID = CUS.CUST_ID
    JOIN 
        SH.COUNTRIES R ON CUS.COUNTRY_ID = R.COUNTRY_ID
    WHERE 
        R.COUNTRY_REGION IN ('Americas', 'Asia', 'Europe')
        AND T.CALENDAR_YEAR BETWEEN 1998 AND 2001 -- Include 1998 for LAG calculations
    GROUP BY 
        T.CALENDAR_YEAR, R.COUNTRY_REGION, C.CHANNEL_DESC
),
Total_Sales_Per_Year AS (
    SELECT 
        T.CALENDAR_YEAR,
        R.COUNTRY_REGION, 
        ROUND(SUM(S.AMOUNT_SOLD), 2) AS TOTAL_SALES
    FROM 
        SH.SALES S
    JOIN 
        SH.TIMES T ON S.TIME_ID = T.TIME_ID
    JOIN 
        SH.CUSTOMERS CUS ON S.CUST_ID = CUS.CUST_ID
    JOIN 
        SH.COUNTRIES R ON CUS.COUNTRY_ID = R.COUNTRY_ID
    WHERE 
        R.COUNTRY_REGION IN ('Americas', 'Asia', 'Europe')
        AND T.CALENDAR_YEAR BETWEEN 1998 AND 2001 -- Include 1998 for LAG calculations
    GROUP BY 
        T.CALENDAR_YEAR, R.COUNTRY_REGION
),
Sales_With_Lag AS (
    SELECT 
        sp.CALENDAR_YEAR,
        sp.COUNTRY_REGION,
        sp.CHANNEL_DESC,
        sp.AMOUNT_SOLD,
        ts.TOTAL_SALES,
        LAG(sp.AMOUNT_SOLD) OVER (PARTITION BY sp.COUNTRY_REGION, sp.CHANNEL_DESC ORDER BY sp.CALENDAR_YEAR) AS PREV_AMOUNT_SOLD,
        LAG(ts.TOTAL_SALES) OVER (PARTITION BY sp.COUNTRY_REGION ORDER BY sp.CALENDAR_YEAR) AS PREV_TOTAL_SALES
    FROM 
        Sales_Per_Channel sp
    JOIN 
        Total_Sales_Per_Year ts ON sp.CALENDAR_YEAR = ts.CALENDAR_YEAR 
                                 AND sp.COUNTRY_REGION = ts.COUNTRY_REGION
)
SELECT 
    CALENDAR_YEAR,
    COUNTRY_REGION,
    CHANNEL_DESC,
    -- Formatting AMOUNT_SOLD with dollar sign and comma separators
    TO_CHAR(AMOUNT_SOLD, 'FM$999,999,999') AS AMOUNT_SOLD,
    
    -- Formatting "% BY CHANNELS" with percentage sign and two decimal places
    TO_CHAR(ROUND(AMOUNT_SOLD / TOTAL_SALES * 100, 2), '999.99') || '%' AS "% BY CHANNELS",
    
    -- Handling NULL values for PREV_AMOUNT_SOLD and PREV_TOTAL_SALES, using 0 if necessary
    TO_CHAR(
        ROUND(COALESCE(PREV_AMOUNT_SOLD, 0) / COALESCE(PREV_TOTAL_SALES, 1) * 100, 2), 
        '999.99'
    ) || '%' AS "% PREVIOUS PERIOD",
    
    -- Calculating the difference in percentage and formatting
    TO_CHAR(
        ROUND(
            ROUND(AMOUNT_SOLD / TOTAL_SALES * 100, 2) - 
            ROUND(COALESCE(PREV_AMOUNT_SOLD, 0) / COALESCE(PREV_TOTAL_SALES, 1) * 100, 2),
        2), '999.99'
    ) || '%' AS "% DIFF"
FROM 
    Sales_With_Lag
WHERE 
    CALENDAR_YEAR BETWEEN 1999 AND 2001 -- Exclude 1998 from final output
ORDER BY 
    COUNTRY_REGION, CALENDAR_YEAR, CHANNEL_DESC;
---------------------------------------Task 2 ---------------------------------------
WITH Filtered_Sales AS (
    SELECT 
        T.time_id,
        T.day_name,
        T.calendar_week_number,
        T.calendar_year,
        T.day_number_in_week,
        SUM(S.amount_sold) AS daily_amount_sold
    FROM 
        sh.SALES S
    JOIN 
        sh.TIMES T ON S.time_id = T.time_id
    WHERE 
        T.calendar_year = 1999
        AND T.calendar_week_number BETWEEN 49 AND 51
    GROUP BY 
        T.time_id, T.day_name, T.calendar_week_number, T.calendar_year, T.day_number_in_week
),
Cumulative_Sales AS (
    SELECT 
        FS.time_id,
        FS.day_name,
        FS.calendar_week_number,
        FS.calendar_year,
        FS.day_number_in_week,
        FS.daily_amount_sold,
        SUM(FS.daily_amount_sold) OVER (
            PARTITION BY FS.calendar_week_number
            ORDER BY FS.day_number_in_week
        ) AS cum_sum
    FROM 
        Filtered_Sales FS
),
Centered_Avg_Sales AS (
    SELECT 
        CS.time_id,
        CS.day_name,
        CS.calendar_week_number,
        CS.calendar_year,
        CS.day_number_in_week,
        CS.daily_amount_sold,
        CS.cum_sum,
        -- Count non-NULL values
        CASE 
            WHEN CS.day_number_in_week = 1 THEN 
                -- Monday: Handle 4-day average with possible NULLs
                (COALESCE(LAG(CS.daily_amount_sold, 2) OVER (ORDER BY CS.time_id), 0) +
                 COALESCE(LAG(CS.daily_amount_sold, 1) OVER (ORDER BY CS.time_id), 0) +
                 CS.daily_amount_sold +
                 COALESCE(LEAD(CS.daily_amount_sold, 1) OVER (ORDER BY CS.time_id), 0)) 
                 /
                (CASE WHEN LAG(CS.daily_amount_sold, 2) OVER (ORDER BY CS.time_id) IS NOT NULL THEN 1 ELSE 0 END +
                 CASE WHEN LAG(CS.daily_amount_sold, 1) OVER (ORDER BY CS.time_id) IS NOT NULL THEN 1 ELSE 0 END +
                 1 +
                 CASE WHEN LEAD(CS.daily_amount_sold, 1) OVER (ORDER BY CS.time_id) IS NOT NULL THEN 1 ELSE 0 END)
            WHEN CS.day_number_in_week = 5 THEN 
                -- Friday: Handle 4-day average with possible NULLs
                (COALESCE(LAG(CS.daily_amount_sold, 1) OVER (ORDER BY CS.time_id), 0) +
                 CS.daily_amount_sold +
                 COALESCE(LEAD(CS.daily_amount_sold, 1) OVER (ORDER BY CS.time_id), 0) +
                 COALESCE(LEAD(CS.daily_amount_sold, 2) OVER (ORDER BY CS.time_id), 0)) 
                 /
                (CASE WHEN LAG(CS.daily_amount_sold, 1) OVER (ORDER BY CS.time_id) IS NOT NULL THEN 1 ELSE 0 END +
                 1 +
                 CASE WHEN LEAD(CS.daily_amount_sold, 1) OVER (ORDER BY CS.time_id) IS NOT NULL THEN 1 ELSE 0 END +
                 CASE WHEN LEAD(CS.daily_amount_sold, 2) OVER (ORDER BY CS.time_id) IS NOT NULL THEN 1 ELSE 0 END)
            ELSE 
                -- Centered 3-day average for all other days
                (COALESCE(LAG(CS.daily_amount_sold, 1) OVER (ORDER BY CS.time_id), 0) +
                 CS.daily_amount_sold +
                 COALESCE(LEAD(CS.daily_amount_sold, 1) OVER (ORDER BY CS.time_id), 0)) 
                 /
                (CASE WHEN LAG(CS.daily_amount_sold, 1) OVER (ORDER BY CS.time_id) IS NOT NULL THEN 1 ELSE 0 END +
                 1 +
                 CASE WHEN LEAD(CS.daily_amount_sold, 1) OVER (ORDER BY CS.time_id) IS NOT NULL THEN 1 ELSE 0 END)
        END AS centered_3_day_avg
    FROM 
        Cumulative_Sales CS
)
SELECT 
    calendar_week_number,
    time_id,
    day_name,
    daily_amount_sold,
    cum_sum,
    ROUND(centered_3_day_avg, 2) AS centered_3_day_avg
FROM 
    Centered_Avg_Sales
ORDER BY 
    calendar_week_number, day_number_in_week;

---------------------------------------Task 3 ---------------------------------------
---For showing difference between ROWS, RANGE and GROUPS------
---Define which rows will be included in the window frame with window functions calculations like SUM and ARRAY_AGG---
SELECT 
    P.prod_category,
    P.prod_id,
    P.prod_name,
    P.prod_list_price,
    
    -- ROWS: The frame includes one preceding row, the current row, and one following row.
    SUM(P.prod_list_price) OVER (
        PARTITION BY P.prod_category
        ORDER BY P.prod_list_price
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS sum_with_rows,

	 -- Show the values included in the window frame for ROWS
    ARRAY_AGG(P.prod_list_price) OVER (
        PARTITION BY P.prod_category
        ORDER BY P.prod_list_price
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS values_in_window_rows,

    -- RANGE:  It includes values that fall within the range of the ORDER BY clause (e.g., one unit before and after the current value).
	-- If multiple rows share the same value, they are all included.
    SUM(P.prod_list_price) OVER (
        PARTITION BY P.prod_category
        ORDER BY P.prod_list_price
        RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS sum_with_range,

	-- Show the values included in the window frame for RANGE
    ARRAY_AGG(P.prod_list_price) OVER (
        PARTITION BY P.prod_category
        ORDER BY P.prod_list_price
        RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS values_in_window_range,
    
    -- GROUPS: The frame includes the current group, one preceding group, and one following group.
    SUM(P.prod_list_price) OVER (
        PARTITION BY P.prod_category
        ORDER BY P.prod_list_price
        GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS sum_with_groups,
  
    -- Show the values included in the window frame for GROUPS
    ARRAY_AGG(P.prod_list_price) OVER (
        PARTITION BY P.prod_category
        ORDER BY P.prod_list_price
        GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS values_in_window_groups

FROM 
    SH.PRODUCTS P
GROUP BY 
    P.prod_category, P.prod_id, P.prod_name, P.prod_list_price
ORDER BY 
    P.prod_category, P.prod_list_price;



