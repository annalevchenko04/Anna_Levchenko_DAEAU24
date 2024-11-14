-- Insert favorite movies into the film table
BEGIN;

INSERT INTO dvdrental.film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features, last_update)
SELECT movie.title, movie.description, movie.release_year, lang.language_id, lang.language_id, movie.rental_duration, movie.rental_rate, movie.length, movie.replacement_cost, movie.rating::dvdrental.mpaa_rating, movie.special_features::text[], CURRENT_DATE
FROM (VALUES 
    ('Coco', 'A story of a young boy who wants to be a musician...', 2010, 7, 4.99, 148, 19.99, 'PG-13'::dvdrental.mpaa_rating, ARRAY['Trailers']::text[]),
    ('Spotlight', 'Sacha Pfeiffer interview victims and try to unseal sensitive documents.', 2001, 14, 9.99, 142, 19.99, 'R'::dvdrental.mpaa_rating, ARRAY['Commentaries']::text[]),
    ('Little Women', 'Amy has a chance encounter with Theodore...', 2019, 21, 19.99, 175, 19.99, 'R'::dvdrental.mpaa_rating, ARRAY['Deleted Scenes']::text[])
) AS movie (title, description, release_year, rental_duration, rental_rate, length, replacement_cost, rating, special_features)
JOIN dvdrental.language lang ON LOWER(lang.name) = LOWER('English')
WHERE NOT EXISTS (SELECT 1 FROM dvdrental.film f WHERE LOWER(f.title) = LOWER(movie.title))
RETURNING film_id;

COMMIT;

**********************************************************************************************************************

BEGIN;

-- Insert actors into the dvdrental.actor table using a single insert
INSERT INTO dvdrental.actor (first_name, last_name, last_update)
SELECT actor.first_name, actor.last_name, CURRENT_DATE
FROM (VALUES 
    ('Leonardo', 'DiCaprio'),
    ('Joseph', 'Gordon-Levitt'),
    ('Morgan', 'Freeman'),
    ('Tim', 'Robbins'),
    ('Marlon', 'Brando'),
    ('Al', 'Pacino')
) AS actor (first_name, last_name)
WHERE NOT EXISTS (
    SELECT 1 FROM dvdrental.actor a 
    WHERE LOWER(a.first_name) = LOWER(actor.first_name) 
    AND LOWER(a.last_name) = LOWER(actor.last_name)
)
RETURNING actor_id;

-- Map actors to films in the dvdrental.film_actor table
INSERT INTO dvdrental.film_actor (film_id, actor_id, last_update)
SELECT f.film_id, a.actor_id, CURRENT_DATE
FROM dvdrental.film f
JOIN dvdrental.actor a ON (
        (LOWER(a.first_name) = (LOWER('leonardo') AND LOWER(a.last_name) = LOWER('dicaprio') AND LOWER(f.title) = LOWER('coco'))
     OR (LOWER(a.first_name) = (LOWER('joseph') AND LOWER(a.last_name) = LOWER('gordon-levitt') AND LOWER(f.title) = LOWER('coco'))
     OR (LOWER(a.first_name) = (LOWER('morgan') AND LOWER(a.last_name) = LOWER('freeman') AND LOWER(f.title) = LOWER('spotlight'))
     OR (LOWER(a.first_name) = (LOWER('tim') AND LOWER(a.last_name) = LOWER('robbins') AND LOWER(f.title) = LOWER('spotlight'))
     OR (LOWER(a.first_name) = (LOWER('marlon') AND LOWER(a.last_name) = LOWER('brando') AND LOWER(f.title) = LOWER('little women'))
     OR (LOWER(a.first_name) = (LOWER('al') AND LOWER(a.last_name) = LOWER('pacino') AND LOWER(f.title) = LOWER('little women'))
)
WHERE NOT EXISTS (
    SELECT 1 FROM dvdrental.film_actor fa 
    WHERE fa.film_id = f.film_id AND fa.actor_id = a.actor_id
)
RETURNING film_id, actor_id;

COMMIT;

**********************************************************************************************************************
-- Insert movies into the inventory of a specific store

BEGIN;

INSERT INTO dvdrental.inventory (film_id, store_id, last_update)
SELECT f.film_id, store.store_id, CURRENT_DATE
FROM dvdrental.film f
JOIN (VALUES ('Coco'), ('Spotlight'), ('Little Women')) AS movies(title) 
    ON LOWER(f.title) = LOWER(movies.title)
JOIN (
    SELECT store_id
    FROM dvdrental.store
    ORDER BY RANDOM()  -- Randomly order the stores
    LIMIT 1  -- Select only one store at random
) AS store
ON TRUE  -- Join to ensure the random store is used
WHERE NOT EXISTS (
    SELECT 1 
    FROM dvdrental.inventory i
    WHERE i.film_id = f.film_id AND i.store_id = store.store_id
)
RETURNING inventory_id;  -- Return inventory_id of inserted rows for confirmation

COMMIT;


*************************************************************************************************************************
-- Start a transaction to ensure atomic updates
BEGIN;

-- Step 1: Identify a customer with at least 43 rental and payment records
WITH target_customer AS (
    SELECT c.customer_id, c.first_name, c.last_name
    FROM dvdrental.customer c
    JOIN dvdrental.rental r ON c.customer_id = r.customer_id
    JOIN dvdrental.payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
    LIMIT 1  -- Get only one customer
),
-- Step 2: Select an existing address from the address table
target_address AS (
    SELECT address_id
    FROM dvdrental.address
    LIMIT 1  -- Get one address
)
-- Step 3: Update the identified customer with new personal data
UPDATE dvdrental.customer
SET first_name = 'Anna',  
    last_name = 'Levchenko',    
    address_id = (SELECT address_id FROM target_address),  -- Use the address from the address table
    last_update = CURRENT_DATE  -- Set last_update to current date
WHERE customer_id = (SELECT customer_id FROM target_customer)
RETURNING customer_id;  -- Return the updated customer_id for confirmation

-- Commit the transaction to apply changes
COMMIT;

*************************************************************************************************************************


BEGIN;

-- Check if the customer exists (case-insensitive)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM dvdrental.customer
        WHERE LOWER(first_name) = LOWER('Anna') AND LOWER(last_name) = LOWER('Levchenko')
    ) THEN

        -- Step 2: Delete from the payment table related to the customer's rentals
        DELETE FROM dvdrental.payment
        WHERE rental_id IN (
            SELECT r.rental_id
            FROM dvdrental.rental r
            JOIN dvdrental.customer c ON r.customer_id = c.customer_id
            WHERE LOWER(c.first_name) = LOWER('Anna') AND LOWER(c.last_name) = LOWER('Levchenko')
        );

        -- Step 3: Delete from the rental table related to Anna Levchenko
        DELETE FROM dvdrental.rental
        WHERE customer_id = (
            SELECT customer_id
            FROM dvdrental.customer
            WHERE LOWER(first_name) = LOWER('Anna') AND LOWER(last_name) = LOWER('Levchenko')
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
    FROM dvdrental.film f
    JOIN dvdrental.inventory i ON f.film_id = i.film_id
    WHERE LOWER(f.title) IN (LOWER('Coco'), LOWER('Spotlight'), LOWER('Little Women'))
),
customer_info AS (
    SELECT customer_id
    FROM dvdrental.customer
    WHERE LOWER(first_name) = LOWER('Anna') AND LOWER(last_name) = LOWER('Levchenko')
),
staff_info AS (
    SELECT staff_id
    FROM dvdrental.staff
    ORDER BY staff_id
    LIMIT 1
),
inserted_rentals AS (
    -- Insert rental records and return rental IDs
    INSERT INTO dvdrental.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    SELECT 
        CURRENT_DATE,                   -- rental_date set to today
        fm.inventory_id,                -- inventory_id for each movie
        ci.customer_id,                 -- customer_id 
        NULL,                           -- return_date initially NULL
        si.staff_id,                    -- staff_id dynamically fetched
        CURRENT_DATE                    -- last_update set to today
    FROM favorite_movies fm
    CROSS JOIN customer_info ci
    CROSS JOIN staff_info si
    WHERE NOT EXISTS (
        -- Avoid duplicate rentals by ensuring this rental does not already exist
        SELECT 1 
        FROM dvdrental.rental r 
        WHERE r.inventory_id = fm.inventory_id AND r.customer_id = ci.customer_id
    )
    RETURNING rental_id, inventory_id, customer_id
)
-- Step 2: Insert payment records based on the inserted rentals
INSERT INTO dvdrental.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 
    ir.customer_id,                 -- customer_id from inserted_rentals CTE
    si.staff_id,                     -- staff_id from staff_info CTE
    ir.rental_id,                    -- rental_id from inserted_rentals CTE
    f.rental_rate,                   -- rental rate from film
    DATE '2017-01-26'                -- set payment_date as "records for the first half of 2017"
FROM inserted_rentals ir
JOIN dvdrental.inventory i ON ir.inventory_id = i.inventory_id
JOIN dvdrental.film f ON i.film_id = f.film_id
CROSS JOIN staff_info si
WHERE NOT EXISTS (
    -- Avoid duplicate payments by ensuring this payment does not already exist
    SELECT 1
    FROM dvdrental.payment p
    WHERE p.customer_id = ir.customer_id AND p.rental_id = ir.rental_id
)
RETURNING payment_id;
-- Commit the transaction to apply changes

COMMIT;
**********************************************************************************************************************

