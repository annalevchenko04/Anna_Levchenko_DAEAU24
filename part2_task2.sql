-- Retrieve the top 5 most rented movies and their expected audience age
SELECT 
    f.title,  -- Movie title
    COUNT(r.rental_id) AS rental_count,  -- Total number of rentals
    f.rating,  -- Movie rating
    -- Determine expected audience age based on the rating system
    CASE 
        WHEN f.rating = 'G' THEN 'All ages'
        WHEN f.rating = 'PG' THEN ' Parental guidance suggested: Some material may not be suitable for children.'
        WHEN f.rating = 'PG-13' THEN 'Parents strongly cautioned, suitable for ages 13 and up'
        WHEN f.rating = 'R' THEN 'Restricted, suitable for ages 17 and up'
        WHEN f.rating = 'NC-17' THEN 'Adults only, suitable for ages 18 and up'
        ELSE 'Unknown age rating'  -- In case there are unrated films
    END AS expected_age
FROM public.rental AS r  -- Added schema prefix
INNER JOIN public.inventory AS i ON r.inventory_id = i.inventory_id  -- Link rentals with inventory
INNER JOIN public.film AS f ON i.film_id = f.film_id  -- Get movie details such as title and rating
GROUP BY f.film_id, f.title, f.rating  -- Group by film ID to count rentals for each film
ORDER BY rental_count DESC, f.title ASC  -- Sort by rental count in descending order to get the most rented films
LIMIT 5;  -- Limit the result to the top 5 most rented movies