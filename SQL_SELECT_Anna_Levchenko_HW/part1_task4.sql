-- Retrieve the number of Drama, Travel, and Documentary movies per year
SELECT 
    f.release_year,
    COALESCE(SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END), 0) AS number_of_drama_movies,   -- Count of Drama movies
    COALESCE(SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END), 0) AS number_of_travel_movies,   -- Count of Travel movies
    COALESCE(SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END), 0) AS number_of_documentary_movies  -- Count of Documentary movies
FROM film f

-- INNER JOIN with film_category to link films to their categories
INNER JOIN film_category fc ON f.film_id = fc.film_id

-- INNER JOIN with category to filter by specific categories
INNER JOIN category c ON fc.category_id = c.category_id

-- Group by release year to aggregate the counts
GROUP BY f.release_year

-- Sort by release year in descending order
ORDER BY f.release_year DESC;
