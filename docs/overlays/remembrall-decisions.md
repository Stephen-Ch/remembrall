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
- **Offline mode is E1 scope** — Service Worker + IndexedDB; core checklist functionality must work without network access
- **AI feature (E3) is document import/conversion**, not freeform generation — users upload, attach, or paste existing documents; AI structures them into a Remembrall; users always edit before saving
- Document import is MVP because content creators and influencers need to bring existing content in
- RBAC, audit triggers, org hierarchy, and non-MVP enterprise controls remain post-MVP

## ShareLink Table Schema

_Drafted 2026-05-06. Awaiting Stephen review and sign-off before E0 closes._

```prisma
model ShareLink {
  id           String     @id @default(cuid())
  token        String     @unique @default(uuid())   // UUID — used in /share/{token} URL
  remembrallId String
  remembrall   Remembrall @relation(fields: [remembrallId], references: [id], onDelete: Cascade)
  createdById  String                                // denormalized owner ID at creation time
  createdAt    DateTime   @default(now())
  expiresAt    DateTime?                             // null = no expiry
  revokedAt    DateTime?                             // null = still active
  accessCount  Int        @default(0)                // incremented on each recipient view
}
```

**Constraints and rules:**
- `token` is a UUID generated at row creation — never exposed in the primary key, always via the token field
- `onDelete: Cascade` — revoking a Remembrall deletes all its share links
- `expiresAt` and `revokedAt` are both nullable; both must be checked at serve time — a link is only active if it has no `revokedAt` and either no `expiresAt` or `expiresAt` is in the future
- `accessCount` is incremented by the recipient view handler; it is informational, not a rate limit gate
- No FK from `createdById` to `User` — the Remembrall's RLS owner check is the security gate; this field is for auditability only
- MVP: one share link per Remembrall. Multiple active links per Remembrall is post-MVP.

---

## Nested Sharing: Cycle Prevention

_Drafted 2026-05-06. Awaiting Stephen review and sign-off before E0 closes._

Nested Remembralls (via `Requirement.nestedRemembrallId`) must not create cycles (A → B → A or deeper).

**Approach: depth-limited traversal check on write**

When a `nestedRemembrallId` is set on a Requirement, the server action must:

1. Traverse the nesting chain **starting from the target Remembrall** — following each nested Remembrall's own requirements upward
2. If the **source Remembrall's ID** appears anywhere in that chain, reject with a clear error: `"This would create a circular reference."`
3. If the chain exceeds **depth limit 5**, reject: `"Nesting is limited to 5 levels."`
4. Only if both checks pass does the Prisma write proceed

**Why traversal check, not constraint:**  
Postgres cannot enforce cycle detection natively across rows. The check lives in the server action layer, guarded by `dbForUser` — so it runs under the same RLS context as the write and cannot be bypassed by raw DB access.

**Depth limit:** 5 is the initial value. It is defined as a named constant (`MAX_NEST_DEPTH = 5`) in the server action layer, not hardcoded inline, so it can be adjusted without a code search.

---

## CI Evidence Standard for Copilot Signoff

_Drafted 2026-05-06. Awaiting Stephen review and sign-off before E0 closes._

Before Stephen accepts a Copilot pull request merge on any E1+ feature branch, Copilot must provide all of the following in the PR or in its response:

**Required evidence:**
1. **Test run output** — paste or screenshot showing all tests pass with 0 failures (file name + count is sufficient; no need for full output unless failures exist)
2. **RLS matrix** — confirm all 6 isolation scenarios passed (own data visible, other user data invisible, unauthenticated blocked, null user ID blocked, revoked share blocked, expired share blocked)
3. **Lint clean** — `eslint --max-warnings 0` passed; no raw PrismaClient imports outside `lib/db.ts`
4. **No direct Prisma calls outside dbForUser** — Copilot confirms this was checked, not just assumed

**What is NOT required:**
- 100% code coverage
- Performance benchmarks
- Full test output transcripts unless failures exist

**Format:** Copilot may provide evidence inline in a response or as a PR description block. Either is acceptable. If CI is not yet wired, Copilot runs the commands locally and pastes results.

**Escalation:** If any check fails, Copilot reports the failure and stops. Stephen decides whether to fix-and-recheck or defer.

---

## Remaining Open Items (not yet decided)

These three items are awaiting a quick product decision from Stephen before E0 formally closes:

- **Reserved username/route list** — routes like `admin`, `api`, `dashboard`, `share`, `settings` must be blocked from user registration. Need: Stephen approves the list.
- **AI logging privacy rule** — EPICS.md says "log metadata only, no raw user input." Need: confirm this is complete as written or add specifics.
- **Offline mode** — EPICS.md says Post-MVP (Service Worker + IndexedDB). Need: confirm formally closed for E0.

---

## Process Rules

- Feature branches merge; x-branches do not
- Research findings must exist before decisions are locked
- No implementation work may override these decisions without a new documented research pass and explicit approval
