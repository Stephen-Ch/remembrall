# Remembrall Architecture

_Last updated: 2026-05-06_  
_Basis: E0 schema study, auth research, and RLS pattern findings_

## Purpose

This document captures the implementation-shaping architecture decisions that close E0. It defines the data model direction, auth flow, URL strategy, and database isolation pattern that E1 must build against.

---

## Confirmed Stack

- **Frontend + API:** Next.js current stable with App Router
- **ORM:** Prisma
- **Database:** PostgreSQL on Supabase
- **Auth:** Auth.js v5 with Prisma adapter
- **Hosting:** Vercel
- **AI integration:** Anthropic API

This stack is confirmed and unblocked for E1.

## Legacy Model Mapping

The v0.2 product used internal names that differ from the rebuild. The canonical mapping is:

| v0.2 name | Rebuild name | Meaning |
|---|---|---|
| `Job` | `Remembrall` | A user-owned instance that can be created, edited, and shared |
| `JobTemplate` | Template / master Remembrall | Reusable source pattern for Remembralls |
| `JobRequirement` | `Requirement` | Ordered checklist item within a Remembrall |
| `RequirementJobTemplate` | `nestedRemembrallId` | Nested Remembrall link |
| `Company` / `CompanyId` | Account / tenant concept | Legacy tenancy pattern; not reused for access control |
| `Channel`, `SubChannel`, `Department` | Post-MVP organizational structures | Out of MVP scope |

## Data Model Direction

### Core entities

- **User** owns Remembralls and authenticates through Auth.js
- **Remembrall** is the primary user-owned object
- **Requirement** is an ordered checklist item belonging to a Remembrall
- **ShareLink** stores private UUID-based share tokens separately from the Remembrall row

### Confirmed model rules

- Ownership anchors on `User.id` from Auth.js
- `Remembrall.ownerId` is the access-control root for user-scoped data
- Public visibility stays on Remembrall with `isPublic`, `publishedAt`, and `revokedAt`
- Private access uses ShareLink rows instead of inline token fields
- Requirement supports nesting through nullable `nestedRemembrallId`
- The design should keep room for future versioning and should not assume Remembrall history is overwrite-only

### Legacy findings that shape the rebuild

- v0.2 had no real privacy model for sharing; public access was effectively slug-based knowledge
- v0.2 supported copy-to-my-account behavior, which validates the later E2 save-to-account pattern
- v0.2 implemented nesting through a requirement-level template reference, which confirms nested Remembralls are a real product behavior and not a new invention
- v0.2 relied on application filtering with `companyId`; the rebuild must not repeat that pattern

### Draft schema shape

```prisma
model User {
  id           String      @id @default(cuid())
  email        String      @unique
  username     String      @unique
  createdAt    DateTime    @default(now())
  remembralls  Remembrall[]
  shareLinks   ShareLink[]
}

model Remembrall {
  id           String        @id @default(uuid())
  ownerId      String
  owner        User          @relation(fields: [ownerId], references: [id])
  slug         String
  title        String
  description  String?
  isPublic     Boolean       @default(false)
  publishedAt  DateTime?
  revokedAt    DateTime?
  shareVisible Boolean       @default(false)
  createdAt    DateTime      @default(now())
  updatedAt    DateTime      @updatedAt
  requirements Requirement[]
  shareLinks   ShareLink[]
}

model Requirement {
  id                 String      @id @default(uuid())
  remembrallId       String
  remembrall         Remembrall  @relation(fields: [remembrallId], references: [id])
  orderNo            Int
  title              String
  description        String?
  notes              String?
  nestedRemembrallId String?
  createdAt          DateTime    @default(now())
}

model ShareLink {
  id           String     @id @default(uuid())
  remembrallId String
  remembrall   Remembrall @relation(fields: [remembrallId], references: [id])
  token        String     @unique
  kind         String     @default("private")
  createdAt    DateTime   @default(now())
  revokedAt    DateTime?
  lastUsedAt   DateTime?
}
```

This schema shape is directional guidance for E1, not a migration artifact.

## RLS Pattern

### Connection model

- Application queries use a dedicated **non-owner Postgres role**
- Prisma must not connect as `postgres` or any superuser for normal app traffic
- Elevated credentials are reserved for migrations and named admin tasks only

### Table enforcement

Every user-scoped table must use:

```sql
ALTER TABLE "Remembrall" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Remembrall" FORCE ROW LEVEL SECURITY;

ALTER TABLE "Requirement" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Requirement" FORCE ROW LEVEL SECURITY;
```

`FORCE ROW LEVEL SECURITY` is mandatory so table ownership cannot silently bypass isolation.

### dbForUser wrapper

All user-scoped Prisma access flows through a transaction wrapper that sets the active user ID in the database session:

```typescript
export async function dbForUser<T>(
  userId: string,
  fn: (tx: Prisma.TransactionClient) => Promise<T>
): Promise<T> {
  return prisma.$transaction(async (tx) => {
    await tx.$executeRaw`SELECT set_config('app.current_user_id', ${userId}, TRUE)`
    return fn(tx)
  })
}
```

The wrapper does three important things:

- scopes the user context to one transaction
- ensures RLS policies can read `app.current_user_id`
- centralizes the only safe user-scoped database access path

### Policy shape

RLS policies compare row ownership against the session setting:

```sql
USING ("ownerId" = current_setting('app.current_user_id', TRUE))
```

If the setting is absent, access falls through to deny.

### CI guardrail

The codebase blocks raw `PrismaClient` imports outside `lib/db.ts` using ESLint `no-restricted-imports`. This is a required guardrail because direct Prisma access would bypass the wrapper and undermine RLS.

## URL Strategy

### Public route

- Published Remembralls resolve at **/{username}/{slug}**
- This route is the human-readable, shareable public URL
- Public visibility is controlled by publish state on the Remembrall row

### Private route

- Private shares resolve at **/share/{uuid}**
- The UUID token comes from ShareLink, not from the public slug
- Private share pages are always treated as non-indexable

### Routing implications

- Username and slug together define the public identity
- Usernames are immutable in MVP
- Reserved usernames must be blocked at registration to protect route namespaces

## Auth Flow

### Chosen approach

- Auth.js v5
- Prisma adapter
- Database sessions
- Magic link only

Email/password is intentionally excluded from MVP to reduce scope and eliminate password storage, reset, and credential-specific complexity.

### Request flow

1. A user requests sign-in via email
2. Auth.js sends a magic link
3. On completion, Auth.js resolves a stable `User.id`
4. Server-side application code reads `session.user.id`
5. User-scoped DB work runs through `dbForUser(session.user.id, fn)`

This gives a single consistent ownership key from auth through database isolation.

### Deferred behavior

Recipient state migration from anonymous or cookie-held progress into a newly registered account is **not part of E1**. It is explicitly deferred to **E2**.

## E1 Constraints

- No implementation may bypass `dbForUser` for user-scoped data
- No E1 work should add email/password auth
- No E1 work should implement recipient migration
- No E1 work should revert to application-level multi-tenancy filters in place of RLS

These constraints close E0 and define the safe starting conditions for E1.
