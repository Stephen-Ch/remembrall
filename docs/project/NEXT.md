# NEXT — Current Work

_Updated: 2026-05-06_

## Active Epic: E1 — Core Private Remembrall Engine

E1 is code-complete on branch `e1-core-engine`. Awaiting DB credentials and final verification.

---

## E1 Code Status

All implementation written and committed. TypeScript clean. ESLint clean.

| Area | Status |
|---|---|
| Prisma schema (User, Remembrall, Requirement, ShareLink) | DONE |
| dbForUser wrapper + ESLint gate | DONE |
| Auth.js v5 magic link + database sessions | DONE |
| RLS SQL policies (supabase/setup/) | DONE |
| CRUD server actions (create/read/update/delete) | DONE |
| Nesting + cycle detection (MAX_NEST_DEPTH = 5) | DONE |
| Offline mode (Service Worker + IndexedDB + sync) | DONE |
| Dashboard + edit + run UI (functional, unstyled) | DONE |
| 6-scenario RLS test matrix | DONE (needs TEST_DATABASE_URL to run) |
| Nesting unit tests | DONE |
| Playwright e2e harness (3 spec files, 7 tests) | DONE |

---

## Remaining Before E1 Closes

These require Stephen's action:

1. **Add Supabase credentials to .env.local** (DATABASE_URL + DIRECT_URL + AUTH_SECRET + AUTH_RESEND_KEY)
2. **Run Supabase SQL setup** — paste `supabase/setup/01-create-app-role.sql` into Supabase SQL editor
3. **Run migration** — `npx prisma migrate dev --name e1-initial-schema` (creates tables)
4. **Run RLS policies** — paste `supabase/setup/02-rls-policies.sql` into Supabase SQL editor
5. **Run RLS test matrix** — `TEST_DATABASE_URL=<url> npx vitest tests/rls-matrix.test.ts`
6. **Run Playwright smoke tests** — `PLAYWRIGHT_TEST_MODE=true npx playwright test e2e/smoke.spec.ts`
7. **Smoke test: sign in and create a Remembrall manually**

When all 7 pass, E1 is complete and E2 is unblocked.

---

## Completed Epics

### ✅ E0 — Architecture and Security Decisions
**Merged:** 2026-05-06

**Key decisions locked:**
- Auth.js v5 + Prisma adapter + database sessions + magic link only
- dbForUser wrapper + FORCE RLS + non-owner Postgres role
- ShareLink table for private tokens
- Offline mode is E1 scope (Service Worker + IndexedDB)
- Recipient state migration is E2 scope

---

## Blocked
- E2, E3, E4 — blocked on E1 verification steps above
