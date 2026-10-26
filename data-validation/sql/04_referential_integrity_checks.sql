-- 04_referential_integrity_checks.sql
--
-- What it validates:
--   Every child row points at a parent row that actually exists — accounts
--   belong to real customers, transactions belong to real accounts. In a
--   migration this is the classic failure mode: the child table loads before
--   (or without) the parent, or parent rows are filtered out by a bad join.
--
-- How it works:
--   Anti-joins (NOT EXISTS) against the parent tables. Foreign keys are
--   deliberately NOT enforced in the seed schema — exactly like a staging
--   area or a warehouse load where the database does not protect you and
--   the check has to catch the problem instead.
--
-- What a failure means:
--   Each returned row is an orphan that would break joins, understate
--   balances and fail downstream reports. It must be re-loaded with its
--   parent or removed. Returns nothing when every reference resolves.
--
-- Expected result on the seeded sample DB: 2 rows — account 105 pointing
-- at missing customer 999, and transaction 1007 pointing at missing
-- account 999.

SELECT
    'account with missing customer' AS check_name,
    'accounts' AS table_name,
    a.account_id AS row_id,
    a.customer_id AS missing_parent_id
FROM accounts AS a
WHERE NOT EXISTS (
    SELECT 1 FROM customers AS c WHERE c.customer_id = a.customer_id
)

UNION ALL

SELECT
    'transaction with missing account' AS check_name,
    'transactions' AS table_name,
    t.transaction_id AS row_id,
    t.account_id AS missing_parent_id
FROM transactions AS t
WHERE NOT EXISTS (
    SELECT 1 FROM accounts AS a WHERE a.account_id = t.account_id
)

ORDER BY table_name, row_id;
