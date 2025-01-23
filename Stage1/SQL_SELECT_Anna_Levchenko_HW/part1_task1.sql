SELECT 
    f.title, 
    f.release_year, 
    f.rental_rate
FROM public.film AS f
INNER JOIN public.film_category AS fc ON f.film_id = fc.film_id
INNER JOIN public.category AS c ON fc.category_id = c.category_id
WHERE UPPER(c.name) = UPPER('animation')  -- Ensure case-insensitive match for 'Animation'
  AND f.release_year BETWEEN 2017 AND 2019
  AND f.rental_rate > 1
ORDER BY f.title ASC;
