-- Ensure the user does not already exist, and create the user
DO
$$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'rentaluser'
    ) THEN
        CREATE ROLE rentaluser WITH LOGIN PASSWORD 'rentalpassword';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

GRANT SELECT ON TABLE public.customer TO rentaluser;

SET ROLE rentaluser;

SELECT * FROM public.customer; 

RESET ROLE;

DO
$$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'rental'
    ) THEN
        CREATE ROLE rental;
    END IF;
END
$$;


-- Grant INSERT and UPDATE to the role and assign it to rentaluser
GRANT INSERT, UPDATE ON TABLE public.rental TO rental;

GRANT rental TO rentaluser;

-- Perform operations as rentaluser
SET ROLE rentaluser;

-- Insert a new row into the rental table with random data
INSERT INTO public.rental (rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
VALUES (
    (SELECT COALESCE(MAX(rental_id), 0) + 1 FROM public.rental), -- Automatically generate a new ID
    CURRENT_DATE + (RANDOM() * 30)::INT * INTERVAL '1 day', -- Random rental_date from now to +1 month
    (SELECT inventory_id FROM public.inventory ORDER BY RANDOM() LIMIT 1), -- Random valid inventory_id
    (SELECT customer_id FROM public.customer ORDER BY RANDOM() LIMIT 1),   -- Random valid customer_id
    CURRENT_DATE + ((RANDOM() * 30)::INT + 1) * INTERVAL '1 day', -- Random return_date after rental_date
    (SELECT staff_id FROM public.staff ORDER BY RANDOM() LIMIT 1),         -- Random valid staff_id
    NOW() -- Current timestamp for last_update
)
ON CONFLICT (rental_id) DO NOTHING;

-- Verify the last 5 inserted rows
SELECT * FROM public.rental ORDER BY rental_id DESC LIMIT 5;

-- Update a random row in the rental table
UPDATE public.rental
SET
    return_date = rental_date + (1 + (RANDOM() * 15)::INT) * INTERVAL '1 day', -- Random return_date within 1-15 days after rental_date
    last_update = NOW() -- Set last_update to the current timestamp
WHERE rental_id = (
    SELECT rental_id
    FROM public.rental
    ORDER BY RANDOM()
    LIMIT 1
);

-- Verify the most recently updated rows
SELECT * FROM public.rental
ORDER BY last_update DESC
LIMIT 5;

RESET ROLE;

-- Revoke INSERT permission from rental role
REVOKE INSERT ON TABLE public.rental FROM rental;

-- Verify permissions granted to the rental role
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'rental' AND grantee = 'rental';


CREATE OR REPLACE PROCEDURE create_client_role(
    first_name TEXT,
    last_name TEXT,
    secure_password TEXT DEFAULT 'secure_password'
)
LANGUAGE plpgsql
AS $$
DECLARE
    role_name TEXT;
    customer_id_var INT;
BEGIN
    -- Dynamically generate the role name and fetch the customer_id
    SELECT 'client_' || lower($1) || '_' || lower($2), customer_id
    INTO role_name, customer_id_var
    FROM public.customer c
    WHERE UPPER(c.first_name) = UPPER($1) 
      AND UPPER(c.last_name) = UPPER($2)
      AND EXISTS (SELECT 1 FROM public.payment p WHERE p.customer_id = c.customer_id)
      AND EXISTS (SELECT 1 FROM public.rental r WHERE r.customer_id = c.customer_id);

    -- Ensure the customer exists
    IF customer_id_var IS NULL THEN
        RAISE EXCEPTION 'Customer not found or does not meet the conditions.';
    END IF;

    -- Create the role if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = role_name
    ) THEN
        EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L;', role_name, secure_password);
    END IF;

    -- Grant SELECT privileges on relevant tables to the new role
    EXECUTE format('GRANT SELECT ON public.customer TO %I;', role_name);
    EXECUTE format('GRANT SELECT ON public.payment, public.rental TO %I;', role_name);

    -- Enable Row-Level Security on the payment and rental tables
    EXECUTE 'ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;';
    EXECUTE 'ALTER TABLE public.rental ENABLE ROW LEVEL SECURITY;';

    -- Drop existing RLS policies if they exist
    EXECUTE 'DROP POLICY IF EXISTS client_payment_policy ON public.payment;';
    EXECUTE 'DROP POLICY IF EXISTS client_rental_policy ON public.rental;';

    -- Create RLS policies for customer-specific access
    EXECUTE format('
        CREATE POLICY client_payment_policy
        ON public.payment
        FOR SELECT
        USING (customer_id = %L);', customer_id_var);

    EXECUTE format('
        CREATE POLICY client_rental_policy
        ON public.rental
        FOR SELECT
        USING (customer_id = %L);', customer_id_var);

    RAISE NOTICE 'Role % created and permissions granted successfully.', role_name;
END;
$$;

CALL create_client_role('Maria', 'Miller', 'secure_password');

SET ROLE client_maria_miller;
SELECT * FROM public.rental;
SELECT * FROM public.payment;
SELECT * FROM public.category; ---permission denied



