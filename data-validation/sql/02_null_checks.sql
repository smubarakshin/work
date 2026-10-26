-- 02_null_checks.sql
--
-- What it validates:
--   Required (business-mandatory) fields are actually populated. A NULL in
--   one of these columns means the record cannot be processed downstream:
--   no email means the customer cannot be contacted or matched, no amount
--   means a transaction cannot be posted, no account type means the account
--   cannot be serviced.
--
-- How it works:
--   One SELECT per mandatory column, combined with UNION ALL. Each returned
--   row names the check, the table, the row id and the empty column.
--
-- What a failure means:
--   Each returned row is a record that must be fixed at the source or
--   quarantined before the load is accepted. Returns nothing when every
--   mandatory field is populated.
--
-- Expected result on the seeded sample DB: 1 row (customers, row 3, email).

SELECT 'customers.email is NULL' AS check_name, 'customers' AS table_name, customer_id AS row_id, 'email' AS column_name FROM customers WHERE email IS NULL
UNION ALL
SELECT 'customers.first_name is NULL', 'customers', customer_id, 'first_name' FROM customers WHERE first_name IS NULL
UNION ALL
SELECT 'customers.last_name is NULL', 'customers', customer_id, 'last_name' FROM customers WHERE last_name IS NULL
UNION ALL
SELECT 'customers.date_of_birth is NULL', 'customers', customer_id, 'date_of_birth' FROM customers WHERE date_of_birth IS NULL
UNION ALL
SELECT 'accounts.customer_id is NULL', 'accounts', account_id, 'customer_id' FROM accounts WHERE customer_id IS NULL
UNION ALL
SELECT 'accounts.account_type is NULL', 'accounts', account_id, 'account_type' FROM accounts WHERE account_type IS NULL
UNION ALL
SELECT 'accounts.balance_cents is NULL', 'accounts', account_id, 'balance_cents' FROM accounts WHERE balance_cents IS NULL
UNION ALL
SELECT 'transactions.account_id is NULL', 'transactions', transaction_id, 'account_id' FROM transactions WHERE account_id IS NULL
UNION ALL
SELECT 'transactions.transaction_type is NULL', 'transactions', transaction_id, 'transaction_type' FROM transactions WHERE transaction_type IS NULL
UNION ALL
SELECT 'transactions.amount_cents is NULL', 'transactions', transaction_id, 'amount_cents' FROM transactions WHERE amount_cents IS NULL
UNION ALL
SELECT 'transactions.transaction_date is NULL', 'transactions', transaction_id, 'transaction_date' FROM transactions WHERE transaction_date IS NULL
ORDER BY table_name, row_id;
