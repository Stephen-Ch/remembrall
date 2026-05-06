# NEXT — Current Work

_Updated: 2026-05-06_

## Active Epic: E1 — Core Private Remembrall Engine

E0 is complete and merged. All architecture and security decisions are documented. E1 is now unblocked.

---

## Active: E1 First Step — Prisma Schema

Create the Prisma schema from `docs/architecture/ARCHITECTURE.md`:
- User, Remembrall, Requirement, ShareLink models
- Non-owner Postgres role configured
- ENABLE + FORCE ROW LEVEL SECURITY on all user-scoped tables
- dbForUser wrapper in lib/db.ts
- ESLint no-restricted-imports CI lint gate wired

---

## Completed Epics

### ✅ E0 — Architecture and Security Decisions
**Merged:** 2026-05-06

**Completed x-branches:**
- x/e0-schema-study → `docs/status/e0-schema-study-findings.md`
- x/e0-auth-research → `docs/status/e0-auth-findings.md`
- x/e0-rls-pattern → `docs/status/e0-rls-findings.md`

**Docs feature branch merged:** `docs/e0-decisions` → main

**Key decisions locked:**
- Auth.js v5 + Prisma adapter + database sessions + magic link only
- dbForUser wrapper + FORCE RLS + non-owner Postgres role
- ShareLink table for private tokens
- Offline mode is E1 scope (Service Worker + IndexedDB)
- Recipient state migration is E2 scope

---

## Blocked
- E2, E3, E4 — blocked on E1 completion
