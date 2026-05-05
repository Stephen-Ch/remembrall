# Remembrall — Standing Decisions

_Last updated: May 2026_  
_Source of truth: `_Projects/remembrall/DECISIONS.md` (planning folder)_

This file contains the decisions that are active and must be respected during implementation. It is updated after each milestone.

---

## Stack

- **Frontend + API:** Next.js current stable (App Router)
- **Database:** PostgreSQL via Supabase (hosted, RLS enabled)
- **ORM:** Prisma — non-owner role only, all user-scoped queries via `dbForUser` wrapper
- **Auth:** Auth.js (NextAuth) — confirmed in E0 before E1 starts
- **AI:** Anthropic API — current suitable production models, versions confirmed at build time
- **Deployment:** Vercel — automatic preview URLs per feature branch (required)
- Never hardcode version numbers. Use current stable.

## Branch Rules

- **Feature branch:** normal implementation work, intends to merge, goes through proof gates
- **x-branch (`x/<name>`):** experimental/research spike, NEVER merges, must produce a findings doc in `docs/status/`, then branch is deleted
- These are different things. Mixing them breaks the safety model.

## Proof Gates (every feature branch before merge)

1. Test written before implementation (TDD)
2. Database migration reviewed and tested
3. All 6 RLS test matrix scenarios pass (see `docs/testing/test-catalog.md`)
4. Auth boundary test exists and passes
5. Preview URL verified on Vercel
6. No secrets exposed in code or environment
7. No public route added without explicit allowlist entry
8. Acceptance checklist (defined per epic) fully passed
9. Copilot signoff includes: exact CI command, test count, pass/fail, preview URL

CI is the source of truth. Copilot signoff without CI evidence is not signoff.

## RLS Implementation

- Prisma connects as non-owner Postgres role subject to RLS (never table owner / service role for app queries)
- `FORCE ROW LEVEL SECURITY` on all tenant-owned tables
- Per-request context: `SET LOCAL app.current_user_id` inside a transaction via `dbForUser(userId, fn)`
- RLS policy: `USING (owner_id = current_setting('app.current_user_id')::uuid)`
- Service-role bypass restricted to named admin/migration tasks only

## DB Wrapper Rule

Application code may NOT import PrismaClient directly. All user-scoped DB access goes through `dbForUser(userId, fn)`. CI lint gate fails the build if raw PrismaClient is imported outside `lib/db.ts`.

## Data Model Rules

- ShareLink table (not inline fields) for private UUID tokens
- `isPublic`, `publishedAt`, `revokedAt` remain on Remembrall table for public slug control
- Nesting: same-owner + share-visible only, max depth enforced (default 3), cycle prevention required

## URL and Routing Rules

- Public: `/{username}/{slug}` — indexable after explicit publish
- Private share: `/share/{uuid}` — always noindex, nofollow
- Reserved usernames (blocked at registration): `share`, `api`, `login`, `register`, `admin`, `settings`, `new`, `docs`, `help`, `privacy`, `terms`, `about`, `support`
- Usernames are immutable in MVP
- Public URL uniqueness enforced by compound key `(username, slug)`

## AI Logging Rule

Production logs contain: prompt version, model alias, schema version, timestamp, success/failure, saved Remembrall ID. Raw user input is NEVER logged. 20-case quality review uses synthetic test cases only.

## MVP Scope

**IN:** create → edit → share → AI draft. Single user, no orgs. ShareLink table. Nesting with depth/cycle limits.  
**OUT:** teams, branding, subdomains, channels, document conversion, HIPAA, institutional accounts, polished onboarding, audit trail, offline mode.

## External Review Cadence

Required before: E0 completion, E1 start, launch. Normal feature branches use internal proof gates only — unless the change touches security, auth, data model, or public sharing.

## Process Rules

- No proposals without a research summary first (confirmed by Product Owner)
- No E0 decisions deferred — all architecture/security decisions before implementation
- Postmortem after every sprint
- This document is updated after each milestone
