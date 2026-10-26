# SQL + Python Data Validation

A small, runnable data-quality toolkit: SQL validation checks, a sample
banking dataset with intentional defects, and a Python validator with a
pytest suite that proves the checks catch what they should — and stay
quiet on clean data.

No server, no third-party packages for the checks themselves: everything
runs on SQLite and the Python standard library. The only extra install is
`pytest`, for the test suite.

## Why this exists

In ETL validation and data-migration testing, the same five questions come
up on every load:

1. Did all the rows arrive? (reconciliation)
2. Is anything mandatory missing? (nulls)
3. Was anything loaded twice? (duplicates)
4. Does every child row have a parent? (orphans)
5. Are the values sane? (ranges and formats)

This project answers all five with plain SQL that returns the failing
rows — so a check that finds nothing *is* the pass, and a check that
finds rows tells you exactly what to fix.

## Layout

```
data-validation/
├── README.md
├── build_db.py          # builds sample.db from a seed script
├── validator.py         # runs all SQL checks, prints a pass/fail report
├── .gitignore           # keeps generated *.db files out of git
├── sql/                 # the five checks (SQLite-compatible)
│   ├── 01_row_count_reconciliation.sql
│   ├── 02_null_checks.sql
│   ├── 03_duplicate_key_checks.sql
│   ├── 04_referential_integrity_checks.sql
│   └── 05_value_range_format_checks.sql
├── data/
│   ├── seed.sql         # schema + data WITH intentional defects
│   └── seed_clean.sql   # same schema, clean data (used by the tests)
└── tests/
    ├── conftest.py
    └── test_validator.py
```

## The sample data

`data/seed.sql` builds a small banking schema — `customers`, `accounts`,
`transactions`, plus a `control_totals` table simulating source-system row
counts — the kind of data validated during a core-banking migration.
Amounts are stored in cents as integers (e.g. `150000` = $1,500.00).

It contains 10 intentional defects, so every check has something to catch:

| # | Defect | Caught by |
|---|--------|-----------|
| 1 | Customer 3 has a NULL email | `02_null_checks` |
| 2 | Customers 2 and 6 share one email | `03_duplicate_key_checks` |
| 3 | Account 105 points at missing customer 999 | `04_referential_integrity_checks` |
| 4 | Transaction 1007 points at missing account 999 | `04_referential_integrity_checks` |
| 5 | Transaction 1005 has a negative amount | `05_value_range_format_checks` |
| 6 | Transaction 1008 is $1,500,000 — over the $1M cap | `05_value_range_format_checks` |
| 7 | Customer 5 has a malformed email (`not-an-email`) | `05_value_range_format_checks` |
| 8 | Account 106 has an invalid type (`CRYPTO`) | `05_value_range_format_checks` |
| 9 | Control totals expect 9 transactions, 10 loaded | `01_row_count_reconciliation` |
| 10 | Transaction 1010 is an exact duplicate posting of 1001 | `03_duplicate_key_checks` |

## The checks

| Script | What it validates | Seeded DB result |
|--------|-------------------|------------------|
| `01_row_count_reconciliation.sql` | Per-table row counts vs. source-system control totals | 1 finding |
| `02_null_checks.sql` | Mandatory fields are populated | 1 finding |
| `03_duplicate_key_checks.sql` | Business keys are unique (emails, transaction postings) | 2 findings |
| `04_referential_integrity_checks.sql` | Every child row has an existing parent (no orphans) | 2 findings |
| `05_value_range_format_checks.sql` | Amounts in range, emails well-formed, types from the allowed list | 4 findings |

Each script has a header comment explaining what it validates and what a
failure means. Every script returns the failing rows (or counts) — and
returns nothing when the data is clean.

## How to run

### 1. Build the sample database

```bash
python3 build_db.py            # creates sample.db from data/seed.sql
python3 build_db.py --clean    # creates clean.db from data/seed_clean.sql
```

Or with the `sqlite3` CLI:

```bash
sqlite3 sample.db < data/seed.sql
```

### 2. Run a single SQL check

```bash
sqlite3 sample.db < sql/01_row_count_reconciliation.sql
```

### 3. Run the Python validator (all checks, pass/fail report)

```bash
python3 validator.py            # checks sample.db
python3 validator.py --db clean.db
```

Expected output on the seeded database: all five checks FAIL with a total
of 10 findings. On the clean database: all five PASS, exit code 0.

### 4. Run the tests

```bash
pip install pytest
python3 -m pytest -v
```

The suite does two things: it asserts each check catches exactly the
seeded defects (right rows, right values), and it asserts every check
returns zero findings on the clean dataset — no false positives.

## Real-world mapping

| This project | On the job |
|---|---|
| `control_totals` vs. actual counts | Source-vs-target reconciliation after an ETL load or a $110B data migration |
| Null checks on required fields | Rejecting incomplete records before they reach the warehouse |
| Duplicate-key checks | Catching double-loaded files and duplicate customer onboarding |
| Orphan checks | Finding child rows whose parents never loaded (load-order bugs) |
| Range/format checks | Business-rule validation: limits, codes, formats before posting |

The pattern scales directly: the same five checks, pointed at staging
tables in SQL Server / Snowflake / Postgres, are the core of ETL
validation and migration reconciliation.
