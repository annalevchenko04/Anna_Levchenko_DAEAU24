SELECT 
    CONCAT(a.address, ' ', COALESCE(a.address2, '')) AS full_address,  -- Concatenate address fields, handling NULLs
    SUM(p.amount) AS revenue  -- Calculate total revenue for each store
FROM public.store AS s
LEFT JOIN public.address AS a ON s.address_id = a.address_id  -- LEFT JOIN with the address table to include all stores, even if they do not have an associated address record
INNER JOIN public.inventory AS i ON s.store_id = i.store_id  -- INNER JOIN for inventory items associated with each store
INNER JOIN public.rental AS r ON i.inventory_id = r.inventory_id  -- INNER JOIN for rentals linked to inventory items
INNER JOIN public.payment AS p ON r.rental_id = p.rental_id  -- INNER JOIN for payments associated with rentals
WHERE p.payment_date >= '2017-03-01'  -- Filter payments by date
GROUP BY s.store_id, a.address, a.address2  -- Group by store ID and address to avoid incorrect aggregations
ORDER BY revenue DESC;  -- Sort by revenue in descending order
