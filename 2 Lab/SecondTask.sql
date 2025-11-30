
-- 1. CREATE TABLES
CREATE TABLE Orders (
    o_id SERIAL PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE Products (
    p_name TEXT PRIMARY KEY NOT NULL,
    price MONEY NOT NULL
);

CREATE TABLE Order_Items (
    order_id INT NOT NULL,
    product_name TEXT NOT NULL,
    amount NUMERIC(7,2) NOT NULL DEFAULT 1 CHECK (amount > 0),
    PRIMARY KEY (order_id, product_name),
    FOREIGN KEY (order_id) REFERENCES Orders(o_id),
    FOREIGN KEY (product_name) REFERENCES Products(p_name)
);
-- 2. INSERT INITIAL DATA
INSERT INTO Orders (order_date) VALUES ('2025-01-01');
INSERT INTO Orders (order_date) VALUES ('2025-08-09');

INSERT INTO Products (p_name, price) VALUES
('p1', 10),
('p2', 20);

INSERT INTO Order_Items (order_id, product_name) VALUES
(1, 'p1'),
(1, 'p2');

INSERT INTO Order_Items (order_id, product_name, amount) VALUES
(2, 'p1', 3),
(2, 'p2', 5);

-- 3. MODIFY DATABASE STRUCTURE

ALTER TABLE Products
ADD COLUMN p_id SERIAL NOT NULL;


ALTER TABLE Products
ADD CONSTRAINT products_p_id_unique UNIQUE (p_id);


ALTER TABLE Order_Items
ADD COLUMN product_id INT;


UPDATE Order_Items oi
SET product_id = p.p_id
FROM Products p
WHERE oi.product_name = p.p_name;


ALTER TABLE Order_Items
ALTER COLUMN product_id SET NOT NULL;


ALTER TABLE Order_Items
ADD CONSTRAINT order_items_product_fk FOREIGN KEY (product_id)
REFERENCES Products(p_id);


ALTER TABLE Order_Items
DROP COLUMN product_name;


ALTER TABLE Products
DROP CONSTRAINT products_pkey;        

ALTER TABLE Products
ADD CONSTRAINT products_pkey PRIMARY KEY (p_id); 


ALTER TABLE Products
ADD CONSTRAINT products_p_name_unique UNIQUE (p_name);


ALTER TABLE Order_Items
ADD COLUMN price MONEY;

ALTER TABLE Order_Items
ADD COLUMN total MONEY;

UPDATE Order_Items oi
SET price = p.price
FROM Products p
WHERE oi.product_id = p.p_id;

ALTER TABLE Order_Items
ALTER COLUMN price SET NOT NULL;

UPDATE Order_Items
SET total = amount * price;

ALTER TABLE Order_Items
ALTER COLUMN total SET NOT NULL;

ALTER TABLE Order_Items
ADD CONSTRAINT total_check CHECK (total = amount * price);

-- 4. UPDATE DATA

UPDATE Products
SET p_name = 'product1'
WHERE p_name = 'p1';

DELETE FROM Order_Items
WHERE order_id = 1
  AND product_id = (SELECT p_id FROM Products WHERE p_name = 'p2');

DELETE FROM Orders
WHERE o_id = 2;

UPDATE Products
SET price = 5
WHERE p_name = 'product1';

UPDATE Order_Items oi
SET price = p.price,
    total = oi.amount * p.price
FROM Products p
WHERE oi.product_id = p.p_id;

INSERT INTO Orders (order_date)
VALUES (CURRENT_DATE);

INSERT INTO Order_Items (order_id, product_id, amount, price, total)
SELECT
    (SELECT MAX(o_id) FROM Orders),
    p_id,
    3,
    price,
    price * 3
FROM Products
WHERE p_name = 'product1';
