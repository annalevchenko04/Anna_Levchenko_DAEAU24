CREATE TABLE IF NOT EXISTS user_dilab_student51.transaction_report (
    transaction_surr_id BIGINT,
    transaction_src_id VARCHAR(255),
    event_dt_fk BIGINT,
    customer_surr_id BIGINT,
    customer_name VARCHAR(255),
    customer_gender VARCHAR(50),
    customer_age BIGINT,
    location_surr_id BIGINT,
    location_city_name VARCHAR(255),
    location_state_name VARCHAR(255),
    transaction_payment_method_name VARCHAR(255),
    transaction_amount BIGINT,
    transaction_discount BIGINT,
    transaction_total_amount BIGINT,
    ta_insert_dt VARCHAR(255)
);


CREATE OR REPLACE PROCEDURE user_dilab_student51.load_transaction_report()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Disable result caching to ensure accurate timing
    SET enable_result_cache_for_session TO OFF;

    -- Insert the main query results into a report table
    INSERT INTO user_dilab_student51.transaction_report (
        transaction_surr_id,
        transaction_src_id,
        event_dt_fk,
        customer_surr_id,
        customer_name,
        customer_gender,
        customer_age,
        location_surr_id,
        location_city_name,
        location_state_name,
        transaction_payment_method_name,
        transaction_amount,
        transaction_discount,
        transaction_total_amount,
        ta_insert_dt
    )
    SELECT 
        t.transaction_surr_id,
        t.transaction_src_id,
        t.event_dt_fk,
        c.customer_surr_id,
        c.customer_name,
        c.customer_gender,
        c.customer_age,
        l.location_surr_id,
        l.location_city_name,
        l.location_state_name,
        t.transaction_payment_method_name,
        t.transaction_amount,
        t.transaction_discount,
        t.transaction_total_amount,
        t.ta_insert_dt
    FROM user_dilab_student51.transactions t
    JOIN user_dilab_student51.customer c 
        ON t.customer_surr_id_fk = c.customer_surr_id
    JOIN user_dilab_student51.location l
        ON t.location_surr_id_fk = l.location_surr_id
    ORDER BY t.event_dt_fk DESC
    LIMIT 100;
END;
$$;


CALL user_dilab_student51.load_transaction_report();

SELECT * FROM user_dilab_student51.transaction_report;




