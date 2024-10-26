-- Retrieve a list of horror movies rented by each customer and the total amount paid for those rentals
SELECT 
    c.customer_id,  -- Include customer ID for reference
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,  -- Concatenate first and last names
    STRING_AGG(f.title, ', ') AS horror_movies,  -- Aggregate horror movie titles into one string
    SUM(p.amount) AS total_amount_paid  -- Sum the payment amounts for the rented horror movies
FROM customer c

-- INNER JOIN rental to link customers to their rentals
INNER JOIN rental r ON c.customer_id = r.customer_id

-- INNER JOIN inventory to find out which films were rented
INNER JOIN inventory i ON r.inventory_id = i.inventory_id

-- INNER JOIN film to get film details
INNER JOIN film f ON i.film_id = f.film_id

-- INNER JOIN film_category to filter for horror category
INNER JOIN film_category fc ON f.film_id = fc.film_id

-- INNER JOIN category to get the horror category
INNER JOIN category ca ON fc.category_id = ca.category_id

-- INNER JOIN payment to get payment details for rentals
INNER JOIN payment p ON r.rental_id = p.rental_id

-- Filter for horror category
WHERE ca.name = 'Horror'

-- Group by customer to aggregate the horror movies and total payments
GROUP BY c.customer_id, c.first_name, c.last_name

-- Order results by customer name (optional)
ORDER BY customer_name;
