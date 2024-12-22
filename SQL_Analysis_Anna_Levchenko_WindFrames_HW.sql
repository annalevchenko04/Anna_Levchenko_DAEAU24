---------------------------------------Task 1 ---------------------------------------
WITH sales_by_channel AS (
    SELECT
        R.COUNTRY_REGION,
        T.CALENDAR_YEAR,
        C.CHANNEL_DESC,
        SUM(S.AMOUNT_SOLD) AS AMOUNT_SOLD,
        SUM(S.AMOUNT_SOLD) * 100.0 / SUM(SUM(S.AMOUNT_SOLD)) OVER (
            PARTITION BY R.COUNTRY_REGION, T.CALENDAR_YEAR
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS PERCENTAGE_BY_CHANNELS
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
        LOWER(R.COUNTRY_REGION) IN (LOWER('Americas'), LOWER('Asia'), LOWER('Europe'))
        AND T.CALENDAR_YEAR BETWEEN 1998 AND 2001
    GROUP BY 
        R.COUNTRY_REGION, T.CALENDAR_YEAR, C.CHANNEL_DESC
),
lagged_sales AS (
    SELECT
        COUNTRY_REGION,
        CALENDAR_YEAR,
        CHANNEL_DESC,
        AMOUNT_SOLD,
        PERCENTAGE_BY_CHANNELS,
        LAG(PERCENTAGE_BY_CHANNELS) OVER (
            PARTITION BY COUNTRY_REGION, CHANNEL_DESC 
            ORDER BY CALENDAR_YEAR
            ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
        ) AS PERCENTAGE_PREVIOUS_PERIOD
    FROM 
        sales_by_channel
)
SELECT
    ls.COUNTRY_REGION,
    ls.CALENDAR_YEAR,
    ls.CHANNEL_DESC,
    TO_CHAR(ls.AMOUNT_SOLD, 'FM$999,999,999') AS AMOUNT_SOLD,
    TO_CHAR(ROUND(ls.PERCENTAGE_BY_CHANNELS, 2), '999.99') || '%' AS "% BY CHANNELS",
    TO_CHAR(ROUND(COALESCE(ls.PERCENTAGE_PREVIOUS_PERIOD, 0), 2), '999.99') || '%' AS "% PREVIOUS PERIOD",
    TO_CHAR(ROUND(ls.PERCENTAGE_BY_CHANNELS - COALESCE(ls.PERCENTAGE_PREVIOUS_PERIOD, 0), 2), '999.99') || '%' AS "% DIFFERENCE"
FROM 
    lagged_sales ls
WHERE 
    ls.CALENDAR_YEAR BETWEEN 1999 AND 2001
ORDER BY 
    ls.COUNTRY_REGION, ls.CALENDAR_YEAR, ls.CHANNEL_DESC;

---------------------------------------Task 2 ---------------------------------------
WITH Filtered_Sales AS (
    SELECT DISTINCT
        T.time_id,
        T.day_name,
        T.calendar_week_number,
        T.calendar_year,
        T.day_number_in_week,
        -- Calculate daily sales as a window function
        SUM(S.amount_sold) OVER (
            PARTITION BY T.calendar_week_number, T.calendar_year, T.day_number_in_week
            ORDER BY T.time_id
        ) AS daily_amount_sold,  -- This is now a window function
        -- Cumulative sales using window function 
        SUM(S.amount_sold) OVER (
            PARTITION BY T.calendar_week_number
            ORDER BY T.day_number_in_week
            GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_sum  
    FROM 
        sh.SALES S
    JOIN 
        sh.TIMES T ON S.time_id = T.time_id
    WHERE 
        T.calendar_year = 1999
        AND T.calendar_week_number BETWEEN 49 AND 51  -- Filter for weeks 49 to 51 of 1999
)
SELECT
	    FS.calendar_week_number,
        FS.time_id,
        FS.day_name,
        FS.daily_amount_sold,
        FS.cum_sum,
        -- Calculate the centered 3-day moving average with special rules for Monday and Friday
       ROUND(
	   CASE 
            WHEN FS.day_number_in_week = 1 AND FS.calendar_week_number = (SELECT MIN(calendar_week_number) FROM Filtered_Sales WHERE calendar_year = 1999) THEN 
                -- For the first Monday of the first week: Use Monday, Tuesday, and the weekend (Saturday and Sunday)
                AVG(FS.daily_amount_sold) OVER (
                    ORDER BY FS.time_id 
                    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
                )
            
            WHEN FS.day_number_in_week = 1 THEN 
                -- Centered 3-day average for Mondays (other than the first Monday)
                AVG(FS.daily_amount_sold) OVER (
                    ORDER BY FS.time_id 
                    ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
                )
            
            WHEN FS.day_number_in_week = 5 THEN 
                -- Special calculation for Fridays (Thursday, Friday, and weekend)
                AVG(FS.daily_amount_sold) OVER (
                    ORDER BY FS.time_id 
                    ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING
                )
            
            ELSE 
                -- Centered 3-day average for other days
                AVG(FS.daily_amount_sold) OVER (
                    ORDER BY FS.time_id 
                    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
                )
        END, 2) AS centered_3_day_avg
FROM Filtered_Sales FS
ORDER BY 
    FS.calendar_week_number, FS.day_number_in_week;

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



