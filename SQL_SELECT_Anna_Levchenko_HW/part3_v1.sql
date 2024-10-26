-- V1: Find actors who have not acted for the longest time (gap from latest release year to the current year)
SELECT 
    a.actor_id,  -- Actor ID
    CONCAT(a.first_name, ' ', a.last_name) AS actor_name,  -- Actor's full name
    MAX(f.release_year) AS latest_release_year,  -- Find the most recent movie release year for the actor
    (2024 - MAX(f.release_year)) AS years_since_last_film  -- Calculate the gap from the current year (2024)
FROM actor a

-- INNER JOIN film_actor to relate actors with films
INNER JOIN film_actor fa ON a.actor_id = fa.actor_id

-- INNER JOIN film to get release year
INNER JOIN film f ON fa.film_id = f.film_id

-- Group by each actor
GROUP BY a.actor_id, a.first_name, a.last_name

-- Sort by the largest gap in descending order
ORDER BY years_since_last_film DESC;
