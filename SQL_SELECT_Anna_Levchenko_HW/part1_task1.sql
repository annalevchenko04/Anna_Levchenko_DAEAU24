-- Retrieve the titles, release year, and rental_rate > 1 of animation films released between 2017 and 2019, sort them alphabetically

SELECT 
    f.title, 
    f.release_year, 
    f.rental_rate
FROM film f

-- INNER JOIN is used because every film must belong to a category for this query
INNER JOIN film_category fc ON f.film_id = fc.film_id 

-- INNER JOIN with category to filter by the 'Animation' category
INNER JOIN category c ON fc.category_id = c.category_id 

WHERE c.name = 'Animation'  -- Filter for 'Animation' films only
  AND f.release_year BETWEEN 2017 AND 2019  -- Only include films released between 2017 and 2019
  AND f.rental_rate > 1  -- Include films with rental_rate higher than 1

-- Order by title alphabetically, using field name
ORDER BY f.title ASC;

