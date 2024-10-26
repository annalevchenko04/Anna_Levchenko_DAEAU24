-- Retrieve the top 5 most rented movies and their expected audience age
SELECT 
    f.title,  -- Movie title
    COUNT(r.rental_id) AS rental_count,  -- Total number of rentals
    f.rating,  -- Movie rating
    -- Determine expected audience age based on the rating system
    CASE 
        WHEN f.rating = 'G' THEN 'All ages'
        WHEN f.rating = 'PG' THEN '8+'
        WHEN f.rating = 'PG-13' THEN '13+'
        WHEN f.rating = 'R' THEN '17+'
        WHEN f.rating = 'NC-17' THEN '18+'
        ELSE 'Unknown age rating'  -- In case there are unrated films
    END AS expected_age
FROM rental r

-- INNER JOIN inventory to link rentals with movies
INNER JOIN inventory i ON r.inventory_id = i.inventory_id

-- INNER JOIN film to get movie details such as title and rating
INNER JOIN film f ON i.film_id = f.film_id

-- Group by movie to count rentals for each film
GROUP BY f.title, f.rating

-- Sort by rental count in descending order to get the most rented films
ORDER BY rental_count DESC

-- Limit the result to the top 5 most rented movies
LIMIT 5;
