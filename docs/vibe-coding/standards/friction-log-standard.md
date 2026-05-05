# Friction Log Standard — v1.0 Pilot

> **File Version:** 2026-04-16
> **Scope:** Kit/process friction only. Repo-specific learning is a separate track (deferred).

---

## Purpose

Capture kit/process friction signals from real sessions so recurring pain points surface for improvement — without adding ceremony to every prompt.

Each consumer repo (and the kit repo itself) maintains a local friction log at `.kit-feedback/FRICTION-LOG.local.md`. This file is a repo-root working artifact, not part of the shared kit content. It should be `.gitignore`d or left untracked.

---

## Storage Path

    .kit-feedback/FRICTION-LOG.local.md

Create the directory and file on first use if they do not exist.

---

## What Counts as Log-Worthy Friction

Log an entry when any of these occurred during the session:

- A rule had to be reread two or more times before its meaning was clear
- Course of action changed after rereading a rule (initial interpretation was wrong)
- Extra research, clarification, or reset was needed because kit guidance was unclear
- A WARN or BLOCKED verdict seemed confusing or disproportionate, forcing extra verification
- Process ambiguity caused a meaningful detour (time spent on process instead of work)

---

## What Does NOT Count

Do **not** log friction for:

- Normal coding retries (compile fix, test fix, selector fix)
- Flaky tests
- Path typos or wrong-file lookups
- Repo-specific discoveries or durable repo lessons
- Generic implementation churn not caused by the kit/process
- Situations where the rule was clear but the task was simply hard

---

## Severity Rule

v1.0 logs **MEDIUM and HIGH only**. Do not log LOW.

| Severity | Meaning |
|----------|---------|
| **MEDIUM** | Noticeable friction — Copilot had to pause, reread, or ask for clarification |
| **HIGH** | Session was meaningfully slowed or a wrong action was nearly taken before the ambiguity was caught |

---

## One-Entry-Per-Session Rule

At most **one** friction entry per session. If multiple qualifying friction events occurred, log the single highest-value signal — the one most likely to improve the kit if fixed.

---

## Entry Schema

Each entry is appended to the end of `.kit-feedback/FRICTION-LOG.local.md`:

    ---
    ## FRICTION-ENTRY
    - **Date:** YYYY-MM-DD
    - **Session PROMPT-ID:** (PROMPT-ID where friction occurred, or UNTRACKED)
    - **Kit Version:** (from VIBE-CODING.VERSION.md)
    - **Consumer Repo:** (repo name)
    - **Friction Type:** AMBIGUOUS | CONTRADICTORY | MISSING | SLOW | BLOCKING | OTHER
    - **Severity:** MEDIUM | HIGH
    - **Location:** (file path + section/line, e.g. protocol/protocol-v7.md § Prompt Review Gate)
    - **Description:** (1–4 sentences: what was unclear or contradictory)
    - **Extra Step or Detour:** (what extra work was caused by the friction)
    - **Suggested Fix:** (how the rule could be clearer or better structured)
    - **Resolved This Session:** YES | NO
    ---

---

## Example Entry

    ---
    ## FRICTION-ENTRY
    - **Date:** 2026-04-16
    - **Session PROMPT-ID:** PWA-EPIC004-S03-IMPLEMENT-001
    - **Kit Version:** v7.3.2
    - **Consumer Repo:** DailyInventoryPWA
    - **Friction Type:** CONTRADICTORY
    - **Severity:** HIGH
    - **Location:** protocol/protocol-v7.md § Doc Audit Sequencing
    - **Description:** The paragraph said "occurs AFTER Proof-of-Read" in one sentence and "run Doc Audit first" in the next. Initial interpretation was per-prompt; session proceeded without session-start audit.
    - **Extra Step or Detour:** Had to stop mid-prompt, re-read session-start-checklist.md, and restart the session-start chain.
    - **Suggested Fix:** Explicitly label Doc Audit as a session-level gate and provide a numbered sequence.
    - **Resolved This Session:** NO
    ---

---

## Deferred / Out of Scope (v1.0)

The following are **not part of the v1.0 pilot** and must not be mixed into the friction log:

- **Repo-specific learning** — durable lessons about a specific codebase belong in a separate track (tentative: `.repo-learning/LESSONS.local.md`). Not implemented yet.
- **Shared external directory** — cross-repo aggregation at a shared path is deferred until the pilot proves useful.
- **Central repo upload** — no central friction repo for the pilot.
- **Scheduled synthesis** — periodic analysis of friction logs is deferred. Manual or on-demand review only.
- **Tool reminder integration** — `end-session.ps1` does not print a friction-log reminder yet. Deferred to a separate prompt.
