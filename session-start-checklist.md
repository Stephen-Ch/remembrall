# Session Start Checklist

> **Purpose:** Single-page checklist to reduce "too many places to check" friction.  
> **Usage:** Run through this before starting any work session.  
> **Quick Reference:** See [protocol-lite.md](protocol-lite.md) for core rules summary.

---

## Pre-Flight Checks (< 2 minutes)

- [ ] **RUN START OF SESSION DOCS AUDIT** — This single command audits current repo state only: kit version/drift → packet state → Consumer doc-audit (hard fail) → Staleness Expiry Gate → Decision-Queue Gate → Tool/Auth Fragility Gate → audit print + required actions. Run it first; it verifies and reports without modifying the repo.
- [ ] **Previous clean-close proof** — Review the advisory clean-close proof state surfaced by session-start. It reports whether the previous session's clean close is valid, missing, stale, contradictory, or unverifiable, but it does not replace the live audit.
- [ ] **Consumer-Kit Drift** *(consumer repos only)* — Verify kit subtree is CURRENT (not STALE or DIVERGENT). Surfaced automatically by session-start. Status: PASS | WARN | BLOCKED — see [protocol-v7.md § Consumer-Kit Drift Gate](protocol/protocol-v7.md#consumer-kit-drift-gate-mandatory-at-session-start-in-consumer-repos).
- [ ] **Required action on STALE kit** — If session-start reports kit lag, update the kit explicitly before proceeding. Session-start no longer performs subtree update automatically.
- [ ] **Staleness Expiry** — Verify PAUSE.md handoff state is CURRENT (not STALE or EXPIRED). Surfaced automatically by session-start. Status: PASS | WARN | BLOCKED — see [protocol-v7.md § Staleness Expiry Gate](protocol/protocol-v7.md#staleness-expiry-gate-mandatory-at-session-boundaries).
- [ ] **Decision Queue** — Verify DECISION NEEDED items are well-formed, bounded, and reviewed. Surfaced automatically by session-start. Status: PASS | WARN | BLOCKED — see [protocol-v7.md § Decision-Queue Gate](protocol/protocol-v7.md#decision-queue-gate-mandatory-at-session-boundaries).
- [ ] **Tool/Auth Fragility** — Verify verification toolchain (gh, fetch) is healthy. Surfaced automatically by session-start. Status: PASS | WARN | BLOCKED — see [protocol-v7.md § Tool/Auth Fragility Gate](protocol/protocol-v7.md#toolauth-fragility-gate-mandatory-at-session-boundaries).
- [ ] **Required action on stale/missing packet** — If session-start reports stale, missing, or unverifiable packet state, run packet sync explicitly when you need a current handoff packet. Session-start no longer refreshes the packet automatically.
- [ ] **Goal Anchor** — Write North Star, Current Slice, and Proof before any work.
- [ ] **NEXT.md Status** — Open [NEXT.md](../project/NEXT.md). Confirm Status = ACTIVE or PAUSED with clear Next Step.
- [ ] **NEXT.md Freshness** — Surfaced automatically by Staleness Expiry Gate. Review `NEXT.md` "Immediate Next Steps" against current local and remote repo state before proceeding. Update or remove any items that are already completed, merged, resolved, blocked by changed circumstances, or otherwise obsolete. Status: PASS | WARN | BLOCKED — see [protocol-v7.md § Staleness Expiry Gate](protocol/protocol-v7.md#staleness-expiry-gate-mandatory-at-session-boundaries).
- [ ] **Prior parked-work trigger check (when relevant)** — Before drafting implementation/setup prompts in likely prior-work areas (for example: Playwright, auth, test harness, screenshots/visual evidence, branch cleanup, report UI, x-branch, paused/resumed lanes, or "we already solved this" signals), run the triggered lookup gate in [protocol-v7.md § Core Rules](protocol/protocol-v7.md#core-rules-non-negotiable).
- [ ] **Remote Reality Check** *(after any break)* — Run `git fetch origin`, then `gh pr list --state open --json number,title,headRefName,baseRefName,url`. Confirm NEXT.md and active branches match remote state. Repair mismatches or document as debt before starting work. Status: PASS | WARN | BLOCKED — see [protocol-v7.md § Remote Reality Gate](protocol/protocol-v7.md#remote-reality-gate-mandatory-at-session-boundaries).

### Informational (review if relevant, do not block on these)

- [ ] **Open PRs** — Run `gh pr list --state open` or check GitHub. Note any blocking dependencies.
- [ ] **Blockers** — Check [tech-debt-and-future-work.md](../project/tech-debt-and-future-work.md) for known blockers.

> **Note:** Branch hygiene, research indexing, and orphan-branch cleanup are
> **end-of-session** concerns handled by `run-vibe -Tool end-session`.
> They do not need to block session start.

---

## If Any Check Fails

| Check | Action |
|-------|--------|
| NEXT.md unclear | Update NEXT.md before proceeding |
| PRs blocking | Note in prompt; consider docs-only work |
| Remote Reality: WARN | Repair mismatch or document as debt in NEXT.md/branches.md before starting work |
| Remote Reality: BLOCKED | Note in PAUSE.md; proceed with awareness of unverified remote state |
| Consumer-Kit Drift: WARN (STALE) | Run `run-vibe -Tool kit-update` to update the embedded kit, or document version lag as known debt |
| Consumer-Kit Drift: BLOCKED (DIVERGENT) | STOP. Investigate and revert unauthorized changes inside the kit subtree |
| Staleness Expiry: WARN (STALE) | Review PAUSE.md; confirm or update handoff state and Date; then proceed |
| Staleness Expiry: BLOCKED (EXPIRED) | STOP. Re-verify all handoff state against current reality; rebuild PAUSE.md |
| Decision Queue: WARN | Review Decision Queue section in PAUSE.md; resolve or confirm items; reduce count if possible |
| Decision Queue: BLOCKED | STOP. Malformed items or count >5 or item >30 days old. Fix Decision Queue before proceeding |
| Tool/Auth: WARN | Record which dependencies are degraded. Other gate verdicts already reflect the degradation — no block |
| Tool/Auth: BLOCKED | STOP. A gate verdict claims PASS but its evidence tool was unavailable. Fix toolchain or downgrade the affected verdict |

---

## End of Session

- [ ] **RUN END OF SESSION** — Run `run-vibe -Tool end-session` to execute the **full end-of-session contract** (not just local hygiene). See [protocol-v7.md § End-of-Session Full Contract](protocol/protocol-v7.md#end-of-session-full-contract-canonical-meaning-of-run-end-of-session).
- [ ] **Active Lane** — If tracked changes reported: commit to a branch (preferred) or stash for short-lived interruptions only.
- [ ] **Remote Reality** — Verify fetch + PR state + branch classification. Record status (PASS / WARN / BLOCKED).
- [ ] **Workspace Reality** — Verify worktrees, stashes, unmerged branches, untracked files. Classify all leftovers. Record status (PASS / WARN / BLOCKED). See [protocol-v7.md § Workspace Reality Gate](protocol/protocol-v7.md#workspace-reality-gate-mandatory-at-session-close).
- [ ] **Messy-repo triage (when unsure)** — Follow [protocol-v7.md § Stale/Dirty Triage Path](protocol/protocol-v7.md#staledirty-triage-path) for preserve/classify/cleanup order without skipping safeguards.
- [ ] **Disposition table** — Every leftover non-main item classified: ACTIVE / PR OPEN / PARKED / MERGED / OBSOLETE / DECISION NEEDED / BLOCKED.
- [ ] **CLEAN FIELD READY** — Print `YES` only when Active Lane + Remote Reality + Workspace Reality all qualify. Otherwise `NO` with action items.
- [ ] **Clean-close proof maintenance** — A successful clean close refreshes the repo-local clean-close proof; a non-clean close removes any prior proof so the next session does not inherit stale success evidence.
- [ ] **NEXT.md Freshness** — If session work changed current priorities or closed planned work, update `NEXT.md` before wrap-up so the next session does not inherit stale "Immediate Next Steps."
- [ ] **PAUSE.md** — Record parked leftovers, decision-needed items, and exact next step. Update the Date field to today (Staleness Expiry freshness stamp). Populate the Decision Queue section for every DECISION NEEDED disposition item.
- [ ] **Friction Log** — If qualifying kit/process friction occurred this session, append one MEDIUM/HIGH entry to `.kit-feedback/FRICTION-LOG.local.md` per [friction-log-standard.md](standards/friction-log-standard.md). If none, skip.
- [ ] Optionally: add `-WriteReport` to save a status snapshot under `<DOCS_ROOT>/status/`.

> **"RUN END OF SESSION" means the full contract.** Active-lane green alone is NOT sufficient.
> `CLEAN FIELD READY: YES` requires all three gates (Active Lane, Remote Reality, Workspace Reality) to qualify.
> Any `CLEAN FIELD READY: NO` result is a failed closeout and returns a nonzero exit.
> See [protocol-v7.md § Workspace Reality and Closure Language](protocol/protocol-v7.md#workspace-reality-and-closure-language) for forbidden casual closure phrases.

---

## Quick Links

| Doc | Purpose |
|-----|---------|
| [protocol-lite.md](protocol-lite.md) | Quick reference (start here) |
| [NEXT.md](../project/NEXT.md) | **Active story + next step (live work-state authority)** |
| [protocol-v7.md](protocol/protocol-v7.md) | Full protocol rules |
| [PROTOCOL-INDEX.md](protocol/PROTOCOL-INDEX.md) | Navigate protocol-v7 by task |
| [PAUSE.md](PAUSE.md) | End-of-session handoff (not needed during active work) |
| [critical-transition-checklist.md](critical-transition-checklist.md) | Preflight for critical transitions only (subtree updates, broad staging, handoffs) — **not part of per-prompt flow** |
| [branches.md](../status/branches.md) | Branch/PR tracking |
| [tech-debt-and-future-work.md](../project/tech-debt-and-future-work.md) | Known issues |
