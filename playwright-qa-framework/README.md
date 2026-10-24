# Playwright QA Framework

End-to-end and API test automation framework in **Playwright + TypeScript**, built with the
**Page Object Model**. It covers a complete e-commerce purchase flow on the public demo shop
[SauceDemo](https://www.saucedemo.com) and a REST API suite against
[JSONPlaceholder](https://jsonplaceholder.typicode.com), with CI running on every push and pull request.

## Tech stack

| Area | Tool |
| --- | --- |
| Language | TypeScript (strict mode) |
| E2E framework | Playwright Test |
| API testing | Playwright `APIRequestContext` |
| Design pattern | Page Object Model |
| Reporting | Playwright HTML reporter, screenshots / video / trace on failure |
| CI | GitHub Actions |

## Architecture

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

## Run locally

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

## Test coverage

### E2E — SauceDemo (`tests/e2e/checkout-flow.spec.ts`)

| Test | What it verifies |
| --- | --- |
| Full purchase flow | Login → add two products → cart contents → checkout form → order confirmation |
| Locked-out user | `locked_out_user` is rejected with a clear error message |
| Cart removal | Removing an item clears the cart badge |

### API — JSONPlaceholder (`tests/api/jsonplaceholder.spec.ts`)

| Test | What it verifies |
| --- | --- |
| `GET /posts` | 200, non-empty array, posts carry `userId`, `id`, `title`, `body` |
| `GET /posts/1` | 200, correct `id` / `userId`, non-empty title |
| `GET /posts?userId=1` | Filtering works — every returned post belongs to user 1 |
| `POST /posts` | 201, response echoes the payload and assigns an `id` |

## CI

`.github/workflows/ci.yml` runs on every push and pull request to `main`: install dependencies,
install Chromium, run the full suite (with retries), and upload the HTML report as an artifact
(plus raw test results on failure).

---

Shamil Mubarakshin — Senior QA Automation Engineer
