# User Story: What Stephen Wants From Vibe-Coding

> **File Version:** 2026-02-06  
> **Scope:** Portable across repos via subtree

---

## 1. User Story

**As a** solo developer working with AI coding agents (Copilot, ChatGPT, GitHub Agent),  
**I want** a structured workflow that prevents AI hallucination, enforces evidence-based decisions, and accumulates reusable knowledge,  
**So that** I can ship reliable code without wasting time on churn, duplicate research, or silent regressions.

---

## 2. Success Criteria

- [ ] AI never guesses — every structural claim has file/line/DB evidence
- [ ] Research is saved and indexed, not repeated session after session
- [ ] One prompt at a time — no background work, no parallel execution
- [ ] PRs are minimal and reviewable (Maintainer can approve without confusion)
- [ ] Session state is recoverable (PAUSE.md + forGPT packet = instant resume)
- [ ] ChatGPT writes prompts; Copilot executes; roles never blur

---

## 3. Workflow Contract

| Rule | Meaning |
|------|---------|
| **One prompt at a time** | Copilot completes current prompt before ChatGPT drafts the next |
| **Copilot executes** | Runs commands, edits files, commits code |
| **ChatGPT writes prompts** | Plans work, drafts prompts, never claims to execute |
| **No background work** | If I close VS Code, nothing continues silently |
| **Explicit handoff** | PAUSE.md captures state; forGPT packet restarts sessions |

---

## 4. Confidence + Evidence Gates

### The 95% Rule

| Confidence | Action |
|------------|--------|
| ≥95% | May proceed with implementation |
| <95% | STOP → enter RESEARCH-ONLY mode |

### What Counts as Evidence

- **File evidence:** Exact file path + line range + content snippet
- **DB evidence:** Query + result showing actual data state
- **Git evidence:** Commit SHA + diff showing what changed
- **Runtime evidence:** Log output, error message, stack trace

### Exit Criteria (RESEARCH-ONLY → Implementation)

1. Evidence Pack document created with all required sections
2. Confidence statement ≥95% with justification
3. Prior research checked (no duplicating existing R-### docs)
4. Hypothesis validated or competing hypotheses narrowed

---

## 5. Research Requirements

| Requirement | Why |
|-------------|-----|
| **Save every research output** | `<DOCS_ROOT>/research/R-###-<Title>.md` |
| **Index immediately** | Add to `ResearchIndex.md` in the same commit |
| **Check before creating** | Search ResearchIndex + research/ folder first |
| **Reuse existing** | Link to prior R-### docs instead of re-investigating |
| **R-### IDs** | Sequential, never reused, format: `R-001`, `R-002`, etc. |

**ResearchIndex.md is the source of truth** for what research exists. If it's not indexed, it might as well not exist.

---

## 6. PR/Branch Hygiene Expectations

| Expectation | Rationale |
|-------------|-----------|
| **Minimum PRs** | Fewer PRs = easier for Maintainer to review |
| **Docs PR consolidation** | All docs-only changes go to one PR when possible |
| **No merges without Maintainer** | He's the approver; don't merge without his OK |
| **Branch naming** | `docs/...` for docs-only, `fix/...` for bugs, `feat/...` for features, `x/...` for experiments (never merged — see [x-branch-contract.md](../protocol/x-branch-contract.md)) |
| **One concern per PR** | Don't mix unrelated changes |

---

## 7. Definitions

| Term | Meaning |
|------|---------|
| **RESEARCH-ONLY** | No code changes allowed; read files, run queries, produce Evidence Pack |
| **INSTRUMENTATION (CODE-OK)** | Temporary diagnostic code allowed to gather runtime evidence; must be removed after |
| **FIX** | Implementation mode; confidence ≥95%; code changes allowed |
| **Evidence Pack** | Structured document with Repro Steps, Environment, Hard Evidence, Hypotheses, Confidence |
| **Prior Research Lookup** | Mandatory search of existing research before producing new RESEARCH-ONLY output |
| **forGPT Packet** | The one-folder bundle to upload when starting a ChatGPT session |

---

## Quick Reference

```
Session Start:
1. Sync forGPT packet: .\sync-forgpt.ps1
2. Upload <DOCS_ROOT>/forGPT to ChatGPT
3. Tell ChatGPT: "Read Start-Here-For-AI.md first"

During Work:
- Confidence <95%? → RESEARCH-ONLY + Evidence Pack
- Creating research? → Check ResearchIndex first
- Finishing prompt? → Update PAUSE.md before closing

Session End:
- Commit all changes
- Update PAUSE.md with current state
- Push to branch
```
