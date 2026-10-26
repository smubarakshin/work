#!/usr/bin/env python3
"""Run the SQL data-validation checks and print a pass/fail summary.

Each check is a SQL script in sql/ that returns the rows that FAIL the
check — an empty result means the check passed. The validator runs all five
checks against a SQLite database and prints one line per check, plus the
offending rows for anything that failed.

Usage:
    python3 validator.py               # checks sample.db (build it first)
    python3 validator.py --db clean.db # checks another database file

Exit code: 0 when every check passes, 1 when any check finds a problem,
2 when the database file does not exist. No third-party dependencies —
standard library only (sqlite3).
"""

import argparse
import sqlite3
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
SQL_DIR = BASE_DIR / "sql"

# (script file stem, human-readable description), in run order.
CHECKS: list[tuple[str, str]] = [
    ("01_row_count_reconciliation", "Row-count reconciliation (source vs target)"),
    ("02_null_checks", "NULL checks on required fields"),
    ("03_duplicate_key_checks", "Duplicate business-key checks"),
    ("04_referential_integrity_checks", "Referential-integrity (orphan) checks"),
    ("05_value_range_format_checks", "Value-range and format checks"),
]


def run_check(db_path: Path, sql_path: Path) -> list[dict]:
    """Run one SQL check file; return the failing rows as a list of dicts."""
    sql = sql_path.read_text(encoding="utf-8")
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        return [dict(row) for row in conn.execute(sql).fetchall()]
    finally:
        conn.close()


def run_all(db_path: Path, sql_dir: Path = SQL_DIR) -> dict[str, dict]:
    """Run every check; return {script stem: {description, findings}}."""
    return {
        stem: {
            "description": description,
            "findings": run_check(db_path, sql_dir / f"{stem}.sql"),
        }
        for stem, description in CHECKS
    }


def print_report(results: dict[str, dict]) -> int:
    """Print the pass/fail summary; return 1 if anything failed, else 0."""
    total_findings = 0
    for stem, result in results.items():
        findings = result["findings"]
        status = "FAIL" if findings else "PASS"
        print(f"[{status}] {stem}: {result['description']} — {len(findings)} finding(s)")
        for row in findings:
            detail = " | ".join(f"{key}={value}" for key, value in row.items())
            print(f"         {detail}")
        total_findings += len(findings)
    print(f"\nTotal: {total_findings} finding(s) across {len(results)} check(s).")
    return 1 if total_findings else 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", default=str(BASE_DIR / "sample.db"),
                        help="SQLite database to validate (default: sample.db)")
    args = parser.parse_args(argv)
    db_path = Path(args.db)
    if not db_path.exists():
        print(f"Database not found: {db_path}\nBuild it first: python3 build_db.py",
              file=sys.stderr)
        return 2
    return print_report(run_all(db_path))


if __name__ == "__main__":
    raise SystemExit(main())
