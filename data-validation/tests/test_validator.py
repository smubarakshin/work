"""Tests for the SQL data-validation checks and the Python validator.

Two directions, mirroring how these checks are used in real ETL work:
  1. The seeded database (data/seed.sql) contains KNOWN defects — every
     check must catch exactly the defects it was written for, no more and
     no fewer. If a check stops catching a defect, the test fails.
  2. The clean database (data/seed_clean.sql) contains NO defects — every
     check must return zero findings. If a check starts flagging good data,
     the test fails.

Expected findings on the seeded database:
  01 reconciliation: 1 (transactions: 9 expected, 10 loaded)
  02 nulls:         1 (customer 3, email NULL)
  03 duplicates:    2 (email bob.smith@example.com; duplicate posting)
  04 orphans:       2 (account 105, transaction 1007)
  05 range/format:  4 (negative amount, $1.5M amount, bad email, bad type)
"""

import validator


def findings(results, stem):
    """Findings list for one check, by script stem."""
    return results[stem]["findings"]


class TestSeededDatabase:
    """Every seeded defect is caught, with the right details."""

    def test_reconciliation_catches_row_count_mismatch(self, seeded_db):
        results = validator.run_all(seeded_db)
        rows = findings(results, "01_row_count_reconciliation")
        assert len(rows) == 1
        row = rows[0]
        assert row["table_name"] == "transactions"
        assert row["expected_rows"] == 9
        assert row["actual_rows"] == 10
        assert row["row_diff"] == 1

    def test_null_check_catches_missing_email(self, seeded_db):
        results = validator.run_all(seeded_db)
        rows = findings(results, "02_null_checks")
        assert len(rows) == 1
        assert rows[0]["table_name"] == "customers"
        assert rows[0]["row_id"] == 3
        assert rows[0]["column_name"] == "email"

    def test_duplicate_check_catches_email_and_posting(self, seeded_db):
        results = validator.run_all(seeded_db)
        rows = findings(results, "03_duplicate_key_checks")
        assert len(rows) == 2
        by_name = {row["check_name"]: row for row in rows}
        email_dup = by_name["duplicate customer email"]
        assert email_dup["duplicate_key"] == "bob.smith@example.com"
        assert email_dup["occurrences"] == 2
        posting_dup = by_name["duplicate transaction posting"]
        assert posting_dup["occurrences"] == 2
        assert "101 | DEPOSIT | 50000 | 2024-01-05" in posting_dup["duplicate_key"]

    def test_orphan_check_catches_missing_parents(self, seeded_db):
        results = validator.run_all(seeded_db)
        rows = findings(results, "04_referential_integrity_checks")
        assert len(rows) == 2
        by_name = {row["check_name"]: row for row in rows}
        assert by_name["account with missing customer"]["row_id"] == 105
        assert by_name["account with missing customer"]["missing_parent_id"] == 999
        assert by_name["transaction with missing account"]["row_id"] == 1007
        assert by_name["transaction with missing account"]["missing_parent_id"] == 999

    def test_range_format_check_catches_all_four(self, seeded_db):
        results = validator.run_all(seeded_db)
        rows = findings(results, "05_value_range_format_checks")
        assert len(rows) == 4
        by_name = {row["check_name"]: row for row in rows}
        assert by_name["negative transaction amount"]["row_id"] == 1005
        assert by_name["transaction amount over $1,000,000 limit"]["row_id"] == 1008
        assert by_name["malformed customer email"]["row_id"] == 5
        assert by_name["invalid account_type"]["row_id"] == 106

    def test_validator_reports_failure_on_seeded_db(self, seeded_db):
        assert validator.main(["--db", str(seeded_db)]) == 1


class TestCleanDatabase:
    """No false positives: clean data passes every check."""

    def test_all_checks_pass_on_clean_data(self, clean_db):
        results = validator.run_all(clean_db)
        for stem in results:
            assert findings(results, stem) == [], f"{stem} flagged clean data"

    def test_validator_reports_success_on_clean_db(self, clean_db):
        assert validator.main(["--db", str(clean_db)]) == 0
