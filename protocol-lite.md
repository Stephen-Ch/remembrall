# Protocol Lite — Quick Reference

> **File Version:** 2026-02-09  
> **Purpose:** Reduce session startup cognitive load. For full rules, see [protocol-v7.md](protocol/protocol-v7.md).

---

## The Tiered Confidence Rule (Core Gate)

**If confidence is below the threshold for the scope, STOP and gather evidence.**

| Scope | Threshold | Action |
|-------|-----------|--------|
| Low-risk (docs, tests, reports) | ≥95% | May proceed |
| Production/runtime code | ≥99% | May proceed |
| Below threshold | — | Enter RESEARCH-ONLY mode |

For definitions of what 95%/99% confidence means, dual-agent requirements, and handshake phrases, see the canonical section:

→ [protocol-v7.md § No Guessing / Tiered Confidence Gate](protocol/protocol-v7.md#no-guessing--tiered-confidence-gate-mandatory)

---

## RESEARCH-ONLY vs INSTRUMENTATION

| Mode | Code Changes | When to Use |
|------|--------------|-------------|
| **RESEARCH-ONLY** | ❌ None | Confidence <95%, investigation without runtime observation |
| **INSTRUMENTATION (CODE-OK)** | ✅ Temporary diagnostics | Need runtime output to diagnose; explicitly approved |

**RESEARCH-ONLY Allowed:** `read_file`, `grep_search`, `git log/diff/status`, SELECT queries, creating `R-###` docs

**RESEARCH-ONLY Forbidden:** Editing runtime code, opening PRs with code changes, builds that modify state

**Prior Research Lookup (MANDATORY):**
- Every RESEARCH-ONLY output MUST search ResearchIndex.md + research/ folder first
- List commands used (rg/grep) + matching R-### IDs found + which were read
- OR state "No relevant prior research found" (only after searching)
- **If missing, the output is INVALID** — stop and add the lookup

**Exiting RESEARCH-ONLY:** Complete an Evidence Pack + confidence ≥95%

→ Full rules: [protocol-v7.md § RESEARCH-ONLY Command Lock](protocol/protocol-v7.md#research-only-command-lock-mandatory)
→ Handoff template: [research-request-template.md](templates/research-request-template.md) — structured format for GPT↔Copilot research requests

---

## Evidence Pack (When <95%)

Every research effort produces an **Evidence Pack** in `<DOCS_ROOT>/research/R-###-<Title>.md`.

**Required sections:**
1. Repro Steps
2. Environment Fingerprint
3. Hard Evidence (DB proof, logs, diff, etc.)
4. Competing Hypotheses
5. Confidence Statement

**Template:** [EVIDENCE-PACK-TEMPLATE.md](templates/EVIDENCE-PACK-TEMPLATE.md)

→ Full rules: [protocol-v7.md § Evidence Pack Requirement](protocol/protocol-v7.md#evidence-pack-requirement-mandatory)

---

## Green Gate (Stack-Aware)

Run the gate that matches your project type:

| Stack | Gate Command |
|-------|--------------|
| .NET (ASP.NET MVC) | `msbuild <YourProject>.csproj /p:Configuration=Release` |
| JS (if package.json has scripts) | `npm run build` + `npm run test` |
| Docs-only | Population Gate (no TBD/TODO/PLACEHOLDER) |

**Mixed-stack project:** .NET Gate required. JS Gate N/A (no build script).

→ Full rules: [protocol-v7.md § Green Gate — Stack-Aware Rules](protocol/protocol-v7.md#green-gate--stack-aware-rules)

---

## Manual Testing

| Type | When | Format |
|------|------|--------|
| **Quick Smoke** | Non-critical validation | 3 bullets in PR comment |
| **Formal MT** | Acceptance/regression, grading changes | Full checklist artifact |

**Quick Smoke format:**

    **Quick Smoke — PR #NN**
    - [ ] (test 1) — PASS/FAIL
    - [ ] (test 2) — PASS/FAIL
    - [ ] (test 3) — PASS/FAIL
    IDs tested: (list)

**Formal template:** [MANUAL-TEST-TEMPLATE.md](templates/MANUAL-TEST-TEMPLATE.md)

→ Full rules: [protocol-v7.md § Manual Test Checklist Artifact](protocol/protocol-v7.md#manual-test-checklist-artifact-mandatory)

---

## Approver Workflow (Waiting for Maintainer)

**Allowed while PRs await approval:**
- Continue work on feature branches
- Docs-only PRs and commits
- Research and investigation
- Keep branches current (`git merge origin/develop`)

**Not allowed:**
- Merge to develop without approval
- Stack dependent PRs (avoid)
- Assume PR will merge "soon"

**PR Communication:** One Merge Packet comment per PR. If >48h, one polite ping.

**Update NEXT.md:**
- Status: BLOCKED
- Blocked By: PR #NN awaiting approval

→ Full rules: [protocol-v7.md § Waiting-for-Approver Workflow](protocol/protocol-v7.md#waiting-for-approver-workflow-mandatory)

---

## Session Startup (< 2 minutes)

Run through [session-start-checklist.md](session-start-checklist.md):

1. **RUN START OF SESSION DOCS AUDIT** — kit update, version print, Consumer-Kit Drift Gate, forGPT sync, doc-audit
2. Check NEXT.md status (ACTIVE/PAUSED/BLOCKED)
3. Check open PRs + Remote Reality
4. Confirm research is indexed

→ Consumer-Kit Drift Gate: [protocol-v7.md § Consumer-Kit Drift Gate](protocol/protocol-v7.md#consumer-kit-drift-gate-mandatory-at-session-start-in-consumer-repos)
→ Staleness Expiry Gate: [protocol-v7.md § Staleness Expiry Gate](protocol/protocol-v7.md#staleness-expiry-gate-mandatory-at-session-boundaries)
→ Decision-Queue Gate: [protocol-v7.md § Decision-Queue Gate](protocol/protocol-v7.md#decision-queue-gate-mandatory-at-session-boundaries)
→ Tool/Auth Fragility Gate: [protocol-v7.md § Tool/Auth Fragility Gate](protocol/protocol-v7.md#toolauth-fragility-gate-mandatory-at-session-boundaries)

**End of session:** Run `run-vibe -Tool end-session` for the full contract (Active Lane + Remote Reality + Workspace Reality → `CLEAN FIELD READY: YES/NO`).

→ Full contract: [protocol-v7.md § End-of-Session Full Contract](protocol/protocol-v7.md#end-of-session-full-contract-canonical-meaning-of-run-end-of-session)  
→ Workspace Reality Gate: [protocol-v7.md § Workspace Reality Gate](protocol/protocol-v7.md#workspace-reality-gate-mandatory-at-session-close)

---

## Mid-Session Reset (Confusion Recovery)

Say **RUN MID-SESSION RESET** when you lose confidence about the current state mid-session.

Steps: **STOP edits → Reality Snapshot → Classify Confusion → Research-Only if <95% → State Next Safe Step**

Confusion buckets: branch confusion, scope confusion, docs/state drift, hidden-work fear, confidence too low.

→ Full protocol: [protocol-v7.md § Mid-Session Reset](protocol/protocol-v7.md#mid-session-reset-operator-confusion-recovery)

---

## Branch Hygiene

**Check for orphan branches:**

    git branch -a --no-merged origin/develop | Select-String -NotMatch "docs/"

If runtime branches exist without PRs: open PR or document in [branches.md](../status/branches.md).

---

## Key Pointers

| Doc | Purpose |
|-----|---------|
| [protocol-v7.md](protocol/protocol-v7.md) | **Authoritative full protocol** |
| [hard-rules.md](protocol/hard-rules.md) | **Mandatory gates only (<2KB)** |
| [session-start-checklist.md](session-start-checklist.md) | Pre-flight checks |
| [PAUSE.md](PAUSE.md) | Session handoff state |
| [EVIDENCE-PACK-TEMPLATE.md](templates/EVIDENCE-PACK-TEMPLATE.md) | For <95% confidence |
| [MANUAL-TEST-TEMPLATE.md](templates/MANUAL-TEST-TEMPLATE.md) | Formal test checklists |
| [branches.md](../status/branches.md) | Branch/PR tracking |

---

## Do Not Duplicate

This doc is a quick-reference entrypoint. **Do not add new rules here.**

- All rules live in [protocol-v7.md](protocol/protocol-v7.md)
- Update protocol-v7.md for rule changes
- This doc links to sections; it does not redefine them
