CREATE OR REPLACE FUNCTION sh.get_total_sales_by_category(
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    product_category VARCHAR,
    total_sales_amount NUMERIC
) AS $$
BEGIN
    -- Check if dates are valid
    IF start_date IS NULL OR end_date IS NULL THEN
        RAISE EXCEPTION 'Start date and end date cannot be NULL';
    END IF;

    IF start_date > end_date THEN
        RAISE EXCEPTION 'Start date cannot be after end date';
    END IF;

    RETURN QUERY
    SELECT 
        p.prod_category AS product_category,
        SUM(s.amount_sold) AS total_sales_amount
    FROM 
        sh.sales s
    JOIN 
        sh.products p ON s.prod_id = p.prod_id
    JOIN 
        sh.times t ON s.time_id = t.time_id
    WHERE 
        t.time_id BETWEEN start_date AND end_date
    GROUP BY 
        p.prod_category_id, p.prod_category
    ORDER BY 
        total_sales_amount DESC;
END;
$$ LANGUAGE plpgsql;

-- Example call:
SELECT * FROM sh.get_total_sales_by_category('2000-01-01', '2000-12-31');

CREATE OR REPLACE FUNCTION sh.avg_sales_by_region_for_product(
    input_prod_id INT DEFAULT NULL
)
RETURNS TABLE (
    region VARCHAR,
    product_id INT,
    avg_sales_quantity NUMERIC
) AS $$
BEGIN
    -- RAISE EXCEPTION if product ID is invalid (negative value)
    IF input_prod_id IS NOT NULL AND input_prod_id <= 0 THEN
        RAISE EXCEPTION 'Invalid product ID: %, must be positive', input_prod_id;
    END IF;

    RETURN QUERY
    WITH random_product AS (
        SELECT COALESCE(input_prod_id, (
            SELECT prod_id
            FROM sh.products
            ORDER BY RANDOM()
            LIMIT 1
        )) AS prod_id
    )
    SELECT 
        co.country_region,
        rp.prod_id AS product_id,
        AVG(s.quantity_sold) AS avg_sales_quantity
    FROM 
        sh.sales s
    JOIN 
        sh.customers cu ON s.cust_id = cu.cust_id
    JOIN 
        sh.countries co ON cu.country_id = co.country_id
    JOIN 
        random_product rp ON s.prod_id = rp.prod_id
    GROUP BY 
        co.country_region_id, co.country_region, rp.prod_id
    ORDER BY 
        avg_sales_quantity DESC;
END;
$$ LANGUAGE plpgsql;

-- Example calls:
SELECT * FROM sh.avg_sales_by_region_for_product(43);
SELECT * FROM sh.avg_sales_by_region_for_product();

SELECT 
    cu.cust_id,
    cu.cust_first_name || ' ' || cu.cust_last_name AS customer_name,
    SUM(s.amount_sold) AS total_sales_amount
FROM 
    sh.sales s
JOIN 
    sh.customers cu ON s.cust_id = cu.cust_id
GROUP BY 
    cu.cust_id
ORDER BY 
    total_sales_amount DESC
LIMIT 5;
