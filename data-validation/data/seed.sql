-- seed.sql — Sample banking dataset for the data-validation checks.
--
-- Creates a small SQLite schema (customers, accounts, transactions) plus a
-- control_totals table that simulates the row counts reported by a source
-- system, then inserts data with a few INTENTIONAL defects so the checks in
-- ../sql/ demonstrably catch things:
--
--   1. customers row 3  — email is NULL                    (caught by 02)
--   2. customers rows 2 and 6 — same email address        (caught by 03)
--   3. accounts row 105 — customer_id 999 does not exist  (caught by 04)
--   4. transactions row 1007 — account_id 999 missing     (caught by 04)
--   5. transactions row 1005 — negative amount (-10000)    (caught by 05)
--   6. transactions row 1008 — $1,500,000, over the $1M cap (caught by 05)
--   7. customers row 5  — malformed email 'not-an-email'   (caught by 05)
--   8. accounts row 106 — account_type 'CRYPTO' not allowed (caught by 05)
--   9. control_totals expects 9 transactions, 10 are loaded (caught by 01)
--  10. transactions row 1010 — exact duplicate posting of row 1001 (caught by 03)
--
-- Amounts are stored in cents as integers (e.g. 150000 = $1,500.00) to avoid
-- floating-point rounding — the same convention used in real payment systems.
-- Re-runnable: every CREATE drops the table first.

DROP TABLE IF EXISTS control_totals;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    first_name    TEXT NOT NULL,
    last_name     TEXT NOT NULL,
    email         TEXT,               -- intentionally nullable: the null check proves it
    date_of_birth TEXT NOT NULL,      -- ISO format YYYY-MM-DD
    created_at    TEXT NOT NULL
);

CREATE TABLE accounts (
    account_id   INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL,
    account_type TEXT NOT NULL,       -- allowed: CHECKING, SAVINGS, MONEY_MARKET, CD
    balance_cents INTEGER NOT NULL,
    opened_date  TEXT NOT NULL,
    status       TEXT NOT NULL        -- ACTIVE, CLOSED, FROZEN
);

CREATE TABLE transactions (
    transaction_id   INTEGER PRIMARY KEY,
    account_id       INTEGER NOT NULL,
    transaction_type TEXT NOT NULL,   -- DEPOSIT, WITHDRAWAL, PAYMENT, TRANSFER
    amount_cents     INTEGER NOT NULL, -- always stored as a positive value
    transaction_date TEXT NOT NULL,
    description      TEXT
);

-- Simulated source-system row counts, as an ETL control table would hold them.
CREATE TABLE control_totals (
    table_name     TEXT PRIMARY KEY,
    expected_rows  INTEGER NOT NULL,
    source_system  TEXT NOT NULL
);

INSERT INTO control_totals (table_name, expected_rows, source_system) VALUES
    ('customers',    6, 'CRM'),
    ('accounts',     6, 'CORE'),
    ('transactions', 9, 'CORE');  -- INTENTIONAL mismatch: 10 rows are loaded below

INSERT INTO customers (customer_id, first_name, last_name, email, date_of_birth, created_at) VALUES
    (1, 'Alice', 'Johnson', 'alice.johnson@example.com', '1985-03-14', '2023-01-10'),
    (2, 'Bob',   'Smith',   'bob.smith@example.com',     '1990-07-22', '2023-02-15'),
    (3, 'Carol', 'Davis',   NULL,                        '1978-11-05', '2023-03-01'),  -- DEFECT 1: NULL email
    (4, 'David', 'Wilson',  'david.wilson@example.com',  '1982-05-30', '2023-04-12'),
    (5, 'Eve',   'Martinez','not-an-email',              '1995-09-18', '2023-05-20'),  -- DEFECT 7: malformed email
    (6, 'Frank', 'Smith',   'bob.smith@example.com',     '1988-01-25', '2023-06-08');  -- DEFECT 2: duplicate email

INSERT INTO accounts (account_id, customer_id, account_type, balance_cents, opened_date, status) VALUES
    (101, 1,   'CHECKING',     150000,  '2023-01-10', 'ACTIVE'),
    (102, 1,   'SAVINGS',      2500000, '2023-01-15', 'ACTIVE'),
    (103, 2,   'CHECKING',     75000,   '2023-02-15', 'ACTIVE'),
    (104, 3,   'SAVINGS',      500000,  '2023-03-01', 'ACTIVE'),
    (105, 999, 'CHECKING',     10000,   '2023-04-01', 'ACTIVE'),  -- DEFECT 3: orphan, customer 999 missing
    (106, 4,   'CRYPTO',       300000,  '2023-04-12', 'ACTIVE');  -- DEFECT 8: invalid account_type

INSERT INTO transactions (transaction_id, account_id, transaction_type, amount_cents, transaction_date, description) VALUES
    (1001, 101, 'DEPOSIT',    50000,     '2024-01-05', 'Payroll deposit'),
    (1002, 101, 'WITHDRAWAL', 2500,      '2024-01-06', 'ATM withdrawal'),
    (1003, 102, 'DEPOSIT',    100000,    '2024-01-07', 'Transfer in'),
    (1004, 103, 'PAYMENT',    12000,     '2024-01-08', 'Bill payment'),
    (1005, 104, 'DEPOSIT',    -10000,    '2024-01-09', 'Refund'),              -- DEFECT 5: negative amount
    (1006, 105, 'DEPOSIT',    5000,      '2024-01-10', 'Deposit to orphan account'),
    (1007, 999, 'DEPOSIT',    9999,      '2024-01-11', 'Unknown account deposit'), -- DEFECT 4: orphan transaction
    (1008, 101, 'DEPOSIT',    150000000, '2024-01-12', 'Large deposit'),        -- DEFECT 6: $1.5M, over the $1M cap
    (1009, 101, 'TRANSFER',   7500,      '2024-01-13', 'Transfer to savings'),
    (1010, 101, 'DEPOSIT',    50000,     '2024-01-05', 'Payroll deposit');      -- DEFECT 10: duplicate posting of 1001
