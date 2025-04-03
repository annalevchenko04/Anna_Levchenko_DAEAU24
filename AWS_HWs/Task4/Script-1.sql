CREATE USER 'anna_levchenko'@'%' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON dilab_dev.* TO 'anna_levchenko'@'%';
GRANT ALL PRIVILEGES ON anna_levchenko.* TO 'anna_levchenko'@'%';
FLUSH PRIVILEGES;


DROP DATABASE IF EXISTS anna_levchenko;

CREATE SCHEMA IF NOT EXISTS anna_levchenko;

USE anna_levchenko;

-- Step 2: Create a Table
-- Drop the table if it exists to ensure restartability
DROP TABLE IF EXISTS employees;

-- Create the 'employees' table
CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(10, 2) NOT NULL
);

-- Step 3: Create a View
-- Drop the view if it exists to ensure restartability
DROP VIEW IF EXISTS view_employee_details;

-- Create a view that selects employee details
CREATE VIEW view_employee_details AS
SELECT id, CONCAT(first_name, ' ', last_name) AS full_name, hire_date, salary
FROM employees;

-- Step 4: Drop the procedure if it exists (for restartability)
DROP PROCEDURE IF EXISTS add_employee;

-- Step 5: Change delimiter to $$ for procedure creation
DELIMITER $$

-- Step 6: Create the stored procedure
CREATE PROCEDURE add_employee(
    IN p_first_name VARCHAR(50),
    IN p_last_name VARCHAR(50),
    IN p_hire_date DATE,
    IN p_salary DECIMAL(10, 2)
)
BEGIN
    INSERT INTO employees (first_name, last_name, hire_date, salary)
    VALUES (p_first_name, p_last_name, p_hire_date, p_salary);
END$$

-- Step 7: Reset the delimiter back to the default
DELIMITER ;

-- Step 8: Call the stored procedure with sample data (after creation)
CALL add_employee('John', 'Doe', '2025-04-01', 50000.00);
CALL add_employee('Jane', 'Smith', '2024-05-15', 60000.00);
CALL add_employee('Alice', 'Johnson', '2023-07-20', 55000.00);

