# E0 Schema Study — Findings
_x/e0-schema-study | May 2026 | Claude_

Source: `C:\Users\schur\workspaces\Remembrall\trunk` (v0.2, ASP.NET Core 3.1 + SQL Server)

---

## Data Model — Name Mapping

The original codebase used internal names that differ from product names. This is the canonical mapping for the rebuild:

| v0.2 name | Rebuild name | Notes |
|---|---|---|
| `Job` | `Remembrall` | The instance a user runs |
| `JobTemplate` | Template / master Remembrall | Reusable master; Job was created from a template |
| `JobRequirement` | `Requirement` | A checklist item |
| `RequirementJobTemplate` field | Nested Remembrall link | The nesting mechanism — a requirement could reference another template |
| `Channel` | Channel | Organizational layer (post-MVP) |
| `SubChannel` | Sub-channel | Nested org layer (post-MVP) |
| `Department` | Department | Higher org grouping |
| `Company` / `CompanyId` | Account | Top-level tenant — every Job, User, and Channel carried a `companyId` |

---

## Original Schema (key tables)

### JobTemplate
```
Id, JobId (string slug), JobName, JobDescription, JobRound,
JobDate, ChannelId, IsActive, CreatedBy, ModifiedBy, ModifiedDate
```

### Job (instance of a template, run by a user)
```
id, jobId (string), jobName, jobDescription, jobRound, jobDate,
isCompleted, completedDate, isDeleted, deletedDate, createdDate,
channelId, subChannelId, type, userID, departmentId, companyId
```

### JobRequirement / JobTemplateRequirement
```
id, requirementNo (order), requirementTitle, requirementDesc,
requirementNotes, requirementJobTemplate (nested template link),
jobTemplateId, isCompleted
```

### Users
```
id, firstName, lastName, email, userId, channelId, employeeTypeId,
departmentId, companyId, createdDate, modifiedDate
```

### Channel / SubChannel
```
Channel: Id, ChannelName, IsActive, CreatedBy, ModifiedBy, IsDeleted
SubChannel: id, channelId, subChannelName, channelName, userId
```

### Supporting tables
`Company`, `Department`, `Roles`, `UserRole`, `RolePrivileges`, `ApplicationRoute`,
`EmployeeType`, `UserChannelAssociation`, `UserDepartmentAssociation`,
`EmailConfiguration`, `AccountActivator`, `ResetPassword`

---

## Key Findings

### 1. No public sharing / no privacy model in v0.2
The public view (`Proc_ReadOnlyGetJobDetailsById`) was accessed by `@JobId + @JobName` — essentially a human-readable URL slug. There was no `isPublic` flag, no `shareToken`, no UUID link, no revocation. Anyone who knew the jobId + jobName could read it.

**Rebuild implication:** The entire public/private visibility model, share tokens, and revocation are new in the 2026 rebuild. There is nothing to port here — design from scratch per the dev plan.

### 2. CopyRemembrAll existed — the viral loop was real
`Proc_MakeRemembrAllCopy` copied a Job to a new user's account. This was the v0.2 viral loop: a recipient could save a copy to their own account. The data model for this was simple (userId + jobId + jobName).

**Rebuild implication:** The "Save to my account" CTA in E2 has a direct v0.2 precedent. The copy operation is well-understood.

### 3. Template versioning
Editing a JobTemplate did not overwrite it. The old version was set `IsActive=0` and a new version was inserted with a `_1`, `_2` suffix. This preserved history.

**Rebuild implication:** MVP does not need versioning. But the data model should not preclude it. Don't add a hard `UNIQUE` constraint on `(userId, slug)` alone — add `isActive` or `version` to the Remembrall table to keep the door open.

### 4. Nesting was implemented via `RequirementJobTemplate`
A requirement had a `requirementJobTemplate` field that referenced another template. This was the nesting mechanism.

**Rebuild implication:** The `Requirement` model needs a `nestedRemembrallId` field (nullable FK to Remembrall). This confirms the nested Remembrall concept was real and working in v0.2, not just planned.

### 5. Multi-tenancy was `companyId` everywhere — no RLS
Every table carried `companyId`. Isolation was enforced in stored procedures (`WHERE CompanyId = @CompanyId`). No row-level security.

**Rebuild implication:** This is exactly the application-level filtering risk our architecture decisions addressed. Do not replicate this pattern. Use RLS as decided in E0.

### 6. Auth was fully custom — email activation + password reset
No OAuth, no magic links. Email-based activation (`AccountActivator` table), password reset (`ResetPassword` table), all custom stored procedures. Sessions were presumably cookie-based.

**Rebuild implication:** Auth.js replaces all of this. Nothing to port.

### 7. RBAC existed (Roles, RolePrivileges, ApplicationRoute)
A full role/privilege system was in v0.2 with `readAccess`, `noAccess`, `fullAccess` per route.

**Rebuild implication:** This is post-MVP. Do not build it for E1. The data model should not preclude it (keep `role` field on User), but implement nothing beyond owner/recipient in MVP.

### 8. Audit logs existed for Channel (trigger-based)
SQL triggers wrote to `AuditLog_Channel` on insert/update.

**Rebuild implication:** Post-MVP. Architecture must not preclude it (i.e., don't delete-hard by default), but do not implement triggers or audit tables in MVP.

### 9. JobRound field — unclear purpose
Both Job and JobTemplate had a `jobRound` field. Not explained in code. Possibly an iteration counter or a round-number for a recurring procedure.

**Rebuild implication:** Skip for MVP. If it comes up in UX review of wireframes, revisit.

---

## Rebuild Data Model (draft for ARCHITECTURE.md)

Informed by v0.2 but redesigned for multi-tenancy, public sharing, and Prisma/Postgres.

```prisma
model User {
  id           String      @id @default(uuid())
  email        String      @unique
  username     String      @unique
  passwordHash String?
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
  shareVisible Boolean       @default(false)  // can be exposed as a nested child
  createdAt    DateTime      @default(now())
  updatedAt    DateTime      @updatedAt
  requirements Requirement[]
  shareLinks   ShareLink[]

  @@unique([ownerId, slug])
}

model Requirement {
  id                  String      @id @default(uuid())
  remembrallId        String
  remembrall          Remembrall  @relation(fields: [remembrallId], references: [id])
  orderNo             Int
  title               String
  description         String?
  notes               String?
  nestedRemembrallId  String?     // nullable FK — the nesting mechanism
  createdAt           DateTime    @default(now())
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

---

## What v0.2 confirms we can skip
- Stored procedures — Prisma handles this
- Manual audit triggers — post-MVP
- Custom email activation — Auth.js handles this
- CompanyId-everywhere pattern — replaced by RLS
- Custom session management — Auth.js handles this

## What v0.2 confirms we should keep
- CopyRemembrAll (Save to my account) — real, worked, port the concept
- Nesting via requirement field — real, worked, port as `nestedRemembrallId`
- `shareVisible` flag on Remembrall — implicit in v0.2, make it explicit in rebuild

---

## Status
Findings complete. Ready to feed into ARCHITECTURE.md on the E0 docs feature branch.
