# Remembrall — Standing Decisions

_Last updated: 2026-05-06_  
_Source docs: docs/status/e0-schema-study-findings.md, docs/status/e0-auth-findings.md, docs/status/e0-rls-findings.md_

This file records the confirmed architecture, security, and scope decisions that are now binding for implementation.

---

## Confirmed Stack

- **Frontend + API:** Next.js current stable with App Router
- **Database:** PostgreSQL via Supabase
- **ORM:** Prisma
- **Auth:** Auth.js v5 with Prisma adapter
- **Session strategy:** Database sessions
- **Deployment:** Vercel
- **AI:** Anthropic API

Versions remain on current stable releases. Do not hardcode version numbers into standing decisions.

## Auth Decisions

- MVP auth is **magic link only**
- **Email/password is out of MVP** and is not part of E1
- Auth.js uses the **Prisma adapter**
- Auth state for app requests comes from **database-backed sessions**, not JWT-only session state
- `session.user.id` is the stable ownership key and the source user ID for database access
- **Recipient state migration is deferred to E2**

## RLS Decisions

- Prisma application queries must connect as a **non-owner, non-superuser Postgres role**
- User-scoped tables must use **ENABLE ROW LEVEL SECURITY** and **FORCE ROW LEVEL SECURITY**
- All user-scoped DB access must go through a **dbForUser** wrapper
- The wrapper sets per-request user context with **set_config** inside a Prisma **$transaction**
- RLS policies read **app.current_user_id** and deny access when it is unset
- Service-role or owner-level bypass is restricted to named admin or migration paths only

## CI and Safety Gates

- ESLint must block raw **PrismaClient** imports outside **lib/db.ts** using **no-restricted-imports**
- CI remains the source of truth for merge readiness
- Feature branches must still satisfy proof gates before merge, including auth and RLS verification

## Data Model Decisions

- `Job` maps to **Remembrall**
- `JobTemplate` remains the conceptual source for reusable templates / master Remembralls
- `JobRequirement` maps to **Requirement**
- Nested Remembralls remain supported through a nullable **nestedRemembrallId** relationship on Requirement
- Private share access uses a dedicated **ShareLink** table with UUID token entries
- Public sharing state remains on Remembrall via **isPublic**, **publishedAt**, and **revokedAt**
- The design must not recreate the old **companyId everywhere** filtering model; isolation is enforced through RLS
- Template versioning is not an MVP feature, but the schema should not block future version support

## URL and Routing Decisions

- Public published Remembralls use **/{username}/{slug}**
- Private share links use **/share/{uuid}**
- Public slug routes are indexable only after explicit publish
- Private share routes are always **noindex, nofollow**
- Usernames are immutable in MVP
- Public URL uniqueness is enforced by the compound public identity **(username, slug)**

## Scope Decisions

- E1 implementation scope assumes the E0 auth and RLS choices above are final
- Recipient save-state migration belongs to **E2**, not E1
- RBAC, audit triggers, org hierarchy, and non-MVP enterprise controls remain post-MVP

## Process Rules

- Feature branches merge; x-branches do not
- Research findings must exist before decisions are locked
- No implementation work may override these decisions without a new documented research pass and explicit approval
