#!/usr/bin/env python3
"""Build a SQLite database from a seed script.

Usage:
    python3 build_db.py                      # builds sample.db from data/seed.sql
    python3 build_db.py --clean              # builds clean.db from data/seed_clean.sql
    python3 build_db.py --seed data/seed.sql --out my.db

Re-runnable: an existing output file is replaced. No third-party
dependencies — standard library only (sqlite3).
"""

import argparse
import sqlite3
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

TABLES = ("customers", "accounts", "transactions", "control_totals")


def build_db(seed_path: Path, db_path: Path) -> Path:
    """Create db_path from seed_path, replacing it if it already exists."""
    if db_path.exists():
        db_path.unlink()
    conn = sqlite3.connect(db_path)
    try:
        conn.executescript(seed_path.read_text(encoding="utf-8"))
        conn.commit()
    finally:
        conn.close()
    return db_path


def count_rows(db_path: Path) -> dict[str, int]:
    """Return the row count of every known table in db_path."""
    conn = sqlite3.connect(db_path)
    try:
        return {
            table: conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            for table in TABLES
        }
    finally:
        conn.close()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", default=str(BASE_DIR / "data" / "seed.sql"),
                        help="Seed SQL file to load (default: data/seed.sql)")
    parser.add_argument("--out", default=str(BASE_DIR / "sample.db"),
                        help="Database file to create (default: sample.db)")
    parser.add_argument("--clean", action="store_true",
                        help="Build from data/seed_clean.sql into clean.db")
    args = parser.parse_args(argv)

    seed_path = Path(BASE_DIR / "data" / "seed_clean.sql") if args.clean else Path(args.seed)
    db_path = Path(BASE_DIR / "clean.db") if args.clean else Path(args.out)
    if not seed_path.exists():
        print(f"Seed file not found: {seed_path}", file=sys.stderr)
        return 2

    build_db(seed_path, db_path)
    print(f"Built {db_path} from {seed_path.name}")
    for table, count in count_rows(db_path).items():
        print(f"  {table}: {count} rows")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
