-- Select the concatenated address and total revenue for each rental store
SELECT 
    CONCAT(a.address, ' ', COALESCE(a.address2, '')) AS full_address,  -- Concatenates address and address2, using COALESCE to handle NULLs
    SUM(p.amount) AS revenue  -- Sums the payment amounts to get the total revenue for each store
FROM store s
-- LEFT JOIN with address table to get the address of each store
-- LEFT JOIN is used because every store should appear even if address2 is NULL
LEFT JOIN address a ON s.address_id = a.address_id 

-- INNER JOIN with inventory table because each store is linked to its inventory
INNER JOIN inventory i ON s.store_id = i.store_id 

-- INNER JOIN with rental table because every rental must have an associated inventory item
INNER JOIN rental r ON i.inventory_id = r.inventory_id 

-- INNER JOIN with payment table to calculate revenue
-- Only rentals that resulted in a payment are needed, so INNER JOIN ensures we only consider paid rentals
INNER JOIN payment p ON r.rental_id = p.rental_id 

-- Filter for payments made since March 1, 2017
WHERE p.payment_date >= '2017-03-01' 

-- Group by address fields to calculate the total revenue for each store
GROUP BY a.address, a.address2 

-- Order the results by revenue in descending order to show stores with the highest revenue first
ORDER BY revenue DESC;

