--Homework3
-- 1. For each release year, most popular rental film
SELECT f.release_year, f.title, COUNT(r.rental_id) AS rentals
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.release_year, f.title
HAVING COUNT(r.rental_id) = (
    SELECT MAX(cnt)
    FROM (
        SELECT COUNT(r2.rental_id) AS cnt
        FROM film f2
        JOIN inventory i2 ON f2.film_id = i2.film_id
        JOIN rental r2 ON i2.inventory_id = r2.inventory_id
        WHERE f2.release_year = f.release_year
        GROUP BY f2.title
    ) t
)
ORDER BY f.release_year;


-- 2. Top-5 actors who appeared in Comedies most often
SELECT a.first_name, a.last_name, COUNT(*) AS films
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film_category fc ON fa.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE c.name = 'Comedy'
GROUP BY a.actor_id
ORDER BY films DESC
LIMIT 5;

-- 3. Actors who have not starred in Action films
SELECT a.first_name, a.last_name
FROM actor a
WHERE NOT EXISTS (
    SELECT 1
    FROM film_actor fa
    JOIN film_category fc ON fa.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE c.name = 'Action'
      AND fa.actor_id = a.actor_id
);


-- 4. Three most popular rental films by each genre
SELECT c.name AS category, f.title, COUNT(r.rental_id) AS rentals
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY c.name, f.title
HAVING COUNT(r.rental_id) >= (
    SELECT COUNT(r2.rental_id)
    FROM category c2
    JOIN film_category fc2 ON c2.category_id = fc2.category_id
    JOIN film f2 ON fc2.film_id = f2.film_id
    JOIN inventory i2 ON f2.film_id = i2.film_id
    JOIN rental r2 ON i2.inventory_id = r2.inventory_id
    WHERE c2.name = c.name
    GROUP BY f2.title
    ORDER BY COUNT(r2.rental_id) DESC
    OFFSET 2 LIMIT 1
)
ORDER BY category, rentals DESC;

-- 5. Number of films released each year and cumulative total
SELECT f1.release_year,
       COUNT(*) AS films_per_year,
       (
           SELECT COUNT(*)
           FROM film f2
           WHERE f2.release_year <= f1.release_year
       ) AS cumulative_total
FROM film f1
GROUP BY f1.release_year
ORDER BY f1.release_year;


-- 6. Monthly percentage of Animation films from total rentals
SELECT
    month,
    100.0 * animation_rentals / total_rentals AS animation_percent
FROM (
    SELECT
        DATE_TRUNC('month', r.rental_date) AS month,
        COUNT(*) AS total_rentals,
        COUNT(*) FILTER (WHERE c.name = 'Animation') AS animation_rentals
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    GROUP BY month
) t
ORDER BY month;


-- 7. Actors who starred in Action films more than in Drama
SELECT a.first_name, a.last_name
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film_category fc ON fa.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY a.actor_id
HAVING
    SUM(CASE WHEN c.name = 'Action' THEN 1 ELSE 0 END) >
    SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END);

-- 8. Top-5 customers who spent the most money on Comedies
SELECT cu.first_name, cu.last_name, SUM(p.amount) AS total_spent
FROM customer cu
JOIN payment p ON cu.customer_id = p.customer_id
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film_category fc ON i.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE c.name = 'Comedy'
GROUP BY cu.customer_id
ORDER BY total_spent DESC
LIMIT 5;

-- 9. Street types and number of addresses
SELECT
    split_part(address, ' ',
        array_length(string_to_array(address, ' '), 1)
    ) AS street_type,
    COUNT(*) AS total_addresses
FROM address
GROUP BY street_type
ORDER BY total_addresses DESC;

-- 10. Ratings with total films and top-3 categories for each rating
SELECT f.rating,
       COUNT(*) AS total_films,
       c.name AS category,
       COUNT(*) AS category_films
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY f.rating, c.name
HAVING COUNT(*) >= (
    SELECT COUNT(*)
    FROM film f2
    JOIN film_category fc2 ON f2.film_id = fc2.film_id
    JOIN category c2 ON fc2.category_id = c2.category_id
    WHERE f2.rating = f.rating
    GROUP BY c2.name
    ORDER BY COUNT(*) DESC
    OFFSET 2 LIMIT 1
)
ORDER BY f.rating, category_films DESC;

