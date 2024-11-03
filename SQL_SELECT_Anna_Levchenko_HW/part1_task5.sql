SELECT 
    c.customer_id,  -- Include customer ID for reference
    CONCAT(UPPER(c.first_name), ' ', UPPER(c.last_name)) AS customer_name,  -- Concatenate first and last names, using UPPER for consistency
    STRING_AGG(f.title, ', ') AS horror_movies,  -- Aggregate horror movie titles into one string
    SUM(p.amount) AS total_amount_paid  -- Sum the payment amounts for the rented horror movies
FROM public.customer AS c  -- Added schema prefix
INNER JOIN public.rental AS r ON c.customer_id = r.customer_id  -- Link customers to their rentals
INNER JOIN public.inventory AS i ON r.inventory_id = i.inventory_id  -- Find which films were rented
INNER JOIN public.film AS f ON i.film_id = f.film_id  -- Get film details
INNER JOIN public.film_category AS fc ON f.film_id = fc.film_id  -- Filter for horror category
INNER JOIN public.category AS ca ON fc.category_id = ca.category_id  -- Get the horror category
INNER JOIN public.payment AS p ON r.rental_id = p.rental_id  -- Get payment details for rentals
WHERE UPPER(ca.name) = 'HORROR'  -- Filter for horror category, using UPPER for case-insensitivity
GROUP BY c.customer_id, c.first_name, c.last_name  -- Group by customer ID and name to aggregate results
ORDER BY customer_name;  -- Order results by customer name (optional)
