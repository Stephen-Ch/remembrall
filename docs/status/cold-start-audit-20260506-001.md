# Cold-Start Audit — Remembrall
**PROMPT-ID:** REMEMBRALL-COLD-START-AUDIT-20260506-001
**Date:** 2026-05-06
**Mode:** RESEARCH-ONLY
**Auditor:** Claude (agentic autonomous session)
**Steps covered:** 1 (cold-start audit) and 2 (installation state assessment)

---

## Repo Truth at Audit Time

| Field | Value |
|---|---|
| Branch | `main` (HEAD file readable; git commands blocked — see Blocker 1) |
| ORIG_HEAD | `2a0c6d5cb8c515381654cf89ee1c136cfe648e11` |
| Kit version (file) | v7.5.15 |
| Kit scripts (actual) | Pre-Phase-6 — git-helpers.ps1 absent, session-start/kit-update do not reference it |
| Implementation code | None — E0 (architecture decisions) in progress |

---

## BLOCKERS

### Blocker 1 — .git/config unreadable from Linux mount (ENVIRONMENT)
The `.git/config` file is visible in directory listings but cannot be read from the Linux/CIFS mount. All git commands fail with `fatal: unknown error occurred while reading the configuration files`. This blocks:
- `git status`, `git log`, `git branch`
- Running any kit PowerShell tool (they invoke git internally)
- Committing, pushing, or running session-start from this environment

**Impact:** Steps 3, 4, 8, 9 of the onboarding plan require Windows/PowerShell execution. Cannot be done from this Claude session directly.

**Kit signal:** This is an environmental constraint, not a kit bug. The kit's tools are PowerShell-native. Agentic Linux-based consumers cannot run them without a bridge.

### Blocker 2 — Kit installation stale (STALE CONSUMER)
VIBE-CODING.VERSION.md reports v7.5.15, but the installed scripts predate Phase 6:
- `git-helpers.ps1` — **ABSENT** (required by current v7.5.15 session-start and kit-update)
- `session-start.ps1` — does not dot-source git-helpers.ps1 (old version)
- `kit-update.ps1` — does not dot-source git-helpers.ps1 (old version)

This means `session-start` would crash on startup when the new scripts try to call functions from the missing git-helpers.ps1. The version file shows 7.5.15 because it was updated, but the payload pull that included git-helpers.ps1 has not been run yet.

**Required action:** Run `kit-update.ps1` from Windows PowerShell before any kit tools are usable.
**Procedure:** Follow `docs/vibe-coding/MIGRATION-INSTRUCTIONS.md` → Stale Consumer Bootstrap Procedure.

---

## Control Deck — SOLID

| Artifact | Status | Notes |
|---|---|---|
| VISION.md | ✅ Present, clear | One-line + full market context |
| EPICS.md | ✅ Present, detailed | E0–E4 with DoD per epic |
| NEXT.md | ✅ Present, current | E0 active, three x-branches planned |
| remembrall-decisions.md | ✅ Present | Stack + branch rules + proof gates |
| README.md | ✅ Present | Accurate status, dev protocol noted |
| PAUSE.md | — Not present | Normal during active work |

---

## Kit Installation State

| Item | Status | Notes |
|---|---|---|
| VIBE-CODING.VERSION.md | ⚠️ v7.5.15 (file) | Content behind — Phase 6 scripts missing |
| git-helpers.ps1 | ❌ ABSENT | Phase 6 deliverable — required by new scripts |
| session-start.ps1 | ⚠️ Old version | Does not reference git-helpers.ps1 |
| kit-update.ps1 | ⚠️ Old version | Does not reference git-helpers.ps1 |
| doc-audit.ps1 | ✅ Present | Not checked for version |
| run-vibe.ps1 | ✅ Present | Not checked for version |
| forGPT packet | ❌ ABSENT | No forGPT directory exists |
| Start-Here-For-AI.md | ❌ ABSENT | Not in kit required-artifacts but useful for onboarding |
| GPT-ROLE.md | ❌ ABSENT | Template exists in kit, not deployed |

---

## Project State — What's Clear

**E0 is in progress with good structure:**
- x/e0-schema-study: **DONE** — findings committed to `docs/status/e0-schema-study-findings.md`
- x/e0-auth-research: **QUEUED** — Auth.js validation, ownership, session handling questions defined
- x/e0-rls-pattern: **QUEUED** — Prisma + Supabase + RLS setup, dbForUser wrapper spec

The schema study findings are solid — v0.2 name mapping documented, original data model captured, clear mapping to rebuild names.

**What's blocking E1:** All three E0 x-branches must complete, then a docs feature branch populates decisions + ARCHITECTURE.md before any implementation code begins. E1 and beyond are correctly gated.

**Stack decisions:** Next.js (App Router) + Prisma + Supabase (RLS) + Auth.js + Vercel + Anthropic API. All pending E0 auth/RLS confirmation — correctly deferred.

**Test infrastructure:** RLS test matrix is defined (10 scenarios) before any code exists. Good practice.

---

## What's Missing / Gaps Surfaced

| Gap | Severity | Notes |
|---|---|---|
| forGPT packet does not exist | HIGH | Step 5 of onboarding plan cannot proceed. No context packet for GPT. |
| GPT-ROLE.md not deployed | MEDIUM | Template exists in kit. Friction for fresh GPT sessions. |
| Start-Here-For-AI.md missing | MEDIUM | Not kit-required but highly useful for cold starts |
| No ARCHITECTURE.md yet | EXPECTED | E0 is not complete — this is correct |
| `x/e0-auth-research` and `x/e0-rls-pattern` not started | EXPECTED | Queued but not started. Both have clear question sets. |

---

## Friction Points (Kit Testing Signal)

1. **Agentic Linux consumer cannot run kit tools.** Kit assumes PowerShell-on-Windows. No bridge exists for Linux-based agents. This is a real gap if the goal is fully autonomous agentic use.

2. **Version file ≠ script version.** VIBE-CODING.VERSION.md shows v7.5.15 but scripts are older. A fresh agent or developer reads the version and assumes the scripts match. They don't. The version file is part of the subtree payload, so it got updated before the Phase 6 scripts were published — creating a window where version and content diverge.

3. **forGPT packet generation requires running sync-forgpt.ps1.** This is a PowerShell tool. An agent arriving cold with no packet and no ability to generate one is stuck at Step 5.

4. **No Start-Here-For-AI.md.** The kit has a template. The repo doesn't use it. A fresh agent's first instinct is to look for a quick-start doc — none exists outside the README.

---

## Stopping Point

This audit covers Steps 1 and 2. Steps 3–4 (fix installation + run session-start) require Windows PowerShell to run kit-update.ps1. Cannot proceed autonomously from this environment without a bridge.

**Recommended next actions (require Stephen or Windows execution):**
1. Run `kit-update.ps1` from Windows PowerShell to pull Phase 6 scripts (git-helpers.ps1)
2. Run `session-start.ps1` to confirm installation is clean
3. Run `sync-forgpt.ps1` to generate the forGPT packet
4. Then Claude can resume at Step 5 (read packet) → Step 6 (scope next x-branch)

---

## OctopusHead Signal

This cold-start found:
- Stale kit install (scripts behind even though version file says current)
- Missing forGPT packet
- Missing GPT-ROLE.md and Start-Here

OctopusHead would benefit from detecting script-level staleness (not just version file), forGPT packet presence, and Start-Here / GPT-ROLE presence. Version file alone is not a reliable freshness signal.
