-- Create the view
CREATE OR REPLACE VIEW public.sales_revenue_by_category_qtr AS
WITH sales_data AS (
    SELECT 
        fc.category_id::integer AS category_id, 
        c.name AS category_name,
        SUM(p.amount) AS total_sales,
        EXTRACT(QUARTER FROM p.payment_date) AS quarter,
        EXTRACT(YEAR FROM p.payment_date) AS year
    FROM public.payment p
    JOIN public.rental r ON p.rental_id = r.rental_id
    JOIN public.inventory i ON r.inventory_id = i.inventory_id
    JOIN public.film_category fc ON i.film_id = fc.film_id  
    JOIN public.category c ON fc.category_id = c.category_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
      AND EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM CURRENT_DATE)
    GROUP BY fc.category_id, c.name, quarter, year
)
SELECT 
    category_id, 
    category_name, 
    total_sales, 
    quarter, 
    year
FROM sales_data
WHERE total_sales > 0;

-- Call the view
SELECT * 
FROM public.sales_revenue_by_category_qtr;


-- Create the query language function
CREATE OR REPLACE FUNCTION public.get_sales_revenue_by_category_qtr(p_quarter INT, p_year INT)
RETURNS TABLE (
    category_id INT,
    category_name TEXT,
    total_sales NUMERIC,
    quarter INT,
    year INT
) AS $$
    SELECT 
        fc.category_id,
        c.name AS category_name,
        SUM(p.amount) AS total_sales,
        EXTRACT(QUARTER FROM p.payment_date)::INT AS quarter,
        EXTRACT(YEAR FROM p.payment_date)::INT AS year
    FROM public.payment p
    JOIN public.rental r ON p.rental_id = r.rental_id
    JOIN public.inventory i ON r.inventory_id = i.inventory_id
    JOIN public.film_category fc ON i.film_id = fc.film_id
    JOIN public.category c ON fc.category_id = c.category_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = p_year
      AND EXTRACT(QUARTER FROM p.payment_date) = p_quarter
    GROUP BY fc.category_id, c.name, quarter, year
    HAVING SUM(p.amount) > 0;  -- Filter out rows with no sales
$$ LANGUAGE sql;

-- Example of calling the function
SELECT * FROM public.get_sales_revenue_by_category_qtr(2, 2017);
SELECT * FROM public.get_sales_revenue_by_category_qtr(5, 2017); -- will be empty
SELECT * FROM public.get_sales_revenue_by_category_qtr(1, 1800); -- will be empty



-- Create the function
CREATE OR REPLACE FUNCTION public.most_popular_films_by_countries(countries text[])
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
    WITH PopularFilms AS (
        SELECT 
            c.country AS country,
            f.title AS film,
            f.rating::TEXT AS rating,
            l.name::TEXT AS language,
            f.length::INTEGER AS length,
            f.release_year::INTEGER AS release_year,
            COUNT(r.rental_id) AS rental_count
        FROM 
            public.country c
        JOIN 
            public.city ci ON c.country_id = ci.country_id
        JOIN 
            public.address a ON ci.city_id = a.city_id
        JOIN 
            public.customer cust ON a.address_id = cust.address_id
        JOIN 
            public.rental r ON r.customer_id = cust.customer_id
        JOIN 
            public.inventory i ON r.inventory_id = i.inventory_id
        JOIN 
            public.film f ON i.film_id = f.film_id
        JOIN 
            public.language l ON f.language_id = l.language_id
        WHERE 
            LOWER(c.country) = ANY(ARRAY(SELECT LOWER(unnest(countries))))
        GROUP BY 
            c.country, f.film_id, f.title, f.rating, l.name, f.length, f.release_year
    )
    -- Filter to return only the films that have the maximum rental count per country
    SELECT 
        pf.country,
        pf.film,
        pf.rating,
        pf.language,
        pf.length,
        pf.release_year
    FROM 
        PopularFilms pf
    WHERE 
        pf.rental_count = (
            SELECT MAX(pf2.rental_count)
            FROM PopularFilms pf2
            WHERE LOWER(pf2.country) = LOWER(pf.country)
        )
    ORDER BY 
        pf.country, pf.film;
END;
$$ LANGUAGE plpgsql;


-- Example of calling the function
SELECT * 
FROM public.most_popular_films_by_countries(ARRAY['Afghanistan', 'Brazil', 'United States']);


CREATE OR REPLACE FUNCTION public.films_in_stock_by_title(partial_title TEXT)
RETURNS TABLE(
    row_numb INT,
    film_title TEXT,
    language TEXT,
    customer_name TEXT,
    rental_date DATE
) AS $$
DECLARE
    rec RECORD;  -- To hold each row during the loop
    counter INT := 0;  -- Row number counter
BEGIN
    -- Check if the input is null or empty, raise an exception if true
    IF partial_title IS NULL OR partial_title = '' THEN
        RAISE EXCEPTION 'The partial title cannot be null or empty.';
    END IF;

    -- Main query to fetch films available in stock based on partial title match
    FOR rec IN 
        WITH film_rentals AS (
            SELECT 
                f.title AS film_title,
                l.name::TEXT AS language,  -- Ensure language is returned as text
                c.first_name || ' ' || c.last_name AS customer_name,
                r.rental_date::DATE AS rental_date  -- Ensure rental date is in DATE format
            FROM 
                public.film f
            JOIN 
                public.language l ON f.language_id = l.language_id
            LEFT JOIN 
                public.inventory i ON f.film_id = i.film_id
            LEFT JOIN 
                public.rental r ON i.inventory_id = r.inventory_id
            LEFT JOIN 
                public.customer c ON r.customer_id = c.customer_id
            WHERE 
                f.title ILIKE partial_title   -- Use ILIKE for case-insensitive partial matching
                AND (r.return_date IS NULL OR r.return_date > CURRENT_DATE)  -- Ensure the film is not rented or is still due to return
        )
        SELECT DISTINCT ON (fr.film_title) 
            fr.film_title, 
            fr.language, 
            fr.customer_name, 
            fr.rental_date
        FROM film_rentals fr
        ORDER BY fr.film_title, fr.rental_date DESC  -- Order by title, and for each title, show the most recent rental
    LOOP
        -- Increment the counter
        counter := counter + 1;

        -- Assign values directly to the OUT parameters
        row_numb := counter;
        film_title := rec.film_title;
        language := rec.language;
        customer_name := rec.customer_name;
        rental_date := rec.rental_date;

        -- Return the current row
        RETURN NEXT;
    END LOOP;

    -- If no results are found, raise an exception with a custom message
    IF counter = 0 THEN
        RAISE EXCEPTION 'No films found in stock matching the title: %', partial_title;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Example of calling the function
SELECT * 
FROM public.films_in_stock_by_title('%ali%');

-- Create or replace the function
CREATE OR REPLACE FUNCTION public.new_movie(
    movie_title text,  -- Movie title parameter
    movie_release_year integer DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),  -- Default to current year
    language_name text DEFAULT 'Klingon'  -- Default to Klingon language
)
RETURNS VOID AS $$
DECLARE
    movie_language_id INTEGER;  -- Variable to store the language_id after verifying it exists
    existing_movie_count INTEGER;  -- Variable to check if the movie already exists
BEGIN

    -- Check if movie title is NULL or empty
    IF movie_title IS NULL OR LENGTH(TRIM(movie_title)) = 0 THEN
        RAISE EXCEPTION 'The movie title cannot be NULL or empty.';
    END IF;
    
    -- If language_name is not provided, default to Klingon
    IF language_name IS NULL THEN
        language_name := 'Klingon';
    END IF;

    -- Check if the provided language exists in the 'language' table (case-insensitive)
    SELECT l.language_id INTO movie_language_id
    FROM public.language l
    WHERE UPPER(l.name) = UPPER(language_name)
    LIMIT 1;

    -- If the language does not exist, insert it into the language table
    IF movie_language_id IS NULL THEN
        INSERT INTO public.language (name) VALUES (language_name);

        -- Now, select the newly inserted language_id
        SELECT l.language_id INTO movie_language_id
        FROM public.language l
        WHERE UPPER(l.name) = UPPER(language_name)
        LIMIT 1;
    END IF;

    -- Check if the movie already exists in the film table
    SELECT COUNT(*) INTO existing_movie_count
    FROM public.film f
    WHERE UPPER(f.title) = UPPER(movie_title) AND f.release_year = movie_release_year
    AND f.language_id = movie_language_id;

    -- If the movie already exists, raise an exception
    IF existing_movie_count > 0 THEN
        RAISE EXCEPTION 'Movie "%" already exists in the film table for the language "%".', movie_title, language_name;
    END IF;

    -- Insert the new movie record into the film table
    INSERT INTO public.film (title, release_year, language_id, rental_rate, rental_duration, replacement_cost)
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


SELECT public.new_movie('The Matrix', 1999, 'English'); 
SELECT public.new_movie('The Matrix'); ---Klingon language will be added to language table, year set to current and this film to film table 
SELECT public.new_movie('The Matrix', 1999, 'English'); --- error, alredy exists
SELECT public.new_movie(''); --error, title cannot be null
SELECT public.new_movie('Avatar', 2009, 'Navi'); 