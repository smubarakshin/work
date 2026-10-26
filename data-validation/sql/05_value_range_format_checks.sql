-- 05_value_range_format_checks.sql
--
-- What it validates:
--   Values sit inside their allowed ranges and formats. Amounts must be
--   positive (they are stored as absolute values; the type column says
--   which direction the money moved) and under the $1,000,000 single-
--   transaction limit; emails must look like an email; account_type must
--   be one of the product codes the core system knows; balances must not
--   go negative.
--
-- How it works:
--   One SELECT per rule, combined with UNION ALL. Each returned row names
--   the rule, the table, the row id and the offending value.
--
-- What a failure means:
--   Each returned row is a value that is either corrupt at the source (a
--   negative amount, a mistyped email) or outside business policy (an
--   over-limit transaction, an unknown product code). It needs a source
--   fix or a documented exception — it must not silently flow into
--   balances and reports.
--
-- Expected result on the seeded sample DB: 4 rows — transaction 1005
-- (negative amount), transaction 1008 ($1.5M, over the limit), customer 5
-- (malformed email), account 106 (account_type 'CRYPTO').

SELECT 'negative transaction amount' AS check_name, 'transactions' AS table_name, transaction_id AS row_id, amount_cents AS offending_value FROM transactions WHERE amount_cents < 0
UNION ALL
SELECT 'transaction amount over $1,000,000 limit', 'transactions', transaction_id, amount_cents FROM transactions WHERE amount_cents > 100000000
UNION ALL
SELECT 'malformed customer email', 'customers', customer_id, email FROM customers WHERE email IS NOT NULL AND email NOT LIKE '%@%.%'
UNION ALL
SELECT 'invalid account_type', 'accounts', account_id, account_type FROM accounts WHERE account_type NOT IN ('CHECKING', 'SAVINGS', 'MONEY_MARKET', 'CD')
UNION ALL
SELECT 'negative account balance', 'accounts', account_id, balance_cents FROM accounts WHERE balance_cents < 0
ORDER BY table_name, row_id;
