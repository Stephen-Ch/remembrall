# E0 RLS Pattern — Findings
_x/e0-rls-pattern | 2026-05-06 | Claude (autonomous agentic session)_

**PROMPT-ID:** REMEMBRALL-E0-RLS-RESEARCH-20260506-001
**Source:** Supabase docs, Prisma docs, community research (May 2026)
**Deliverable for:** `docs/status/e0-rls-findings.md` per NEXT.md

---

## Summary Verdict

The Prisma + Supabase + RLS + dbForUser pattern is confirmed and implementable. All four questions are answered.

| Question | Verdict |
|---|---|
| Postgres role Prisma connects as | ✅ CONFIRMED — must be non-owner, non-superuser |
| FORCE ROW LEVEL SECURITY syntax | ✅ CONFIRMED — covers table owner |
| dbForUser wrapper spec | ✅ SPECIFIED — see below |
| CI lint gate (raw PrismaClient block) | ✅ SPECIFIED — see below |

---

## Question 1: Which Postgres role does Prisma connect as in Supabase?

**CONFIRMED: Must use a non-owner, non-superuser role.**

By default, Prisma connects as `postgres` — a superuser that bypasses all RLS policies. This would make every RLS policy invisible during development and testing, creating a false sense of security.

**Required setup:**

1. Create a restricted role in Supabase SQL editor:
```sql
CREATE ROLE remembrall_app WITH LOGIN PASSWORD '<strong-password>';
GRANT USAGE ON SCHEMA public TO remembrall_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO remembrall_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO remembrall_app;
-- Grant future tables too
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO remembrall_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO remembrall_app;
```

2. Use this role in the Prisma connection string:
```
DATABASE_URL=postgresql://remembrall_app:<password>@<host>.supabase.co:5432/postgres
```

3. **Never use the `postgres` superuser in the application.** Use it only for schema migrations (separate `DIRECT_URL` in Prisma config).

**Prisma `schema.prisma` pattern:**
```prisma
datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")      // remembrall_app role — RLS enforced
  directUrl = env("DIRECT_URL")         // postgres superuser — migrations only
}
```

---

## Question 2: FORCE ROW LEVEL SECURITY — syntax and table owner coverage

**CONFIRMED.** Standard RLS (`ENABLE ROW LEVEL SECURITY`) still allows table owners to bypass policies. `FORCE ROW LEVEL SECURITY` closes this gap.

**Required SQL for every user-scoped table:**
```sql
ALTER TABLE "Remembrall" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Remembrall" FORCE ROW LEVEL SECURITY;

ALTER TABLE "Requirement" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Requirement" FORCE ROW LEVEL SECURITY;
```

**Why FORCE matters:** Without it, if Prisma ever connects as a table owner (e.g., during a misconfigured migration), RLS is silently bypassed. FORCE makes RLS apply unconditionally — to all roles including owners. This is the correct default for a multi-tenant app.

**RLS policy pattern (owner access):**
```sql
-- Owner can see their own Remembralls
CREATE POLICY "owner_select" ON "Remembrall"
  FOR SELECT USING (
    "ownerId" = current_setting('app.current_user_id', TRUE)
  );

-- Owner can write their own Remembralls
CREATE POLICY "owner_write" ON "Remembrall"
  FOR ALL USING (
    "ownerId" = current_setting('app.current_user_id', TRUE)
  );
```

The `TRUE` second argument to `current_setting` means: return NULL instead of throwing an error if the setting is not defined (e.g., in unauthenticated contexts). RLS policies evaluate NULL as falsy, so unset user ID = no access.

---

## Question 3: dbForUser wrapper — exact TypeScript signature and transaction pattern

**SPECIFIED.**

**File location:** `lib/db.ts` — the only file in the codebase that may import PrismaClient directly.

**Full wrapper:**
```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

/**
 * Execute a database operation as a specific user.
 * Sets app.current_user_id in a transaction-local Postgres session variable,
 * so RLS policies can enforce row-level isolation.
 *
 * @param userId - The authenticated user's stable ID (from Auth.js session)
 * @param fn - Callback receiving a transaction-scoped Prisma client
 */
export async function dbForUser<T>(
  userId: string,
  fn: (tx: Omit<PrismaClient, '$connect' | '$disconnect' | '$on' | '$transaction' | '$use' | '$extends'>) => Promise<T>
): Promise<T> {
  return prisma.$transaction(async (tx) => {
    await tx.$executeRawUnsafe(
      `SET LOCAL "app.current_user_id" = '${userId.replace(/'/g, "''")}'`
    )
    return fn(tx)
  })
}

export { prisma }
```

**Usage in a server action:**
```typescript
import { auth } from '@/auth'
import { dbForUser } from '@/lib/db'

export async function getMyRemembralls() {
  const session = await auth()
  if (!session?.user?.id) throw new Error('Unauthorized')

  return dbForUser(session.user.id, (tx) =>
    tx.remembrall.findMany()
  )
}
```

**Security note on SET LOCAL:** `SET LOCAL` is transaction-scoped — the variable is automatically cleared when the transaction ends (commit or rollback). There is no risk of user ID leaking across requests.

**Security note on SQL injection in SET LOCAL:** The userId comes from Auth.js, which derives it from a database record. It is a cuid string (alphanumeric). The `replace` call above is a belt-and-suspenders guard — single quotes escaped. In practice, a cuid cannot contain a single quote.

**Alternative using `set_config`:**
```typescript
await tx.$executeRaw`SELECT set_config('app.current_user_id', ${userId}, TRUE)`
```
This is parameterized and avoids the string interpolation concern entirely. **Prefer this form.**

**Revised recommended implementation:**
```typescript
export async function dbForUser<T>(
  userId: string,
  fn: (tx: Omit<PrismaClient, '$connect' | '$disconnect' | '$on' | '$transaction' | '$use' | '$extends'>) => Promise<T>
): Promise<T> {
  return prisma.$transaction(async (tx) => {
    // set_config with transaction-local=TRUE — parameterized, no injection risk
    await tx.$executeRaw`SELECT set_config('app.current_user_id', ${userId}, TRUE)`
    return fn(tx)
  })
}
```

---

## Question 4: CI lint gate — ESLint rule to block raw PrismaClient imports

**SPECIFIED.**

**Goal:** Ensure no file outside `lib/db.ts` imports PrismaClient directly. Raw Prisma access bypasses the dbForUser wrapper and therefore bypasses RLS.

**ESLint rule using `no-restricted-imports`:**

In `.eslintrc.js` (or `eslint.config.js` for flat config):
```javascript
module.exports = {
  rules: {
    'no-restricted-imports': [
      'error',
      {
        paths: [
          {
            name: '@prisma/client',
            message:
              'Do not import PrismaClient directly. Use dbForUser() from lib/db.ts to ensure RLS enforcement.',
          },
        ],
      },
    ],
  },
  overrides: [
    {
      // lib/db.ts is the only allowed exception
      files: ['lib/db.ts'],
      rules: {
        'no-restricted-imports': 'off',
      },
    },
  ],
}
```

**What this catches:**
```typescript
// ❌ This will fail the lint gate in any file except lib/db.ts:
import { PrismaClient } from '@prisma/client'

// ✅ This is the only allowed pattern:
import { dbForUser } from '@/lib/db'
```

**CI integration:** Add `eslint --max-warnings 0` to the CI pipeline. The lint gate runs on every PR and blocks merge if any file imports PrismaClient outside `lib/db.ts`.

---

## Answers to E0 Hardening Checklist Items

From `docs/project/EPICS.md` E0 gate:

| Checklist Item | Status |
|---|---|
| dbForUser wrapper spec written and CI lint gate defined | ✅ COMPLETE — see above |
| Auth architecture confirmed: Auth.js + Prisma + dbForUser wrapper (Option A) | ✅ CONFIRMED — see e0-auth-findings.md |

---

## Remaining E0 Checklist Items (not covered by auth or RLS research)

These items from the E0 hardening checklist are not yet resolved by these two x-branches:

| Item | Status | Notes |
|---|---|---|
| ShareLink table schema finalized | ⏳ OPEN | Blocked until data model is confirmed post-schema-study |
| Nested sharing rule + cycle prevention | ⏳ OPEN | Requires data model confirmation |
| Reserved username/route list agreed | ⏳ OPEN | Product decision for Stephen |
| AI logging privacy rule documented | ⏳ OPEN | Anthropic API usage; log metadata only (confirmed in EPICS.md) |
| CI evidence standard for Copilot signoff defined | ⏳ OPEN | Process decision |
| Offline mode explicitly deferred | ⏳ OPEN | Confirm closed (EPICS.md says Post-MVP) |

---

## What E0 Completion Requires Now

1. **Stephen decision:** Magic link only vs. email/password + magic link (see e0-auth-findings.md)
2. **Stephen/GPT decision:** Recipient state migration deferred to E2 — confirm acceptable
3. **Remaining E0 checklist items** resolved (see table above)
4. Create docs feature branch:
   - Populate `docs/overlays/remembrall-decisions.md` with confirmed E0 answers
   - Create `docs/architecture/ARCHITECTURE.md` with data model, RLS pattern, URL strategy
   - Stephen reviews and approves → merge to main → E1 unblocked
