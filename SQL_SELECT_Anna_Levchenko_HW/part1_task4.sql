SELECT 
    f.release_year,
    COALESCE(SUM(CASE WHEN UPPER(c.name) = 'DRAMA' THEN 1 ELSE 0 END), 0) AS number_of_drama_movies,   -- Count of Drama movies, case-insensitive
    COALESCE(SUM(CASE WHEN UPPER(c.name) = 'TRAVEL' THEN 1 ELSE 0 END), 0) AS number_of_travel_movies,  -- Count of Travel movies, case-insensitive
    COALESCE(SUM(CASE WHEN UPPER(c.name) = 'DOCUMENTARY' THEN 1 ELSE 0 END), 0) AS number_of_documentary_movies  -- Count of Documentary movies, case-insensitive
FROM public.film AS f  -- Added schema prefix
INNER JOIN public.film_category AS fc ON f.film_id = fc.film_id  -- Link films to their categories
INNER JOIN public.category AS c ON fc.category_id = c.category_id  -- Filter by specific categories
GROUP BY f.release_year  -- Group by release year to aggregate the counts
ORDER BY f.release_year DESC;  -- Sort by release year in descending order
