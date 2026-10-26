-- seed_clean.sql — Same schema as seed.sql, but with NO defects.
--
-- Used by the test suite (tests/test_validator.py) to prove the checks return
-- zero findings on clean data. Control totals match the actual row counts, so
-- the reconciliation check passes too.

DROP TABLE IF EXISTS control_totals;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    first_name    TEXT NOT NULL,
    last_name     TEXT NOT NULL,
    email         TEXT,
    date_of_birth TEXT NOT NULL,
    created_at    TEXT NOT NULL
);

CREATE TABLE accounts (
    account_id   INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL,
    account_type TEXT NOT NULL,
    balance_cents INTEGER NOT NULL,
    opened_date  TEXT NOT NULL,
    status       TEXT NOT NULL
);

CREATE TABLE transactions (
    transaction_id   INTEGER PRIMARY KEY,
    account_id       INTEGER NOT NULL,
    transaction_type TEXT NOT NULL,
    amount_cents     INTEGER NOT NULL,
    transaction_date TEXT NOT NULL,
    description      TEXT
);

CREATE TABLE control_totals (
    table_name     TEXT PRIMARY KEY,
    expected_rows  INTEGER NOT NULL,
    source_system  TEXT NOT NULL
);

INSERT INTO control_totals (table_name, expected_rows, source_system) VALUES
    ('customers',    4, 'CRM'),
    ('accounts',     4, 'CORE'),
    ('transactions', 4, 'CORE');

INSERT INTO customers (customer_id, first_name, last_name, email, date_of_birth, created_at) VALUES
    (1, 'Alice', 'Johnson', 'alice.johnson@example.com', '1985-03-14', '2023-01-10'),
    (2, 'Bob',   'Smith',   'bob.smith@example.com',     '1990-07-22', '2023-02-15'),
    (3, 'Carol', 'Davis',   'carol.davis@example.com',   '1978-11-05', '2023-03-01'),
    (4, 'David', 'Wilson',  'david.wilson@example.com',  '1982-05-30', '2023-04-12');

INSERT INTO accounts (account_id, customer_id, account_type, balance_cents, opened_date, status) VALUES
    (101, 1, 'CHECKING', 150000,  '2023-01-10', 'ACTIVE'),
    (102, 1, 'SAVINGS',  2500000, '2023-01-15', 'ACTIVE'),
    (103, 2, 'CHECKING', 75000,   '2023-02-15', 'ACTIVE'),
    (104, 3, 'SAVINGS',  500000,  '2023-03-01', 'ACTIVE');

INSERT INTO transactions (transaction_id, account_id, transaction_type, amount_cents, transaction_date, description) VALUES
    (1001, 101, 'DEPOSIT',    50000,  '2024-01-05', 'Payroll deposit'),
    (1002, 101, 'WITHDRAWAL', 2500,   '2024-01-06', 'ATM withdrawal'),
    (1003, 102, 'DEPOSIT',    100000, '2024-01-07', 'Transfer in'),
    (1004, 103, 'PAYMENT',    12000,  '2024-01-08', 'Bill payment');
