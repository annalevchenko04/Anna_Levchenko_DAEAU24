-- Retrieve top-5 actors by the number of movies they participated in since 2015
SELECT 
    a.first_name, 
    a.last_name, 
    COUNT(f.film_id) AS number_of_movies
FROM actor a

-- INNER JOIN with film_actor to link actors to their films
INNER JOIN film_actor fa ON a.actor_id = fa.actor_id

-- INNER JOIN with film to get the film details and filter by release year
INNER JOIN film f ON fa.film_id = f.film_id

-- Filter for films released since 2015
WHERE f.release_year >= 2015

-- Group by actor's first and last name to count the number of movies per actor
GROUP BY a.first_name, a.last_name

-- Sort by the number of movies in descending order to get top actors
ORDER BY number_of_movies DESC

-- Limit the result to the top 5 actors
LIMIT 5;
