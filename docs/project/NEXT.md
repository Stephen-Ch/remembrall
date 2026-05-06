# NEXT — Current Work

_Updated: 2026-05-06_

## Active Epic: E0 — Architecture and Security Decisions

All three research x-branches complete. E0 is in the decision/docs phase.

---

## Completed X-Branches

### ✅ x/e0-schema-study
**Findings:** `docs/status/e0-schema-study-findings.md`

### ✅ x/e0-auth-research
**Findings:** `docs/status/e0-auth-findings.md`
**Decisions required before E0 closes:**
- Magic link only vs. email/password + magic link for MVP (recommend magic link only)
- Recipient state migration deferred to E2 — confirm acceptable

### ✅ x/e0-rls-pattern
**Findings:** `docs/status/e0-rls-findings.md`
**Deliverables produced:** dbForUser wrapper spec + CI lint gate spec

---

## Active: E0 Docs Feature Branch

Create docs feature branch:
- Populate `docs/overlays/remembrall-decisions.md` with all confirmed E0 answers
- Create `docs/architecture/ARCHITECTURE.md` with data model, RLS pattern, URL strategy
- Product Owner (Stephen) reviews and approves
- Merge to main → E1 unblocked

---

## Blocked
- E1, E2, E3, E4 — all blocked on E0 completion
- E0 completion blocked on two Stephen/GPT decisions (see x/e0-auth-research above)
