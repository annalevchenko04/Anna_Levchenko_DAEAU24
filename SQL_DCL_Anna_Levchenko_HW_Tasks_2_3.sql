CREATE ROLE rentaluser WITH LOGIN PASSWORD 'rentalpassword';
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

GRANT SELECT ON TABLE dvdrental.customer TO rentaluser;
SELECT * FROM dvdrental.customer;

CREATE ROLE rental;
GRANT rental TO rentaluser;

GRANT INSERT, UPDATE ON TABLE dvdrental.rental TO rental;


INSERT INTO dvdrental.rental (rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
VALUES (
    (SELECT COALESCE(MAX(rental_id), 0) + 1 FROM dvdrental.rental), -- Automatically generate a new ID
    CURRENT_DATE + (RANDOM() * 30)::INT * INTERVAL '1 day', -- Random rental_date from now to +1 month
    (SELECT inventory_id FROM dvdrental.inventory ORDER BY RANDOM() LIMIT 1), -- Random valid inventory_id
    (SELECT customer_id FROM dvdrental.customer ORDER BY RANDOM() LIMIT 1),   -- Random valid customer_id
    CURRENT_DATE + ((RANDOM() * 30)::INT + 1) * INTERVAL '1 day', -- Random return_date after rental_date
    (SELECT staff_id FROM dvdrental.staff ORDER BY RANDOM() LIMIT 1),         -- Random valid staff_id
    NOW() -- Current timestamp for last_update
)
ON CONFLICT (rental_id) DO NOTHING;

SELECT * FROM dvdrental.rental ORDER BY rental_id DESC LIMIT 5;

UPDATE dvdrental.rental
SET
    return_date = rental_date + (1 + (RANDOM() * 15)::INT) * INTERVAL '1 day', -- Random return_date within 1-15 days after rental_date
    last_update = NOW() -- Set last_update to the current timestamp
WHERE rental_id = (
    SELECT rental_id
    FROM dvdrental.rental
    ORDER BY RANDOM()
    LIMIT 1
);

SELECT * FROM dvdrental.rental
ORDER BY last_update DESC
LIMIT 5;

REVOKE INSERT ON TABLE dvdrental.rental FROM rental;

---Verify Permissions-----
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'rental' AND grantee = 'rental';


DO $$
DECLARE
    role_name TEXT;
    customer_id_var INT; 
BEGIN
    -- Dynamically create the role name and get the customer_id
    SELECT 'client_' || lower(first_name) || '_' || lower(last_name), customer_id
    INTO role_name, customer_id_var
    FROM dvdrental.customer
    WHERE UPPER(first_name) = UPPER('Maria') AND UPPER(last_name) = UPPER('Miller')
      AND EXISTS (SELECT 1 FROM dvdrental.payment p WHERE p.customer_id = dvdrental.customer.customer_id)
      AND EXISTS (SELECT 1 FROM dvdrental.rental r WHERE r.customer_id = dvdrental.customer.customer_id);

    -- Create the role if it doesn't already exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = role_name
    ) THEN
        EXECUTE format('CREATE ROLE %I LOGIN PASSWORD ''secure_password'';', role_name);
    END IF;

    -- Grant SELECT permissions on the customer table to the dynamically created role
    EXECUTE format('GRANT SELECT ON dvdrental.customer TO %I;', role_name);

    -- Grant SELECT privileges on payment and rental tables
    EXECUTE format('GRANT SELECT ON dvdrental.payment, dvdrental.rental TO %I;', role_name);

    -- Enable Row-Level Security for the payment and rental tables
    EXECUTE '
        ALTER TABLE dvdrental.payment ENABLE ROW LEVEL SECURITY;
        ALTER TABLE dvdrental.rental ENABLE ROW LEVEL SECURITY;
    ';

    -- Drop the existing policies if they exist
    EXECUTE 'DROP POLICY IF EXISTS client_payment_policy ON dvdrental.payment;';
    EXECUTE 'DROP POLICY IF EXISTS client_rental_policy ON dvdrental.rental;';

    -- Create the RLS policies for both tables to restrict access to own data
    EXECUTE format('
        CREATE POLICY client_payment_policy
        ON dvdrental.payment
        FOR SELECT
        USING (customer_id = %L);', customer_id_var);

    EXECUTE format('
        CREATE POLICY client_rental_policy
        ON dvdrental.rental
        FOR SELECT
        USING (customer_id = %L);', customer_id_var);
END $$;

SET ROLE client_maria_miller;
SELECT * FROM dvdrental.rental;
SELECT * FROM dvdrental.payment;
SELECT * FROM dvdrental.category; ---permission denied



