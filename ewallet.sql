-- CREATE DATABASE ewallet;

-- CREATE TABLE users(
--   id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
--   username VARCHAR(100) NOT NULL,
--   name VARCHAR(100) NOT NULL,
--   phone VARCHAR(20) NOT NULL,
--   email VARCHAR(255) NOT NULL CHECK (email LIKE '%@%'),
--   password VARCHAR(255) NOT NULL,
--   photo TEXT, 
--   pin SMALLINT
-- );

-- CREATE TABLE ewallet(
--   id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--   user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--   balance NUMERIC(10,2) NOT NULL,
--   created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
-- );

-- CREATE TABLE transactions(
--   id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--   sender_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--   receiver_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--   amount NUMERIC(10,2) NOT NULL,
--   type VARCHAR(50) NOT NULL, 
--   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--   updated_at TIMESTAMP DEFAULT NULL
-- );

-- INSERT INTO users (email, password, name, photo, phone, username, pin) 
-- VALUES 
-- ('budi@email.com', 'hash_password_budi_123', 'Budi Santoso', 'https://example.com', '08777777778', 'budisan', 1234),
-- ('siti@email.com', 'hash_password_siti_456', 'Siti Rahma', 'https://example.com', '08777777779', 'siti', 5678),
-- ('andi@email.com', 'hash_password_andi_789', 'Andi Wijaya', NULL, '0877555578', 'andi', 9999);

-- INSERT INTO ewallet (balance, user_id) 
-- VALUES 
-- (500000.00, 1),
-- (1500000.00, 2),
-- (75000.00, 3);

-- INSERT INTO transactions (sender_id, receiver_id, amount, type) 
-- VALUES 
-- (1, 2, 50000.00, 'income'),
-- (2, 3, 100000.00, 'expenses'),
-- (3, 1, 25000.00, 'merchant');

-- LOGIN
SELECT * FROM users WHERE email = 'siti@email.com' AND password = 'hash_pasword' LIMIT 1;
-- REGISTER
INSERT INTO users (email, password, name, photo, pin, username, phone) VALUES 
('chandra@email.com', 'hash_password_chandra', 'Chandra Santoso', 'https://example.com', 1234, 'chandra', '08787813123');
-- GET USER INFORMATION
SELECT username, email, photo FROM users WHERE id = 1;
---CHECK PIN USER
SELECT * FROM users where pin = 2222;
-- GET TRANSACTION HISTORY
SELECT * FROM transactions;
-- GET USER HISTORY WITH OPTION INCOME/EXPENSE, DATE RANGE
SELECT * FROM transactions 
WHERE (sender_id = 1 OR receiver_id = 1) 
AND (type = 'income' OR type = 'expenses') 
AND created_at BETWEEN '2026-10-22' AND '2026-10-23';
--  GET USER ACCOUNT INFORMATION (balance, income, expenses)
SELECT u.name, COALESCE(e.balance, 0) AS balance,  
COALESCE(SUM(CASE WHEN t.receiver_id = u.id THEN t.amount ELSE 0 END),0) AS total_income,
COALESCE(SUM(CASE WHEN t.sender_id = u.id THEN t.amount ELSE 0 END), 0) AS total_expense
FROM ewallet e
JOIN users u ON u.id = e.user_id
JOIN transactions t ON t.sender_id = u.id OR t.receiver_id = u.id
WHERE u.id = 1
GROUP BY u.name, e.balance;

-- FIND RECEIVER WITH PAGINATION
SELECT * FROM transactions WHERE receiver_id = 1
LIMIT 10
OFFSET 0;
-- ADD TRANSACTION/TOPUP
INSERT INTO transactions(sender_id, receiver_id, amount, type) VALUES(1,1,1000.00, 'topup')
-- GET USER PROFILE
SELECT photo, name, photo, phone, email FROM users WHERE id = 1;
-- CHANGE PIN
UPDATE  users SET pin = '2222' WHERE id = 1;
-- CHANGE PASSWORD
UPDATE  users SET password = 'hash_password_terbaru' WHERE id = 1;  
-- CHANGE USER PROFILE
UPDATE  users SET 
name = 'Budi Handuk',
email = 'email@terbaru.com',
phone = '0921313123'
WHERE id = 1;  
