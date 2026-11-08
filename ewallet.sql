-- aktifin ekstensi pgcrypto buat nge-hash password dan pin biar aman
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- hapus tabel lama dulu biar bersih pas bikin ulang
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS wallets CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- tabel users: nyimpen akun user, kontak, password sama pin yang udah di-hash
CREATE TABLE users (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    photo TEXT,
    pin VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NULL,
    CONSTRAINT chk_users_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_users_phone CHECK (phone ~ '^[0-9+]{8,20}$')
);

-- tabel wallets: nyimpen saldo tiap user (1 user cuma punya 1 dompet)
CREATE TABLE wallets (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    balance NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NULL,
    CONSTRAINT chk_wallets_balance CHECK (balance >= 0)
);

-- tabel transactions: nyimpen riwayat transaksi top up dan transfer antar user
CREATE TABLE transactions (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sender_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount NUMERIC(15,2) NOT NULL,
    type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NULL,
    CONSTRAINT chk_transactions_amount CHECK (amount > 0),
    CONSTRAINT chk_transactions_type CHECK (type IN ('topup', 'transfer'))
);

-- isi data awal user buat testing, password sama pin langsung di-hash pakai bcrypt
INSERT INTO users (username, name, phone, email, password, photo, pin)
VALUES 
('budisan', 'Budi Santoso', '08777777778', 'budi@email.com', crypt('password_budi_123', gen_salt('bf')), 'https://example.com/budi.jpg', crypt('123456', gen_salt('bf'))),
('siti', 'Siti Rahma', '08777777779', 'siti@email.com', crypt('password_siti_456', gen_salt('bf')), 'https://example.com/siti.jpg', crypt('567890', gen_salt('bf'))),
('andi', 'Andi Wijaya', '08775555780', 'andi@email.com', crypt('password_andi_789', gen_salt('bf')), NULL, crypt('999999', gen_salt('bf')));

-- isi saldo awal dompet masing-masing user
INSERT INTO wallets (user_id, balance)
VALUES 
(1, 475000.00),
(2, 1450000.00),
(3, 175000.00);

-- isi riwayat transaksi awal buat contoh (top up dan transfer)
INSERT INTO transactions (sender_id, receiver_id, amount, type, created_at)
VALUES 
(1, 1, 500000.00, 'topup', '2026-10-20 10:00:00'),
(2, 2, 1500000.00, 'topup', '2026-10-20 11:00:00'),
(3, 3, 100000.00, 'topup', '2026-10-20 12:00:00'),
(1, 2, 50000.00, 'transfer', '2026-10-22 09:30:00'),
(2, 3, 100000.00, 'transfer', '2026-10-22 14:15:00'),
(3, 1, 25000.00, 'transfer', '2026-10-23 16:45:00');

-- 1. LOGIN: cek email dan password, cocokin sama hash di database
SELECT id, username, name, email, photo
FROM users
WHERE email = 'siti@email.com'
  AND password = crypt('password_siti_456', password);

-- 2. REGISTER: bikin akun user baru (password dan pin di-hash) terus langsung bikinin dompetnya
INSERT INTO users (username, name, phone, email, password, photo, pin)
VALUES (
    'chandra',
    'Chandra Santoso',
    '087878131234',
    'chandra@email.com',
    crypt('password_chandra_123', gen_salt('bf')),
    'https://example.com/chandra.jpg',
    crypt('123456', gen_salt('bf'))
);

INSERT INTO wallets (user_id, balance)
VALUES (
    (SELECT id FROM users WHERE email = 'chandra@email.com'),
    0.00
);

-- 3. AMBIL DATA LOGIN USER: ambil username, email, sama foto profil buat sesi login
SELECT id, username, email, photo
FROM users
WHERE id = 1;

-- 4. CEK PIN USER: cocokin pin yang diinput sama hash di database
SELECT id, username, name
FROM users
WHERE id = 1
  AND pin = crypt('123456', pin);

-- 5. RIWAYAT TRANSAKSI: ambil riwayat transaksi user (baik kirim/terima), lengkap sama nama penerima/pengirim dari tabel users
SELECT 
    t.id,
    t.amount,
    t.type,
    t.created_at,
    CASE
        WHEN t.type = 'topup' THEN 'topup'
        WHEN t.receiver_id = 1 THEN 'inflow'
        ELSE 'outflow'
    END AS flow_direction,
    t.sender_id,
    s.name AS sender_name,
    s.email AS sender_email,
    s.phone AS sender_phone,
    t.receiver_id,
    r.name AS recipient_name,
    r.email AS recipient_email,
    r.phone AS recipient_phone,
    r.photo AS recipient_photo
FROM transactions t
JOIN users s ON t.sender_id = s.id
JOIN users r ON t.receiver_id = r.id
WHERE t.sender_id = 1 OR t.receiver_id = 1
ORDER BY t.created_at DESC;

-- 6. RIWAYAT TRANSAKSI MASUK (INFLOW): filter uang masuk (top up dan transferan masuk) berdasarkan rentang tanggal
SELECT 
    t.id,
    t.amount,
    t.type,
    'inflow' AS flow_direction,
    s.name AS sender_name,
    s.email AS sender_email,
    t.created_at
FROM transactions t
JOIN users s ON t.sender_id = s.id
WHERE t.receiver_id = 1
  AND (t.sender_id != 1 OR t.type = 'topup')
  AND t.created_at BETWEEN '2026-10-01 00:00:00' AND '2026-10-31 23:59:59'
ORDER BY t.created_at DESC;

-- 6. RIWAYAT TRANSAKSI KELUAR (OUTFLOW): filter uang keluar (transfer ke orang lain) berdasarkan rentang tanggal
SELECT 
    t.id,
    t.amount,
    t.type,
    'outflow' AS flow_direction,
    r.name AS recipient_name,
    r.email AS recipient_email,
    r.phone AS recipient_phone,
    t.created_at
FROM transactions t
JOIN users r ON t.receiver_id = r.id
WHERE t.sender_id = 1
  AND t.receiver_id != 1
  AND t.created_at BETWEEN '2026-10-01 00:00:00' AND '2026-10-31 23:59:59'
ORDER BY t.created_at DESC;

-- 7. INFORMASI AKUN USER: hitung saldo sekarang, total uang masuk (inflow), dan total uang keluar (outflow)
SELECT 
    u.id,
    u.name,
    COALESCE(w.balance, 0.00) AS balance,
    COALESCE(SUM(
        CASE 
            WHEN t.receiver_id = u.id AND (t.sender_id != u.id OR t.type = 'topup') THEN t.amount 
            ELSE 0.00 
        END
    ), 0.00) AS total_inflow,
    COALESCE(SUM(
        CASE 
            WHEN t.sender_id = u.id AND t.receiver_id != u.id THEN t.amount 
            ELSE 0.00 
        END
    ), 0.00) AS total_outflow
FROM users u
LEFT JOIN wallets w ON w.user_id = u.id
LEFT JOIN transactions t ON t.sender_id = u.id OR t.receiver_id = u.id
WHERE u.id = 1
GROUP BY u.id, u.name, w.balance;

-- 8. CARI PENERIMA TRANSFER: cari user lain langsung dari tabel users pakai pagination
SELECT 
    id,
    username,
    name,
    phone,
    email,
    photo
FROM users
WHERE id != 1
  AND (name ILIKE '%siti%' OR username ILIKE '%siti%' OR phone ILIKE '%siti%')
ORDER BY name ASC
LIMIT 10
OFFSET 0;

-- 9. TRANSAKSI TOP UP: tambah saldo dompet dan catat riwayatnya sekaligus biar konsisten (atomik)
BEGIN;
UPDATE wallets
SET balance = balance + 200000.00,
    updated_at = CURRENT_TIMESTAMP
WHERE user_id = 1;

INSERT INTO transactions (sender_id, receiver_id, amount, type, created_at)
VALUES (1, 1, 200000.00, 'topup', CURRENT_TIMESTAMP);
COMMIT;

-- 9. TRANSAKSI TRANSFER: potong saldo pengirim, tambah saldo penerima, dan catat transaksi sekaligus (atomik)
BEGIN;
UPDATE wallets
SET balance = balance - 50000.00,
    updated_at = CURRENT_TIMESTAMP
WHERE user_id = 1
  AND balance >= 50000.00;

UPDATE wallets
SET balance = balance + 50000.00,
    updated_at = CURRENT_TIMESTAMP
WHERE user_id = 2;

INSERT INTO transactions (sender_id, receiver_id, amount, type, created_at)
VALUES (1, 2, 50000.00, 'transfer', CURRENT_TIMESTAMP);
COMMIT;

-- 10. AMBIL PROFIL USER: liat detail lengkap user (foto, nama lengkap, no hp, email)
SELECT id, username, name, phone, email, photo, created_at
FROM users
WHERE id = 1;

-- 11. GANTI PIN: update pin baru yang langsung di-hash
UPDATE users
SET pin = crypt('654321', gen_salt('bf')),
    updated_at = CURRENT_TIMESTAMP
WHERE id = 1;

-- 12. GANTI PASSWORD: update password baru yang langsung di-hash
UPDATE users
SET password = crypt('new_password_budi_999', gen_salt('bf')),
    updated_at = CURRENT_TIMESTAMP
WHERE id = 1;

-- 13. EDIT PROFIL USER: ubah data diri user kayak nama, email, no hp, atau foto
UPDATE users
SET name = 'Budi Santoso Updated',
    email = 'budi.new@email.com',
    phone = '08777777770',
    photo = 'https://example.com/budi_updated.jpg',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 1;

-- 14. EKSPLORASI FUNGSI AGREGASI: hitung statistik transfer keluar (jumlah transaksi, total, rata-rata, min, max)
SELECT 
    u.id,
    u.name,
    COUNT(t.id) AS total_sent_transactions,
    COALESCE(SUM(t.amount), 0.00) AS total_amount_sent,
    COALESCE(ROUND(AVG(t.amount), 2), 0.00) AS average_amount_sent,
    COALESCE(MIN(t.amount), 0.00) AS min_amount_sent,
    COALESCE(MAX(t.amount), 0.00) AS max_amount_sent
FROM users u
LEFT JOIN transactions t ON t.sender_id = u.id AND t.receiver_id != u.id
GROUP BY u.id, u.name;

-- 15. EKSPLORASI KLAUSA HAVING: filter user yang pernah transfer minimal 1 kali dan total transfernya di atas 50 ribu
SELECT 
    u.id,
    u.name,
    COUNT(t.id) AS sent_transfers_count,
    SUM(t.amount) AS total_sent_volume
FROM users u
JOIN transactions t ON t.sender_id = u.id AND t.receiver_id != u.id
GROUP BY u.id, u.name
HAVING COUNT(t.id) >= 1 AND SUM(t.amount) >= 50000.00;

-- 16. EKSPLORASI STRING_AGG: gabungin jenis transaksi sama daftar nama orang yang pernah ditransfer jadi satu teks
SELECT 
    u.id,
    u.name,
    COUNT(t.id) AS total_transfers_sent,
    STRING_AGG(DISTINCT t.type, ', ') AS distinct_transaction_types,
    STRING_AGG(DISTINCT r.name, ', ' ORDER BY r.name ASC) AS transfer_recipients_list
FROM users u
JOIN transactions t ON t.sender_id = u.id
JOIN users r ON t.receiver_id = r.id
WHERE t.receiver_id != u.id
GROUP BY u.id, u.name
HAVING COUNT(t.id) > 0;
