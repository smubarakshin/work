# QA Portfolio

Two runnable QA projects in one repo: a **Playwright + TypeScript** end-to-end and API
test framework, and a **SQL + Python** data-validation toolkit. Both are grounded in real
banking QA work — UI/API automation and ETL/migration data validation.

## What's in this repo

```text
.                          Playwright framework (root)
├── pages/                 Page objects — Login, Inventory, Cart, Checkout
├── tests/
│   ├── e2e/               SauceDemo purchase flow
│   └── api/               JSONPlaceholder REST checks
├── playwright.config.ts
├── package.json
├── data-validation/       SQL + Python data-validation toolkit
│   ├── sql/               The five checks (reconciliation, nulls, duplicates,
│   │                      orphans, ranges/formats)
│   ├── data/              Sample banking dataset, seeded + clean
│   ├── validator.py       Runs all checks, prints a PASS/FAIL report
│   └── tests/             pytest suite (8 tests)
└── .github/workflows/     CI pipeline
```

## Playwright QA Framework

End-to-end and API test automation in **Playwright + TypeScript**, built with the
**Page Object Model**. It covers a complete e-commerce purchase flow on the public demo shop
[SauceDemo](https://www.saucedemo.com) and a REST API suite against
[JSONPlaceholder](https://jsonplaceholder.typicode.com), with CI running on every push and pull request.

### Tech stack

| Area           | Tool                                                             |
| -------------- | ---------------------------------------------------------------- |
| Language       | TypeScript (strict mode)                                         |
| E2E framework  | Playwright Test                                                  |
| API testing    | Playwright `APIRequestContext`                                   |
| Design pattern | Page Object Model                                                |
| Reporting      | Playwright HTML reporter, screenshots / video / trace on failure |
| CI             | GitHub Actions                                                   |

### Architecture

```text
pages/                  Page objects — one class per page, locators and actions only
  LoginPage.ts          Sign-in, error assertions
  InventoryPage.ts      Product list, add to cart, cart badge, sorting
  CartPage.ts           Cart contents, remove item, proceed to checkout
  CheckoutPage.ts       Customer info, finish order, completion assertion
tests/
  e2e/                  User journeys through the page objects (no raw selectors in tests)
  api/                  REST checks with status and body assertions
.github/workflows/     CI pipeline
```

Tests never touch selectors directly: every interaction goes through a page object, so a UI
change means updating one class instead of every test.

### Run locally

```bash
npm install
npx playwright install --with-deps chromium   # browsers, first run only

npx playwright test            # full suite (Chromium, headless)
npx playwright test tests/e2e  # E2E only
npx playwright test tests/api  # API only
npx playwright test --ui       # interactive UI mode
npx playwright show-report     # open the HTML report
npm run typecheck              # tsc --noEmit
```

Demo credentials for SauceDemo are the public ones: `standard_user` / `secret_sauce`.

### Test coverage

#### E2E — SauceDemo (`tests/e2e/checkout-flow.spec.ts`)

| Test               | What it verifies                                                              |
| ------------------ | ----------------------------------------------------------------------------- |
| Full purchase flow | Login → add two products → cart contents → checkout form → order confirmation |
| Locked-out user    | `locked_out_user` is rejected with a clear error message                      |
| Cart removal       | Removing an item clears the cart badge                                        |

#### API — JSONPlaceholder (`tests/api/jsonplaceholder.spec.ts`)

| Test                  | What it verifies                                                  |
| --------------------- | ----------------------------------------------------------------- |
| `GET /posts`          | 200, non-empty array, posts carry `userId`, `id`, `title`, `body` |
| `GET /posts/1`        | 200, correct `id` / `userId`, non-empty title                     |
| `GET /posts?userId=1` | Filtering works — every returned post belongs to user 1           |
| `POST /posts`         | 201, response echoes the payload and assigns an `id`              |

## SQL + Python Data Validation

A small, runnable data-quality toolkit: five SQL checks, a sample banking dataset with
intentional defects, and a Python validator with a pytest suite that proves the checks
catch what they should — and stay quiet on clean data.

| Check                                 | What it validates                                                 |
| ------------------------------------- | ----------------------------------------------------------------- |
| `01_row_count_reconciliation.sql`     | Per-table row counts vs. source-system control totals             |
| `02_null_checks.sql`                  | Mandatory fields are populated                                    |
| `03_duplicate_key_checks.sql`         | Business keys are unique (emails, transaction postings)           |
| `04_referential_integrity_checks.sql` | Every child row has an existing parent (no orphans)               |
| `05_value_range_format_checks.sql`    | Amounts in range, emails well-formed, types from the allowed list |

The seeded database has 10 intentional defects — a NULL email, a duplicate email, orphan
account/transaction rows, a negative amount, a $1.5M over-limit amount, a malformed email,
an invalid account type, a control-total mismatch, and a duplicate posting — and the checks
catch all 10. The clean database returns zero findings.

```bash
cd data-validation
python3 build_db.py                  # creates sample.db from data/seed.sql
python3 validator.py                 # runs all 5 checks, PASS/FAIL report
python3 validator.py --db clean.db   # all 5 PASS on clean data
python3 -m pytest -v                 # 8 tests: seeded defects caught, no false positives
```

No third-party packages for the checks themselves — everything runs on SQLite and the
Python standard library. Full details: [data-validation/README.md](./data-validation/README.md).

## CI

`.github/workflows/ci.yml` runs on every push and pull request to `main`: install dependencies,
install Chromium, run the full Playwright suite (with retries), and upload the HTML report as an artifact
(plus raw test results on failure).

---

Shamil Mubarakshin — Senior QA Automation Engineer
