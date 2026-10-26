-- 01_row_count_reconciliation.sql
--
-- What it validates:
--   Row counts after a load, table by table, against the counts the source
--   system reported. In a real ETL / migration job this is the first gate:
--   if the target has fewer rows than the source, rows were lost in transit;
--   if it has more, rows were duplicated or the wrong extract was loaded.
--
-- How it works here:
--   control_totals simulates the source system's reported counts. The query
--   counts the rows actually present in each table and returns only the
--   tables where expected <> actual, with the difference.
--
-- What a failure means:
--   A returned row means that table's load is incomplete or over-loaded and
--   must be investigated before downstream checks (or the business) can
--   trust the data. Returns nothing when every table reconciles.
--
-- Expected result on the seeded sample DB: 1 row (transactions: 9 expected,
-- 10 loaded, diff +1 — the duplicate posting in the seed).

SELECT
    ct.table_name,
    ct.expected_rows,
    actual.actual_rows,
    actual.actual_rows - ct.expected_rows AS row_diff,
    ct.source_system
FROM control_totals AS ct
JOIN (
    SELECT 'customers'    AS table_name, COUNT(*) AS actual_rows FROM customers
    UNION ALL
    SELECT 'accounts',    COUNT(*) FROM accounts
    UNION ALL
    SELECT 'transactions', COUNT(*) FROM transactions
) AS actual
    ON actual.table_name = ct.table_name
WHERE ct.expected_rows <> actual.actual_rows
ORDER BY ct.table_name;
