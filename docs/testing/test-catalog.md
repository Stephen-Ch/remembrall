# Remembrall — Test Catalog

## RLS Test Matrix

These 6 scenarios MUST pass on every feature branch before merge. They are not optional and do not get skipped for time.

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Owner reads their own Remembrall | ✅ Returns data |
| 2 | Owner writes (create/edit/delete) their own Remembrall | ✅ Success |
| 3 | Authenticated user reads another user's private Remembrall | ❌ 0 rows / 403 |
| 4 | Anonymous request (no session) reads any private Remembrall | ❌ 0 rows / 401 |
| 5 | Public slug request reads a public Remembrall by slug | ✅ Returns data |
| 5b | Public slug request reads a private Remembrall | ❌ 404 |
| 6 | Private UUID share token reads the specific Remembrall | ✅ Returns data |
| 6b | Private UUID share token used to enumerate other Remembralls | ❌ 0 rows |
| 7 | Nested Remembrall: recipient following nested link reads parent | ❌ 403 |
| 7b | Nested Remembrall: recipient following nested link reads sibling | ❌ 403 |

All tests must use a real database connection (non-owner role), not mocks. RLS is invisible to mocks.

---

## Auth Boundary Tests

Required for any feature branch that touches auth or visibility:

- Unauthenticated request to a protected route returns 401 (never 200, never 500)
- A user cannot access another user's account settings
- Session expiry redirects to login without leaking data
- Recipient cookie state is correctly scoped (not readable by other sessions)

---

## Proof Gate Checklist (per feature branch)

Before presenting a feature branch for Product Owner review, Copilot must confirm ALL of the following and quote CI evidence:

```
[ ] Tests written before implementation (TDD)
[ ] Migration reviewed and tested against real DB
[ ] RLS test matrix: all scenarios above pass (quote test output)
[ ] Auth boundary test: exists and passes
[ ] Preview URL live on Vercel: <paste URL>
[ ] CI command run: <paste exact command>
[ ] Test count: <N> passing, <N> failing, <N> skipped
[ ] No secrets in code or .env committed
[ ] No new public route without allowlist entry
[ ] Acceptance checklist for this epic: fully passed
```

Signoff without this evidence is not signoff.

---

## AI Generation Test Cases (E3)

20 synthetic test cases for the AI draft quality review. To be populated during E3 planning.

Categories to cover:
- Food/recipe procedure (creator use case)
- Physical therapy exercise protocol (professional expert use case)
- Municipal permit process (civic use case)
- Medication instructions (healthcare use case)
- Software deployment steps (developer use case)
- DIY home repair procedure
- School enrollment procedure
- ... (14 more to be defined in E3)

Acceptance threshold: to be defined by Product Owner before E3 begins.
