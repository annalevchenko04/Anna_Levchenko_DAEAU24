-- Insert favorite movies into the film table
INSERT INTO film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features, last_update)
SELECT 'Coco', 'A story of a young boy who wants to be a musician and somehow finds himself communing with talking skeletons in the land of the dead.', 2010, 1, 1, 7, 4.99, 148, 19.99, 'PG-13', '{Trailers}', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'Coco')
RETURNING film_id;

INSERT INTO film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features, last_update)
SELECT 'Spotlight', 'Sacha Pfeiffer interview victims and try to unseal sensitive documents.', 2001, 1, 1, 14, 9.99, 142, 19.99, 'R', '{Commentaries}', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'Spotlight')
RETURNING film_id;

INSERT INTO film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features, last_update)
SELECT 'Little Women', 'Amy has a chance encounter with Theodore, a childhood crush who proposed to Jo but was ultimately rejected.', 2019, 1, 1, 21, 19.99, 175, 19.99, 'R', '{Deleted Scenes}', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'Little Women')
RETURNING film_id;


**********************************************************************************************************************

-- Insert actors into the actor table
INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Leonardo', 'DiCaprio', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Leonardo' AND last_name = 'DiCaprio');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Joseph', 'Gordon-Levitt', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Joseph' AND last_name = 'Gordon-Levitt');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Morgan', 'Freeman', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Morgan' AND last_name = 'Freeman');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Tim', 'Robbins', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Tim' AND last_name = 'Robbins');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Marlon', 'Brando', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Marlon' AND last_name = 'Brando');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Al', 'Pacino', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Al' AND last_name = 'Pacino');


-- Map actors to films in the film_actor table
INSERT INTO film_actor (film_id, actor_id, last_update)
SELECT f.film_id, a.actor_id, CURRENT_DATE
FROM film f
JOIN actor a ON (a.first_name = 'Leonardo' AND a.last_name = 'DiCaprio' AND f.title = 'Coco')
   OR (a.first_name = 'Joseph' AND a.last_name = 'Gordon-Levitt' AND f.title = 'Coco')
   OR (a.first_name = 'Morgan' AND a.last_name = 'Freeman' AND f.title = 'Spotlight')
   OR (a.first_name = 'Tim' AND a.last_name = 'Robbins' AND f.title = 'Spotlight')
   OR (a.first_name = 'Marlon' AND a.last_name = 'Brando' AND f.title = 'Little Women')
   OR (a.first_name = 'Al' AND a.last_name = 'Pacino' AND f.title = 'Little Women')
WHERE NOT EXISTS (SELECT 1 FROM film_actor WHERE film_id = f.film_id AND actor_id = a.actor_id);



**********************************************************************************************************************
-- Insert movies into the inventory of a specific store

-- Add Coco to store inventory
INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id, 1, CURRENT_DATE
FROM film f
WHERE f.title = 'Coco'
AND NOT EXISTS (
    SELECT 1 FROM inventory i 
    WHERE i.film_id = f.film_id AND i.store_id = 1
)
RETURNING inventory_id;  -- Get the inventory_id of the inserted row

-- Add Spotlight to store inventory
INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id, 1, CURRENT_DATE
FROM film f
WHERE f.title = 'Spotlight'
AND NOT EXISTS (
    SELECT 1 FROM inventory i 
    WHERE i.film_id = f.film_id AND i.store_id = 1
)
RETURNING inventory_id;  -- Get the inventory_id of the inserted row

-- Add Little Women to store inventory
INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id, 1, CURRENT_DATE
FROM film f
WHERE f.title = 'Little Women'
AND NOT EXISTS (
    SELECT 1 FROM inventory i 
    WHERE i.film_id = f.film_id AND i.store_id = 1
)
RETURNING inventory_id;  -- Get the inventory_id of the inserted row



*************************************************************************************************************************

-- Start a transaction to ensure atomic updates
BEGIN;

-- Step 1: Identify a customer with at least 43 rental and payment records
WITH target_customer AS (
    SELECT c.customer_id, c.first_name, c.last_name
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
    LIMIT 1  -- Get only one customer
),

-- Step 2: Select an existing address from the address table
target_address AS (
    SELECT address_id
    FROM address
    LIMIT 1  -- Get one address
)

-- Step 3: Update the identified customer with new personal data
UPDATE customer
SET first_name = 'Anna',  
    last_name = 'Levchenko',    
    address_id = (SELECT address_id FROM target_address),  -- Use the address from the address table
    last_update = CURRENT_DATE  -- Set last_update to current date
WHERE customer_id = (SELECT customer_id FROM target_customer);


-- Commit the transaction to apply changes
COMMIT;

*************************************************************************************************************************


BEGIN;

-- Check if the customer exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM customer
        WHERE first_name = 'Anna' AND last_name = 'Levchenko'
    ) THEN

        -- Step 2: Delete from the payment table related to the customer's rentals
        DELETE FROM payment
        WHERE rental_id IN (
            SELECT r.rental_id
            FROM rental r
            WHERE r.customer_id = (
                SELECT customer_id
                FROM customer
                WHERE first_name = 'Anna' AND last_name = 'Levchenko'
            )
        );

        -- Step 3: Delete from the rental table related to Anna Levchenko
        DELETE FROM rental
        WHERE customer_id = (
            SELECT customer_id
            FROM customer
            WHERE first_name = 'Anna' AND last_name = 'Levchenko'
        );

    ELSE
        RAISE NOTICE 'Customer Anna Levchenko does not exist.';
    END IF;
END $$;

-- Commit the transaction to apply changes
COMMIT;

**********************************************************************************************************************


BEGIN;

-- Step 1: Define CTEs and insert into both rental and payment tables
WITH favorite_movies AS (
    SELECT f.film_id, i.inventory_id
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    WHERE f.title IN ('Coco', 'Spotlight', 'Little Women')
),
customer_info AS (
    SELECT customer_id
    FROM customer
    WHERE first_name = 'Anna' AND last_name = 'Levchenko'
),
staff_info AS (
    SELECT staff_id
    FROM staff
    ORDER BY staff_id
    LIMIT 1
),
inserted_rentals AS (
    -- Insert rental records and return rental IDs
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    SELECT 
        CURRENT_DATE,                   -- rental_date set to today
        fm.inventory_id,                -- inventory_id for each movie
        ci.customer_id,                 -- my customer_id 
        NULL,                           -- return_date initially NULL
        si.staff_id,                    -- staff_id dynamically fetched
        CURRENT_DATE                    -- last_update set to today
    FROM favorite_movies fm
    CROSS JOIN customer_info ci
    CROSS JOIN staff_info si
    WHERE NOT EXISTS (
        -- Avoid duplicate rentals by ensuring this rental does not already exist
        SELECT 1 
        FROM rental r 
        WHERE r.inventory_id = fm.inventory_id AND r.customer_id = ci.customer_id
    )
    RETURNING rental_id, inventory_id, customer_id
)

-- Step 2: Insert payment records based on the inserted rentals
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 
    ir.customer_id,                 -- customer_id from inserted_rentals CTE
    si.staff_id,                    -- staff_id from staff_info CTE
    ir.rental_id,                   -- rental_id from inserted_rentals CTE
    f.rental_rate,                  -- rental rate from film
    DATE '2017-01-26'               -- set payment_date as "records for the first half of 2017"
FROM inserted_rentals ir
JOIN inventory i ON ir.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
CROSS JOIN staff_info si
WHERE NOT EXISTS (
    -- Avoid duplicate payments by ensuring this payment does not already exist
    SELECT 1
    FROM payment p
    WHERE p.customer_id = ir.customer_id AND p.rental_id = ir.rental_id
)
RETURNING payment_id;

-- Commit the transaction to apply changes
COMMIT;

**********************************************************************************************************************

