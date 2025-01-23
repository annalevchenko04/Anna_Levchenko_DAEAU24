-- Retrieve top-5 actors by the number of movies they participated in since 2015
SELECT 
    UPPER(a.first_name) AS first_name,  -- Convert first_name to uppercase for consistency
    UPPER(a.last_name) AS last_name,    -- Convert last_name to uppercase for consistency
    COUNT(f.film_id) AS number_of_movies
FROM public.actor AS a  -- Use schema prefix
INNER JOIN public.film_actor AS fa ON a.actor_id = fa.actor_id  -- Link actors to their films
INNER JOIN public.film AS f ON fa.film_id = f.film_id  -- Get film details and filter by release year
WHERE f.release_year >= 2015
GROUP BY a.actor_id, a.first_name, a.last_name  -- Group by actor_id to uniquely identify each actor
ORDER BY number_of_movies DESC
LIMIT 5;
