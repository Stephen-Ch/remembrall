# E0 Auth Research — Findings
_x/e0-auth-research | 2026-05-06 | Claude (autonomous agentic session)_

**PROMPT-ID:** REMEMBRALL-E0-AUTH-RESEARCH-20260506-001
**Source:** Auth.js v5 documentation, Prisma adapter docs, web research (May 2026)
**Deliverable for:** `docs/status/e0-auth-findings.md` per NEXT.md

---

## Summary Verdict

Auth.js satisfies the core MVP auth requirements with one significant caveat and one decision required.

| Question | Verdict |
|---|---|
| Stable user ID and ownership | ✅ YES — Prisma adapter provides stable cuid-based user ID |
| Session handling | ✅ YES — database sessions via Prisma adapter |
| Recipient state migration | ⚠️ PARTIAL — Auth.js has no built-in anonymous→registered migration; custom logic required |
| Email/password + magic link both in MVP | ⚠️ DECISION REQUIRED — technically possible but adds complexity; recommend one for MVP |
| Auth.js session compatible with dbForUser SET LOCAL | ✅ YES — clear implementation path confirmed |

---

## Question 1: Stable user ID, ownership, session handling, recipient state migration

### Stable User ID
**CONFIRMED.** Auth.js with the Prisma adapter creates a `User` record with a stable `id` field (`@default(cuid())`). This ID is assigned once on first sign-in and persists across all sessions. It is the correct anchor for ownership of Remembralls.

Prisma schema pattern:
```prisma
model User {
  id    String @id @default(cuid())
  email String @unique
  // ...
}
```

### Ownership
**CONFIRMED.** The stable user ID is the right FK for `Remembrall.ownerId`. Multiple sessions, multiple devices — same user ID throughout.

### Session Handling
**CONFIRMED** for database sessions. Auth.js supports two strategies:
- **JWT sessions** — fast, stateless, stored in a signed cookie. No DB lookup per request. Cannot be immediately revoked.
- **Database sessions** — session record in DB, `sessionToken` in cookie. Every request hits the session table. Immediate revocation by deleting the row.

**For Remembrall, use database sessions.** The dbForUser RLS pattern requires the user ID to be reliably available server-side on every request. Database sessions + Prisma adapter provide this consistently. JWT sessions can also work (user ID in JWT claim, decoded server-side via `auth()`) but require extra `jwt`/`session` callback wiring to expose `userId`.

### Recipient State Migration
**PARTIAL — requires custom logic.** Auth.js has no built-in mechanism for migrating anonymous user state to a registered account. For Remembrall's "recipient checks items, then registers" flow:

- Before registration: checklist state would need to be stored in a cookie or a temporary anonymous session keyed to a device/browser
- On registration/sign-in: a server action must read the anonymous state and write it to the new user account
- This is a known pattern but is not free — estimate 1 sprint of E2 scope

**Decision for Stephen:** The MVP scope for E2 includes "Cookie-persisted checkbox state" and "Save to account / Register CTA". The migration logic belongs in E2, not E1. Defer to E2. No blocker for E1.

---

## Question 2: Email/password + magic link — both in MVP or choose one?

### Both Are Technically Supported
- **Email/password:** via `CredentialsProvider` — requires storing hashed passwords, implementing a registration flow, and building password reset
- **Magic link:** via `EmailProvider` — sends a time-limited token link; no password stored; requires a transactional email provider (Resend, SendGrid, etc.)

### Recommendation: Choose One for MVP

**Magic link only** is the lower-risk MVP choice:
- No password storage or hashing logic
- No password reset flow needed
- Simpler registration (just email + send link)
- Auth.js Email provider is well-documented and production-ready
- Reduces E1 scope significantly

**Credentials (email/password)** adds:
- Password hashing (`bcrypt`/`argon2`)
- Registration form + validation
- Password reset flow (which is essentially magic link anyway)
- Known limitation: Credentials provider is designed for JWT sessions by default; wiring it to database sessions requires extra `session`/`jwt` callback configuration

**One flag:** Auth.js documentation and 2026 community sources note that the maintainers now direct new projects toward [Better Auth](https://www.better-auth.com/) for complex credential flows. For magic-link-only MVP, Auth.js v5 remains appropriate and well-supported. If credentials + magic link are both required, reconsider Better Auth in a future x-branch before E1 starts.

**Decision required from Stephen/GPT:** Magic link only vs. both. This blocks the Auth.js confirmation in the E0 hardening checklist.

---

## Question 3: Auth.js session compatible with dbForUser SET LOCAL pattern?

**CONFIRMED — clear implementation path.**

The dbForUser pattern works as follows:
1. Request arrives; Auth.js `auth()` call returns session including `session.user.id`
2. Server action or API route passes `userId` into `dbForUser(userId)`
3. `dbForUser` wrapper opens a Prisma transaction, executes `SET LOCAL app.current_user_id = '<userId>'`
4. All queries within the transaction run under this context — RLS policies read `current_setting('app.current_user_id')` to enforce row-level isolation

The Auth.js session provides `user.id` via:
- Server components: `const session = await auth()` → `session.user.id`
- Route handlers: same
- Server actions: same
- Middleware: available via `auth` export

No incompatibility. Auth.js session → user ID → SET LOCAL → RLS is a confirmed pattern used in production with Supabase.

**One prerequisite:** The Prisma adapter must be configured so that `session.user.id` is available in the session object. With database sessions this is automatic. With JWT sessions it requires adding a `session` callback:

```typescript
callbacks: {
  session({ session, token }) {
    session.user.id = token.sub  // ensure user ID is in session
    return session
  }
}
```

With database sessions + Prisma adapter, this is not needed — `session.user.id` is populated automatically.

---

## Ecosystem Flag (Low Priority, Worth Noting)

Auth.js v5 hit stable in late 2024 and is production-ready. However, 2026 community sources indicate the maintainers now direct new projects with complex credential needs toward **Better Auth**. For Remembrall's MVP (magic link only + RLS ownership), Auth.js v5 is fully appropriate. If requirements evolve beyond MVP to include multi-provider, social login, or complex credential flows, revisit this decision before E1 starts.

---

## Answers to E0 Hardening Checklist Items

From `docs/project/EPICS.md` E0 gate:

| Checklist Item | Status |
|---|---|
| Auth architecture confirmed: Auth.js + Prisma + dbForUser wrapper (Option A) | ✅ CONFIRMED with caveat: choose magic link only for MVP |
| dbForUser wrapper spec written and CI lint gate defined | ⏳ Deferred to x/e0-rls-pattern |

---

## Decisions Required Before E0 Can Close

1. **Email/password vs. magic link only for MVP** — recommend magic link only; requires Stephen/GPT sign-off
2. **Recipient state migration scope** — recommend defer to E2; confirm this is acceptable

---

## Next x-Branch

`x/e0-rls-pattern` — confirm Prisma + Supabase + RLS setup and write the dbForUser wrapper spec. Auth.js findings above feed into it: database sessions confirmed, `session.user.id` is the userId source.
