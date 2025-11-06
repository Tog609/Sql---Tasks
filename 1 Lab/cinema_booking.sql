DROP TABLE IF EXISTS Ticket, Seat, Show, MovieGenre, Movie, Genre, Hall, Theater, Visitor CASCADE;

CREATE TABLE Theater (
    theater_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL
);

CREATE TABLE Hall (
    hall_id SERIAL PRIMARY KEY,
    theater_id INT REFERENCES Theater(theater_id),
    name VARCHAR(50) NOT NULL,
    capacity INT CHECK (capacity > 0)
);

CREATE TABLE Movie (
    movie_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    duration INT CHECK (duration > 0),
    release_date DATE
);

CREATE TABLE Genre (
    genre_id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE MovieGenre (
    movie_id INT REFERENCES Movie(movie_id),
    genre_id INT REFERENCES Genre(genre_id),
    PRIMARY KEY (movie_id, genre_id)
);

CREATE TABLE Show (
    show_id SERIAL PRIMARY KEY,
    movie_id INT REFERENCES Movie(movie_id),
    hall_id INT REFERENCES Hall(hall_id),
    show_time TIMESTAMP NOT NULL,
    price NUMERIC(6,2) CHECK (price >= 0)
);

CREATE TABLE Seat (
    seat_id SERIAL PRIMARY KEY,
    hall_id INT REFERENCES Hall(hall_id),
    row_number INT NOT NULL,
    seat_number INT NOT NULL,
    UNIQUE (hall_id, row_number, seat_number)
);

CREATE TABLE Visitor (
    visitor_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE
);

CREATE TABLE Ticket (
    ticket_id SERIAL PRIMARY KEY,
    show_id INT REFERENCES Show(show_id),
    seat_id INT REFERENCES Seat(seat_id),
    visitor_id INT REFERENCES Visitor(visitor_id),
    status VARCHAR(20) DEFAULT 'booked'
);