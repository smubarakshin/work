-- 03_duplicate_key_checks.sql
--
-- What it validates:
--   Business keys that must be unique are actually unique. A duplicated
--   customer email usually means the same person was onboarded twice
--   (split history, double marketing, wrong identity matching). A duplicated
--   transaction posting — same account, type, amount and date — usually
--   means a file was loaded twice or a retry posted the same event again.
--
-- How it works:
--   GROUP BY the business key and keep only groups with more than one row.
--   Each returned row shows the duplicated key, how many times it occurs
--   and the ids of the rows involved.
--
-- What a failure means:
--   Each returned row is a set of records that must be deduplicated (merge
--   the customers, reverse the extra posting) before balances or reports
--   can be trusted. Returns nothing when every business key is unique.
--
-- Expected result on the seeded sample DB: 2 rows — the email
-- 'bob.smith@example.com' shared by customers 2 and 6, and the transaction
-- posting (account 101, DEPOSIT, 50000, 2024-01-05) present twice.

SELECT
    'duplicate customer email' AS check_name,
    email AS duplicate_key,
    COUNT(*) AS occurrences,
    GROUP_CONCAT(customer_id) AS row_ids
FROM customers
GROUP BY email
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'duplicate transaction posting' AS check_name,
    account_id || ' | ' || transaction_type || ' | ' || amount_cents || ' | ' || transaction_date AS duplicate_key,
    COUNT(*) AS occurrences,
    GROUP_CONCAT(transaction_id) AS row_ids
FROM transactions
GROUP BY account_id, transaction_type, amount_cents, transaction_date
HAVING COUNT(*) > 1

ORDER BY check_name;
