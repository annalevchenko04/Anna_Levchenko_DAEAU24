
-- Check if the view already exists, if so, drop it
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'sales_revenue_by_category_qtr') THEN
        DROP VIEW dvdrental.sales_revenue_by_category_qtr;
    END IF;
END $$;

-- Create the view
CREATE VIEW dvdrental.sales_revenue_by_category_qtr AS
WITH sales_data AS (
    SELECT 
        fc.category_id,
        SUM(p.amount) AS total_sales,
        EXTRACT(QUARTER FROM p.payment_date) AS quarter,
        EXTRACT(YEAR FROM p.payment_date) AS year
    FROM dvdrental.payment p
    JOIN dvdrental.rental r ON p.rental_id = r.rental_id
    JOIN dvdrental.inventory i ON r.inventory_id = i.inventory_id
    JOIN dvdrental.film_category fc ON i.film_id = fc.film_id  
    WHERE p.payment_date >= DATE_TRUNC('quarter', CURRENT_DATE) 
          AND p.payment_date < DATE_TRUNC('quarter', CURRENT_DATE) + INTERVAL '3 months'
    GROUP BY fc.category_id, quarter, year
)
SELECT c.category_id, c.name AS category_name, sd.total_sales, sd.quarter, sd.year
FROM dvdrental.category c
JOIN sales_data sd ON c.category_id = sd.category_id
WHERE sd.total_sales > 0
AND sd.year = EXTRACT(YEAR FROM CURRENT_DATE)
AND sd.quarter = EXTRACT(QUARTER FROM CURRENT_DATE);

-- Check if the function already exists, if so, drop it
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_sales_revenue_by_category_qtr') THEN
        DROP FUNCTION dvdrental.get_sales_revenue_by_category_qtr;
    END IF;
END $$;

-- Create the function
CREATE OR REPLACE FUNCTION dvdrental.get_sales_revenue_by_category_qtr(p_quarter INT, p_year INT)
RETURNS TABLE (
    category_id INT,
    category_name TEXT,
    total_sales NUMERIC,
    quarter INT,
    year INT
) AS $$
BEGIN
    RETURN QUERY
    WITH sales_data AS (
        SELECT 
            fc.category_id,
            SUM(p.amount) AS total_sales,
            EXTRACT(QUARTER FROM p.payment_date)::INT AS quarter,  -- Cast quarter to INT
            EXTRACT(YEAR FROM p.payment_date)::INT AS year         -- Cast year to INT
        FROM dvdrental.payment p
        JOIN dvdrental.rental r ON p.rental_id = r.rental_id
        JOIN dvdrental.inventory i ON r.inventory_id = i.inventory_id
        JOIN dvdrental.film_category fc ON i.film_id = fc.film_id  -- Corrected join to film_category
        WHERE p.payment_date >= TO_DATE(p_year || '-01-01', 'YYYY-MM-DD') 
          AND p.payment_date < TO_DATE(p_year || '-01-01', 'YYYY-MM-DD') + INTERVAL '1 YEAR'
          AND EXTRACT(QUARTER FROM p.payment_date) = p_quarter
        GROUP BY fc.category_id, quarter, year
    )
    SELECT c.category_id, c.name AS category_name, sd.total_sales, sd.quarter, sd.year
    FROM dvdrental.category c
    JOIN sales_data sd ON c.category_id = sd.category_id
    WHERE sd.total_sales > 0;
END;
$$ LANGUAGE plpgsql;

-- Example of calling the function
SELECT * FROM dvdrental.get_sales_revenue_by_category_qtr(2, 2017);


DROP FUNCTION IF EXISTS dvdrental.most_popular_films_by_countries(text[]);

-- Create the function
CREATE OR REPLACE FUNCTION dvdrental.most_popular_films_by_countries(countries text[] DEFAULT ARRAY['United States'])
RETURNS TABLE(
    country TEXT,
    film TEXT,
    rating TEXT,
    language TEXT,
    length INTEGER,
    release_year INTEGER
) AS $$
BEGIN
    -- Raise an exception if input array is null or empty
    IF countries IS NULL OR array_length(countries, 1) IS NULL THEN
        RAISE EXCEPTION 'The country list cannot be null or empty.';
    END IF;

    -- Main query for retrieving the most popular films by country
    RETURN QUERY
    WITH RankedFilms AS (
        SELECT 
            c.country AS country,
            f.title AS film,
            f.rating::TEXT AS rating,
            l.name::TEXT AS language,
            f.length::INTEGER AS length,
            f.release_year::INTEGER AS release_year,
            ROW_NUMBER() OVER (PARTITION BY c.country ORDER BY COUNT(r.rental_id) DESC) AS rank
        FROM 
            dvdrental.country c
        JOIN 
            dvdrental.city ci ON c.country_id = ci.country_id
        JOIN 
            dvdrental.address a ON ci.city_id = a.city_id
        JOIN 
            dvdrental.customer cust ON a.address_id = cust.address_id
        JOIN 
            dvdrental.rental r ON r.customer_id = cust.customer_id
        JOIN 
            dvdrental.inventory i ON r.inventory_id = i.inventory_id
        JOIN 
            dvdrental.film f ON i.film_id = f.film_id
        JOIN 
            dvdrental.language l ON f.language_id = l.language_id
        WHERE 
    	    LOWER(c.country) = ANY(ARRAY(SELECT LOWER(unnest(countries))))
        GROUP BY 
            c.country, f.film_id, f.title, f.rating, l.name, f.length, f.release_year
    )
    -- Filter to return only the top film per country
    SELECT
        RankedFilms.country,      
        RankedFilms.film,
        RankedFilms.rating,
        RankedFilms.language,
        RankedFilms.length,
        RankedFilms.release_year
    FROM RankedFilms
    WHERE RankedFilms.rank = 1
    ORDER BY RankedFilms.country;
END;
$$ LANGUAGE plpgsql;

-- Example of calling the function
SELECT * 
FROM dvdrental.most_popular_films_by_countries(ARRAY['Afghanistan', 'Brazil', 'United States']);


-- Drop the function if it exists to avoid duplicates
DROP FUNCTION IF EXISTS dvdrental.films_in_stock_by_title(text);

-- Create or replace the function
CREATE OR REPLACE FUNCTION dvdrental.films_in_stock_by_title(partial_title text)
RETURNS TABLE(
    row_num INTEGER,
    film_title TEXT,
    language TEXT,
    customer_name TEXT,
    rental_date DATE
) AS $$
BEGIN
    -- Check if the input is null or empty, raise an exception if true
    IF partial_title IS NULL OR partial_title = '' THEN
        RAISE EXCEPTION 'The partial title cannot be null or empty.';
    END IF;

    -- Main query to fetch films available in stock based on partial title match
    RETURN QUERY
    WITH film_rentals AS (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY f.film_id ORDER BY f.title) :: INTEGER AS row_num,  -- Generate a unique row number for each film
            f.title AS film_title,
            l.name::TEXT AS language,  -- Ensure language is returned as text
            c.first_name || ' ' || c.last_name AS customer_name,
            r.rental_date::DATE AS rental_date  -- Ensure rental date is in DATE format
        FROM 
            dvdrental.film f
        JOIN 
            dvdrental.language l ON f.language_id = l.language_id
        LEFT JOIN 
            dvdrental.inventory i ON f.film_id = i.film_id
        LEFT JOIN 
            dvdrental.rental r ON i.inventory_id = r.inventory_id
        LEFT JOIN 
            dvdrental.customer c ON r.customer_id = c.customer_id
        WHERE 
            f.title ILIKE partial_title   -- Use ILIKE for case-insensitive partial matching
            AND (r.return_date IS NULL OR r.return_date > CURRENT_DATE)  -- Ensure the film is not rented or is still due to return
    )
    -- Select distinct films (no duplicates), ordering by the row number
    SELECT fr.row_num, fr.film_title, fr.language, fr.customer_name, fr.rental_date
    FROM film_rentals fr
    WHERE fr.row_num = 1  -- Only return the first occurrence of each film
    ORDER BY fr.row_num;

    -- If no results are found, raise an exception with a custom message
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No films found in stock matching the title: %', partial_title;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Example of calling the function
SELECT * 
FROM dvdrental.films_in_stock_by_title('%ali%');


DROP FUNCTION IF EXISTS dvdrental.new_movie(text, integer, text);

-- Create or replace the function
CREATE OR REPLACE FUNCTION dvdrental.new_movie(
    movie_title text,  -- Movie title parameter
    movie_release_year integer DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),  -- Default to current year
    language_name text DEFAULT 'Klingon'  -- Default to Klingon language
)
RETURNS VOID AS $$
DECLARE
    movie_language_id INTEGER;  -- Variable to store the language_id after verifying it exists
    existing_movie_count INTEGER;  -- Variable to check if the movie already exists
BEGIN
    -- If language_name is not provided, default to Klingon
    IF language_name IS NULL THEN
        language_name := 'Klingon';
    END IF;

    -- Check if the provided language exists in the 'language' table (case-insensitive)
    SELECT l.language_id INTO movie_language_id
    FROM dvdrental.language l
    WHERE UPPER(l.name) = UPPER(language_name)
    LIMIT 1;

    -- If the language does not exist and it is not Klingon, raise an exception
    IF movie_language_id IS NULL AND UPPER(language_name) != UPPER('KLINGON') THEN
        RAISE EXCEPTION 'The provided language "%" does not exist. Movie cannot be inserted.', language_name;
    END IF;

    -- If the language does not exist but is Klingon, insert Klingon into the table
    IF movie_language_id IS NULL AND UPPER(language_name) = UPPER('KLINGON') THEN
        -- Insert Klingon language into the table
        INSERT INTO dvdrental.language (name) VALUES ('Klingon');
        
        -- Now, select the 'Klingon' language_id after inserting it
        SELECT l.language_id INTO movie_language_id
        FROM dvdrental.language l
        WHERE UPPER(l.name) = UPPER('KLINGON')
        LIMIT 1;
    END IF;

    -- Check if the movie already exists in the film table
    SELECT COUNT(*) INTO existing_movie_count
    FROM dvdrental.film f
    WHERE UPPER(f.title) = UPPER(movie_title) AND f.release_year = movie_release_year
    AND f.language_id = movie_language_id;

    -- If the movie already exists, raise an exception
    IF existing_movie_count > 0 THEN
        RAISE EXCEPTION 'Movie "%" already exists in the film table for the language "%".', movie_title, language_name;
    END IF;

    -- Insert the new movie record into the film table
    INSERT INTO dvdrental.film (title, release_year, language_id, rental_rate, rental_duration, replacement_cost)
    VALUES (
        movie_title,  -- Movie title
        movie_release_year,  -- Release year (default: current year)
        movie_language_id,  -- Language ID for the specified or defaulted language
        4.99,  -- Rental rate
        3,  -- Rental duration (3 days)
        19.99  -- Replacement cost
    );

    -- Success message for logging purposes
    RAISE NOTICE 'New movie "%" has been added to the film table.', movie_title;

END;
$$ LANGUAGE plpgsql;