# Manual Test Template

> **When to use:** Formal acceptance/regression testing or grading integrity changes.  
> **For quick validation:** Use "Quick Smoke" format (3 bullets in PR comment) instead.

---

## Test Session Info

| Field | Value |
|-------|-------|
| **Test ID** | MT-### |
| **Date** | YYYY-MM-DD |
| **Tester** | (name) |
| **PR/Story** | #NN / EPIC-###-S## |
| **Environment** | Local / DEV / STAGE |
| **DB Target** | (server/database) |

---

## Test Cases

| ID | Description | Expected Outcome | Actual | Pass/Fail |
|----|-------------|------------------|--------|-----------|
| MT-###-01 | (what to do) | (what should happen) | (what happened) | ✅ / ❌ |
| MT-###-02 | (what to do) | (what should happen) | (what happened) | ✅ / ❌ |
| MT-###-03 | (what to do) | (what should happen) | (what happened) | ✅ / ❌ |

---

## Evidence

**Screenshots/Logs:** (attach or describe)

**DB Proof (if applicable):**
    -- Query used
    -- Results summary

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | ## |
| Passed | ## |
| Failed | ## |
| **Result** | PASS / FAIL |

---

## Quick Smoke Alternative

For non-critical validation, use this format in a PR comment instead of a full MT artifact:

    **Quick Smoke — PR #NN**
    - [ ] (test 1) — PASS/FAIL
    - [ ] (test 2) — PASS/FAIL  
    - [ ] (test 3) — PASS/FAIL
    IDs tested: (list lesson/student IDs used)
