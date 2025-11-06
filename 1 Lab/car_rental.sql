DROP TABLE IF EXISTS Payment, Rental, Employee, Customer, Car, Model, Branch CASCADE;

CREATE TABLE Branch (
    branch_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL
);

CREATE TABLE Model (
    model_id SERIAL PRIMARY KEY,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL
);

CREATE TABLE Car (
    car_id SERIAL PRIMARY KEY,
    model_id INT REFERENCES Model(model_id),
    branch_id INT REFERENCES Branch(branch_id),
    registration_number VARCHAR(20) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'available'
);

CREATE TABLE Customer (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE
);

CREATE TABLE Employee (
    employee_id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES Branch(branch_id),
    name VARCHAR(100) NOT NULL
);

CREATE TABLE Rental (
    rental_id SERIAL PRIMARY KEY,
    car_id INT REFERENCES Car(car_id),
    customer_id INT REFERENCES Customer(customer_id),
    employee_id INT REFERENCES Employee(employee_id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total NUMERIC(8,2) CHECK (total >= 0)
);

CREATE TABLE Payment (
    payment_id SERIAL PRIMARY KEY,
    rental_id INT REFERENCES Rental(rental_id),
    amount NUMERIC(8,2) CHECK (amount > 0),
    payment_date DATE DEFAULT CURRENT_DATE
);