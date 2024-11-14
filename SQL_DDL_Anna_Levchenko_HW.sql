-- Database: AuctionHouseDB
DROP DATABASE IF EXISTS "AuctionHouseDB";

CREATE DATABASE "AuctionHouseDB"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- Drop the schema if it exists
DROP SCHEMA IF EXISTS auction CASCADE;

-- Create the auction schema
CREATE SCHEMA auction;

-- Drop tables if they exist
DROP TABLE IF EXISTS auction.Person CASCADE;
DROP TABLE IF EXISTS auction.Category CASCADE;
DROP TABLE IF EXISTS auction.Country CASCADE;
DROP TABLE IF EXISTS auction.City CASCADE;
DROP TABLE IF EXISTS auction.Location CASCADE;
DROP TABLE IF EXISTS auction.AuctionHouse CASCADE;
DROP TABLE IF EXISTS auction.Auction CASCADE;
DROP TABLE IF EXISTS auction.Item CASCADE;
DROP TABLE IF EXISTS auction.Role CASCADE;
DROP TABLE IF EXISTS auction.Employee CASCADE;
DROP TABLE IF EXISTS auction.Bid CASCADE;
DROP TABLE IF EXISTS auction.Payment CASCADE;
DROP TABLE IF EXISTS auction.AuctionItem CASCADE;
DROP TABLE IF EXISTS auction.AuctionRecord CASCADE;

-- Person Table
CREATE TABLE auction.Person (
    person_id SERIAL PRIMARY KEY,  -- Unique identifier for each person
    person_name VARCHAR(50) NOT NULL,  -- Person's first name
    person_surname VARCHAR(50) NOT NULL,  -- Person's last name
    person_contact VARCHAR(100) NOT NULL,  -- Contact information
    is_seller BOOLEAN DEFAULT FALSE NOT NULL,  -- True if person is a seller
    is_buyer BOOLEAN DEFAULT FALSE NOT NULL,  -- True if person is a buyer
    gender VARCHAR(10) CHECK (gender IN ('Male', 'Female', 'Other'))  -- Gender constraint
);

-- Category Table
CREATE TABLE auction.Category (
    category_id SERIAL PRIMARY KEY,  -- Unique identifier for each category
    category_name VARCHAR(50) NOT NULL UNIQUE  -- Name of the category, must be unique
);

-- Country Table
CREATE TABLE auction.Country (
    country_id SERIAL PRIMARY KEY,  -- Unique identifier for each country
    country_name VARCHAR(50) NOT NULL UNIQUE  -- Country name, unique
);

-- City Table
CREATE TABLE auction.City (
    city_id SERIAL PRIMARY KEY,  -- Unique identifier for each city
    country_id INT NOT NULL REFERENCES auction.Country(country_id) ON DELETE CASCADE,  -- References Country, cascades on delete
    city_name VARCHAR(50) NOT NULL
);

-- Location Table
CREATE TABLE auction.Location (
    location_id SERIAL PRIMARY KEY,  -- Unique identifier for each location
    city_id INT NOT NULL REFERENCES auction.City(city_id) ON DELETE CASCADE,  -- References City, cascades on delete
    street VARCHAR(100) NOT NULL,  -- Name of the street
    building INT NOT NULL  -- Building number
);

-- AuctionHouse Table
CREATE TABLE auction.AuctionHouse (
    auction_house_id SERIAL PRIMARY KEY,  -- Unique identifier for each auction house
    auction_house_name VARCHAR(50) NOT NULL,  -- Name of the auction house
    location_id INT NOT NULL REFERENCES auction.Location(location_id) ON DELETE CASCADE  -- References Location, cascades on delete
);

-- Auction Table
CREATE TABLE auction.Auction (
    auction_id SERIAL PRIMARY KEY,  -- Unique identifier for each auction
    auction_date DATE NOT NULL DEFAULT CURRENT_DATE CHECK (auction_date > '2000-01-01'),  -- Auction date, defaults to today
    auction_time TIME NOT NULL DEFAULT CURRENT_TIME,  -- Auction time, defaults to current time
    auction_house_id INT NOT NULL REFERENCES auction.AuctionHouse(auction_house_id) ON DELETE CASCADE,  -- References AuctionHouse
    auction_description TEXT  -- Description of the auction
);

-- Item Table
CREATE TABLE auction.Item (
    item_id SERIAL PRIMARY KEY,  -- Unique identifier for each item
    person_id INT NOT NULL REFERENCES auction.Person(person_id) ON DELETE SET NULL,  -- References seller (Person), sets to NULL on delete
    starting_price INT NOT NULL CHECK (starting_price > 0),  -- Starting price, must be positive
    item_description TEXT,  -- Description of the item
    lot_number INT GENERATED ALWAYS AS (item_id + 1000) STORED,  -- Lot number generated from item_id
    category_id INT REFERENCES auction.Category(category_id) ON DELETE SET NULL  -- References category, sets to NULL on delete
);

-- Role Table
CREATE TABLE auction.Role (
    role_id SERIAL PRIMARY KEY,  -- Unique identifier for each role
    role_name VARCHAR(50) NOT NULL  -- Role name
);

-- Employee Table
CREATE TABLE auction.Employee (
    employee_id SERIAL PRIMARY KEY,  -- Unique identifier for each employee
    employee_name VARCHAR(50) NOT NULL,  -- First name of employee
    employee_surname VARCHAR(50) NOT NULL,  -- Last name of employee
    role_id INT NOT NULL REFERENCES auction.Role(role_id) ON DELETE SET NULL,  -- References Role
    auction_house_id INT NOT NULL REFERENCES auction.AuctionHouse(auction_house_id) ON DELETE SET NULL  -- References AuctionHouse
);

-- Bid Table
CREATE TABLE auction.Bid (
    bid_id SERIAL PRIMARY KEY,  -- Unique identifier for each bid
    item_id INT NOT NULL REFERENCES auction.Item(item_id) ON DELETE CASCADE,  -- References Item, cascades on delete
    person_id INT NOT NULL REFERENCES auction.Person(person_id) ON DELETE CASCADE,  -- References Person (buyer), cascades on delete
    bid_amount INT NOT NULL CHECK (bid_amount > 0),  -- Bid amount, must be positive
    bid_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP CHECK (bid_time > '2000-01-01')  -- Time of bid, defaults to current time, after 2000
);

-- Payment Table
CREATE TABLE auction.Payment (
    payment_id SERIAL PRIMARY KEY,  -- Unique identifier for each payment
    bid_id INT NOT NULL REFERENCES auction.Bid(bid_id) ON DELETE CASCADE,  -- References Bid, cascades on delete
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE CHECK (payment_date > '2000-01-01'),  -- Payment date, defaults to today, after 2000
    payment_amount INT NOT NULL CHECK (payment_amount > 0)  -- Payment amount, non-negative
);

-- AuctionItem Table
CREATE TABLE auction.AuctionItem (
    auction_item_id SERIAL PRIMARY KEY,  -- Unique identifier for each auction item
    auction_id INT NOT NULL REFERENCES auction.Auction(auction_id) ON DELETE CASCADE,  -- References Auction, cascades on delete
    item_id INT NOT NULL REFERENCES auction.Item(item_id) ON DELETE CASCADE,  -- References Item, cascades on delete
    UNIQUE (auction_id, item_id)  -- Ensures each auction_id and item_id pair is unique
);

-- AuctionRecord Table
CREATE TABLE auction.AuctionRecord (
    auction_record_id SERIAL PRIMARY KEY,  -- Unique identifier for each record
    auction_id INT NOT NULL REFERENCES auction.Auction(auction_id) ON DELETE CASCADE,  -- References Auction, cascades on delete
    item_id INT NOT NULL REFERENCES auction.Item(item_id) ON DELETE CASCADE,  -- References Item, cascades on delete
    employee_id INT REFERENCES auction.Employee(employee_id) ON DELETE SET NULL,  -- References Employee
    final_price INT NOT NULL CHECK (final_price > 0),  -- Final selling price, positive
    UNIQUE (auction_id, item_id)  -- Ensures each auction_id and item_id pair is unique
);


-- Insert Sample Data into Country Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.Country WHERE UPPER(country_name) = UPPER('USA')) THEN
        INSERT INTO auction.Country (country_name) VALUES ('USA');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM auction.Country WHERE UPPER(country_name) = UPPER('UK')) THEN
        INSERT INTO auction.Country (country_name) VALUES ('UK');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM auction.Country WHERE UPPER(country_name) = UPPER('Germany')) THEN
        INSERT INTO auction.Country (country_name) VALUES ('Germany');
    END IF;
END $$;

-- Insert Sample Data into City Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.City WHERE UPPER(city_name) = UPPER('New York') AND country_id = (SELECT country_id FROM auction.Country WHERE UPPER(country_name) = UPPER('USA'))) THEN
        INSERT INTO auction.City (country_id, city_name) 
        VALUES ((SELECT country_id FROM auction.Country WHERE UPPER(country_name) = UPPER('USA')), 'New York');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM auction.City WHERE UPPER(city_name) = UPPER('London') AND country_id = (SELECT country_id FROM auction.Country WHERE UPPER(country_name) = UPPER('UK'))) THEN
        INSERT INTO auction.City (country_id, city_name) 
        VALUES ((SELECT country_id FROM auction.Country WHERE UPPER(country_name) = UPPER('UK')), 'London');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM auction.City WHERE UPPER(city_name) = UPPER('Berlin') AND country_id = (SELECT country_id FROM auction.Country WHERE UPPER(country_name) = UPPER('Germany'))) THEN
        INSERT INTO auction.City (country_id, city_name) 
        VALUES ((SELECT country_id FROM auction.Country WHERE UPPER(country_name) = UPPER('Germany')), 'Berlin');
    END IF;
END $$;

-- Insert Sample Data into Location Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.Location WHERE UPPER(street) = UPPER('5th Avenue') AND building = 100) THEN
        INSERT INTO auction.Location (city_id, street, building)
        VALUES ((SELECT city_id FROM auction.City WHERE UPPER(city_name) = UPPER('New York')), '5th Avenue', 100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM auction.Location WHERE UPPER(street) = UPPER('Baker Street') AND building = 221) THEN
        INSERT INTO auction.Location (city_id, street, building)
        VALUES ((SELECT city_id FROM auction.City WHERE UPPER(city_name) = UPPER('London')), 'Baker Street', 221);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM auction.Location WHERE UPPER(street) = UPPER('Unter den Linden') AND building = 50) THEN
        INSERT INTO auction.Location (city_id, street, building)
        VALUES ((SELECT city_id FROM auction.City WHERE UPPER(city_name) = UPPER('Berlin')), 'Unter den Linden', 50);
    END IF;
END $$;

-- Insert Sample Data into AuctionHouse Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.AuctionHouse WHERE UPPER(auction_house_name) = UPPER('Sothebys')) THEN
        INSERT INTO auction.AuctionHouse (location_id, auction_house_name)
        VALUES ((SELECT location_id FROM auction.Location WHERE UPPER(street) = UPPER('5th Avenue') AND building = 100), 'Sothebys');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM auction.AuctionHouse WHERE UPPER(auction_house_name) = UPPER('Christies')) THEN
        INSERT INTO auction.AuctionHouse (location_id, auction_house_name)
        VALUES ((SELECT location_id FROM auction.Location WHERE UPPER(street) = UPPER('Baker Street') AND building = 221), 'Christies');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM auction.AuctionHouse WHERE UPPER(auction_house_name) = UPPER('Phillips')) THEN
        INSERT INTO auction.AuctionHouse (location_id, auction_house_name)
        VALUES ((SELECT location_id FROM auction.Location WHERE UPPER(street) = UPPER('Unter den Linden') AND building = 50), 'Phillips');
    END IF;
END $$;

-- Insert Sample Data into Person Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.Person WHERE UPPER(person_name) = UPPER('John') AND UPPER(person_surname) = UPPER('Doe')) THEN
        INSERT INTO auction.Person (person_name, person_surname, person_contact, is_seller, is_buyer, gender)
        VALUES ('John', 'Doe', 'john.doe@example.com', TRUE, TRUE, 'Male');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.Person WHERE UPPER(person_name) = UPPER('Jane') AND UPPER(person_surname) = UPPER('Smith')) THEN
        INSERT INTO auction.Person (person_name, person_surname, person_contact, is_seller, is_buyer, gender)
        VALUES ('Jane', 'Smith', 'jane.smith@example.com', TRUE, TRUE, 'Female');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.Person WHERE UPPER(person_name) = UPPER('Max') AND UPPER(person_surname) = UPPER('Mustermann')) THEN
        INSERT INTO auction.Person (person_name, person_surname, person_contact, is_seller, is_buyer, gender)
        VALUES ('Max', 'Mustermann', 'max.mustermann@example.com', TRUE, TRUE, 'Male');
    END IF;
END $$;

-- Insert Sample Data into Category Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.Category WHERE UPPER(category_name) = UPPER('Art')) THEN
        INSERT INTO auction.Category (category_name) VALUES ('Art');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM auction.Category WHERE UPPER(category_name) = UPPER('Antiques')) THEN
        INSERT INTO auction.Category (category_name) VALUES ('Antiques');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM auction.Category WHERE UPPER(category_name) = UPPER('Cars')) THEN
        INSERT INTO auction.Category (category_name) VALUES ('Cars');
    END IF;
END $$;

-- Insert Sample Data into Item Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.Item WHERE UPPER(item_description) = UPPER('Painting by Picasso')) THEN
        INSERT INTO auction.Item (person_id, starting_price, item_description, category_id)
        VALUES ((SELECT person_id FROM auction.Person WHERE UPPER(person_name) = UPPER('John') AND UPPER(person_surname) = UPPER('Doe')), 500000, 'Painting by Picasso', (SELECT category_id FROM auction.Category WHERE UPPER(category_name) = UPPER('Art')));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM auction.Item WHERE UPPER(item_description) = UPPER('Antique Vase')) THEN
        INSERT INTO auction.Item (person_id, starting_price, item_description, category_id)
        VALUES ((SELECT person_id FROM auction.Person WHERE UPPER(person_name) = UPPER('Jane') AND UPPER(person_surname) = UPPER('Smith')), 20000, 'Antique Vase', (SELECT category_id FROM auction.Category WHERE UPPER(category_name) = UPPER('Antiques')));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.Item WHERE UPPER(item_description) = UPPER('Classic Car')) THEN
        INSERT INTO auction.Item (person_id, starting_price, item_description, category_id)
        VALUES ((SELECT person_id FROM auction.Person WHERE UPPER(person_name) = UPPER('Max') AND UPPER(person_surname) = UPPER('Mustermann')), 100000, 'Classic Car', (SELECT category_id FROM auction.Category WHERE UPPER(category_name) = UPPER('Cars')));
    END IF;
END $$;

-- Insert Sample Data into Auction Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Auction of Picasso Art')) THEN
        INSERT INTO auction.Auction (auction_date, auction_time, auction_house_id, auction_description)
        VALUES ('2024-11-15', '15:00', (SELECT auction_house_id FROM auction.AuctionHouse WHERE UPPER(auction_house_name) = UPPER('Sothebys')), 'Auction of Picasso Art');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Antique Collection Auction')) THEN
        INSERT INTO auction.Auction (auction_date, auction_time, auction_house_id, auction_description)
        VALUES ('2024-11-20', '14:00', (SELECT auction_house_id FROM auction.AuctionHouse WHERE UPPER(auction_house_name) = UPPER('Christies')), 'Antique Collection Auction');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Luxury Cars Auction')) THEN
        INSERT INTO auction.Auction (auction_date, auction_time, auction_house_id, auction_description)
        VALUES ('2024-11-22', '16:00', (SELECT auction_house_id FROM auction.AuctionHouse WHERE UPPER(auction_house_name) = UPPER('Phillips')), 'Luxury Cars Auction');
    END IF;
END $$;

-- Insert Sample Data into AuctionItem Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.AuctionItem WHERE auction_id = (SELECT auction_id FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Auction of Picasso Art')) AND item_id = (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Painting by Picasso'))) THEN
        INSERT INTO auction.AuctionItem (auction_id, item_id)
        VALUES ((SELECT auction_id FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Auction of Picasso Art')), 
                (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Painting by Picasso')));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.AuctionItem WHERE auction_id = (SELECT auction_id FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Antique Collection Auction')) AND item_id = (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Antique Vase'))) THEN
        INSERT INTO auction.AuctionItem (auction_id, item_id)
        VALUES ((SELECT auction_id FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Antique Collection Auction')), 
                (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Antique Vase')));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.AuctionItem WHERE auction_id = (SELECT auction_id FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Luxury Cars Auction')) AND item_id = (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Classic Car'))) THEN
        INSERT INTO auction.AuctionItem (auction_id, item_id)
        VALUES ((SELECT auction_id FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Luxury Cars Auction')), 
                (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Classic Car')));
    END IF;
END $$;

-- Insert Sample Data into Role Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.Role WHERE UPPER(role_name) = UPPER('Manager')) THEN
        INSERT INTO auction.Role (role_name) VALUES ('Manager');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.Role WHERE UPPER(role_name) = UPPER('Auctioneer')) THEN
        INSERT INTO auction.Role (role_name) VALUES ('Auctioneer');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.Role WHERE UPPER(role_name) = UPPER('Assistant')) THEN
        INSERT INTO auction.Role (role_name) VALUES ('Assistant');
    END IF;
END $$;

-- Insert Sample Data into Employee Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.Employee WHERE UPPER(employee_name) = UPPER('Alice') AND UPPER(employee_surname) = UPPER('Johnson')) THEN
        INSERT INTO auction.Employee (employee_name, employee_surname, role_id, auction_house_id)
        VALUES ('Alice', 'Johnson', 
                (SELECT role_id FROM auction.Role WHERE UPPER(role_name) = UPPER('Manager')), 
                (SELECT auction_house_id FROM auction.AuctionHouse WHERE UPPER(auction_house_name) = UPPER('Sothebys')));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.Employee WHERE UPPER(employee_name) = UPPER('Bob') AND UPPER(employee_surname) = UPPER('Williams')) THEN
        INSERT INTO auction.Employee (employee_name, employee_surname, role_id, auction_house_id)
        VALUES ('Bob', 'Williams', 
                (SELECT role_id FROM auction.Role WHERE UPPER(role_name) = UPPER('Auctioneer')), 
                (SELECT auction_house_id FROM auction.AuctionHouse WHERE UPPER(auction_house_name) = UPPER('Christies')));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.Employee WHERE UPPER(employee_name) = UPPER('Charlie') AND UPPER(employee_surname) = UPPER('Davis')) THEN
        INSERT INTO auction.Employee (employee_name, employee_surname, role_id, auction_house_id)
        VALUES ('Charlie', 'Davis', 
                (SELECT role_id FROM auction.Role WHERE UPPER(role_name) = UPPER('Assistant')), 
                (SELECT auction_house_id FROM auction.AuctionHouse WHERE UPPER(auction_house_name) = UPPER('Phillips')));
    END IF;
END $$;

-- Insert Sample Data into Bid Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.Bid WHERE item_id = (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Painting by Picasso')) AND person_id = (SELECT person_id FROM auction.Person WHERE UPPER(person_name) = UPPER('John') AND UPPER(person_surname) = UPPER('Doe'))) THEN
        INSERT INTO auction.Bid (item_id, person_id, bid_amount)
        VALUES ((SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Painting by Picasso')), 
                (SELECT person_id FROM auction.Person WHERE UPPER(person_name) = UPPER('John') AND UPPER(person_surname) = UPPER('Doe')), 550000);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.Bid WHERE item_id = (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Antique Vase')) AND person_id = (SELECT person_id FROM auction.Person WHERE UPPER(person_name) = UPPER('Jane') AND UPPER(person_surname) = UPPER('Smith'))) THEN
        INSERT INTO auction.Bid (item_id, person_id, bid_amount)
        VALUES ((SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Antique Vase')), 
                (SELECT person_id FROM auction.Person WHERE UPPER(person_name) = UPPER('Jane') AND UPPER(person_surname) = UPPER('Smith')), 25000);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.Bid WHERE item_id = (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Classic Car')) AND person_id = (SELECT person_id FROM auction.Person WHERE UPPER(person_name) = UPPER('Max') AND UPPER(person_surname) = UPPER('Mustermann'))) THEN
        INSERT INTO auction.Bid (item_id, person_id, bid_amount)
        VALUES ((SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Classic Car')), 
                (SELECT person_id FROM auction.Person WHERE UPPER(person_name) = UPPER('Max') AND UPPER(person_surname) = UPPER('Mustermann')), 120000);
    END IF;
END $$;

-- Insert Sample Data into Payment Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.Payment WHERE bid_id = (SELECT bid_id FROM auction.Bid WHERE bid_amount = 550000)) THEN
        INSERT INTO auction.Payment (bid_id, payment_amount)
        VALUES ((SELECT bid_id FROM auction.Bid WHERE bid_amount = 550000), 550000);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.Payment WHERE bid_id = (SELECT bid_id FROM auction.Bid WHERE bid_amount = 25000)) THEN
        INSERT INTO auction.Payment (bid_id, payment_amount)
        VALUES ((SELECT bid_id FROM auction.Bid WHERE bid_amount = 25000), 25000);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.Payment WHERE bid_id = (SELECT bid_id FROM auction.Bid WHERE bid_amount = 120000)) THEN
        INSERT INTO auction.Payment (bid_id, payment_amount)
        VALUES ((SELECT bid_id FROM auction.Bid WHERE bid_amount = 120000), 120000);
    END IF;
END $$;

-- Insert Sample Data into AuctionRecord Table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auction.AuctionRecord WHERE auction_id = (SELECT auction_id FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Auction of Picasso Art')) AND item_id = (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Painting by Picasso'))) THEN
        INSERT INTO auction.AuctionRecord (auction_id, item_id, final_price, employee_id)
        VALUES (
            (SELECT auction_id FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Auction of Picasso Art')), 
            (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Painting by Picasso')), 
            600000,
            (SELECT employee_id FROM auction.Employee WHERE UPPER(employee_name) = UPPER('Alice') AND UPPER(employee_surname) = UPPER('Johnson')) 
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.AuctionRecord WHERE auction_id = (SELECT auction_id FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Antique Collection Auction')) AND item_id = (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Antique Vase'))) THEN
        INSERT INTO auction.AuctionRecord (auction_id, item_id, final_price, employee_id)
        VALUES (
            (SELECT auction_id FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Antique Collection Auction')), 
            (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Antique Vase')), 
            28000,
            (SELECT employee_id FROM auction.Employee WHERE UPPER(employee_name) = UPPER('Bob') AND UPPER(employee_surname) = UPPER('Williams')) 
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auction.AuctionRecord WHERE auction_id = (SELECT auction_id FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Luxury Cars Auction')) AND item_id = (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Classic Car'))) THEN
        INSERT INTO auction.AuctionRecord (auction_id, item_id, final_price, employee_id)
        VALUES (
            (SELECT auction_id FROM auction.Auction WHERE UPPER(auction_description) = UPPER('Luxury Cars Auction')), 
            (SELECT item_id FROM auction.Item WHERE UPPER(item_description) = UPPER('Classic Car')), 
            130000,
            (SELECT employee_id FROM auction.Employee WHERE UPPER(employee_name) = UPPER('Charlie') AND UPPER(employee_surname) = UPPER('Davis')) 
        );
    END IF;
END $$;


-- Add `record_ts` column if it does not already exist in each table

DO $$
BEGIN
    -- Add column to auction.Person table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('Person') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.Person ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;

    -- Add column to auction.Category table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('Category') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.Category ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;

    -- Add column to auction.Item table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('Item') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.Item ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;

    -- Add column to auction.Auction table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('Auction') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.Auction ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;

    -- Add column to auction.AuctionItem table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('AuctionItem') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.AuctionItem ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;

    -- Add column to auction.Bid table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('Bid') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.Bid ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;

    -- Add column to auction.Payment table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('Payment') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.Payment ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;

    -- Add column to auction.AuctionRecord table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('AuctionRecord') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.AuctionRecord ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;

    -- Add column to auction.Employee table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('Employee') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.Employee ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;

    -- Add column to auction.Role table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('Role') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.Role ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;

    -- Add column to auction.AuctionHouse table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('AuctionHouse') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.AuctionHouse ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;

    -- Add column to auction.Location table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('Location') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.Location ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;

    -- Add column to auction.City table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('City') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.City ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;

    -- Add column to auction.Country table if it does not exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE UPPER(table_name) = UPPER('Country') 
                   AND UPPER(column_name) = UPPER('record_ts') 
                   AND UPPER(table_schema) = UPPER('auction')) THEN
        ALTER TABLE auction.Country ADD COLUMN record_ts DATE DEFAULT current_date NOT NULL;
    END IF;
END $$;

