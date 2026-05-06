# NEXT — Current Work

_Updated: May 2026_

## Active Epic: E0 — Architecture and Security Decisions

E0 is in progress. Three research x-branches are planned.

---

## Active / Queued Work

### x/e0-schema-study
**Type:** x-branch (never merges)  
**Goal:** Study the original v0.2 source code (`C:\Users\schur\workspaces\Remembrall\trunk`) to extract the data model, business logic, and any decisions worth carrying forward into the rebuild.  
**Deliverable:** `docs/status/e0-schema-study-findings.md` committed to main  
**Key questions:**
- What was the original data model (Job / JobTemplate / JobRequirement / Channel / SubChannel)?
- What business logic is worth preserving vs. redesigning?
- What did the original auth/session model look like?

### x/e0-auth-research
**Type:** x-branch (never merges)  
**Goal:** Verify Auth.js satisfies the MVP auth requirements. Flag any blockers.  
**Deliverable:** `docs/status/e0-auth-findings.md` committed to main  
**Key questions:**
- Does Auth.js support stable user ID, ownership, session handling, and recipient state migration?
- Email/password + magic link: both supported in MVP, or choose one?
- Is the Auth.js session compatible with the dbForUser SET LOCAL pattern?

### x/e0-rls-pattern
**Type:** x-branch (never merges)  
**Goal:** Confirm exact Prisma + Supabase + RLS setup. Write the dbForUser wrapper spec.  
**Deliverable:** `docs/status/e0-rls-findings.md` committed to main  
**Key questions:**
- Which Postgres role does Prisma connect as in Supabase? Confirm it is non-owner.
- FORCE ROW LEVEL SECURITY: confirm syntax and that it covers the table owner.
- dbForUser wrapper: exact TypeScript signature and transaction pattern.
- CI lint gate: ESLint rule to block raw PrismaClient imports outside `lib/db.ts`.

---

## After all three x-branches complete

Create docs feature branch:
- Populate `docs/overlays/remembrall-decisions.md` with all confirmed E0 answers
- Create `docs/architecture/ARCHITECTURE.md` with data model, RLS pattern, URL strategy
- Product Owner (Stephen) reviews and approves
- Merge to main → E1 unblocked

---

## Blocked
- E1, E2, E3, E4 — all blocked on E0 completion
