"""Shared fixtures for the data-validation tests.

Makes the project root importable (so tests can `import validator` and
`import build_db`) and provides two ready-made databases per test run:
a seeded one with known defects and a clean one with none.
"""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import build_db  # noqa: E402  (import after sys.path fix)


@pytest.fixture(scope="session")
def seeded_db(tmp_path_factory):
    """Database built from data/seed.sql — contains the known defects."""
    db_path = tmp_path_factory.mktemp("db") / "seeded.db"
    build_db.build_db(
        Path(__file__).resolve().parent.parent / "data" / "seed.sql", db_path
    )
    return db_path


@pytest.fixture(scope="session")
def clean_db(tmp_path_factory):
    """Database built from data/seed_clean.sql — no defects at all."""
    db_path = tmp_path_factory.mktemp("db") / "clean.db"
    build_db.build_db(
        Path(__file__).resolve().parent.parent / "data" / "seed_clean.sql", db_path
    )
    return db_path
