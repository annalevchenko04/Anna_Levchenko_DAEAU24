-- V1: Find actors who have not acted for the longest time (gap from latest release year to the current year)
WITH ActorGaps AS (
    SELECT 
        a.actor_id,  -- Actor ID
        CONCAT(a.first_name, ' ', a.last_name) AS actor_name,  -- Actor's full name
        COALESCE(MAX(f.release_year), 0) AS latest_release_year,  -- Find the most recent movie release year for the actor
        (EXTRACT(YEAR FROM CURRENT_DATE) - COALESCE(MAX(f.release_year), EXTRACT(YEAR FROM CURRENT_DATE))) AS years_since_last_film  -- Calculate the gap from the current year dynamically
    FROM public.actor AS a  -- Added schema prefix

    -- LEFT JOIN to include all actors, even those without films
    LEFT JOIN public.film_actor AS fa ON a.actor_id = fa.actor_id

    -- LEFT JOIN film to get release year, ensuring actors without films are included
    LEFT JOIN public.film AS f ON fa.film_id = f.film_id

    -- Group by actor ID for uniqueness
    GROUP BY a.actor_id
)

SELECT 
    actor_id, 
    actor_name, 
    latest_release_year, 
    years_since_last_film
FROM ActorGaps
-- Filter to get only those actors with the maximum gap
WHERE years_since_last_film = (SELECT MAX(years_since_last_film) FROM ActorGaps)
ORDER BY actor_name; 