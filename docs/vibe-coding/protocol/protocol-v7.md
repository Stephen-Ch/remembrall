# Protocol v7 — Vibe-Coding Protocol

> **File Version:** 2026-04-28
> **Quick reference:** For mandatory gates only, see [hard-rules.md](hard-rules.md).

**v7.2.1 Changes:**
- Stack-aware gates now read from `stack-profile.md` (no interpretation)
- Added `standards/` folder with research-standard.md and stack-profile-standard.md
- Added `portability/` folder with subtree-playbook.md

## Core Rules (Non-Negotiable)

1. **Prompt Review Gate + Command Lock (MANDATORY FIRST OUTPUT)**: Immediately after PROMPT-ID and BEFORE Proof-of-Read, the AI must output exactly 4 lines:
   - "What:" (1-line summary of what you will do)
   - "Best next step?" YES/NO
   - "Confidence: <percentage>%"
   - "Work state:" READY|IN-PROGRESS|COMPLETE|MERGED|OBSOLETE

   **Confidence scale note:** The percentage uses the same scale as the Tiered Confidence Gate and Evidence Pack (≥95% for docs/research, ≥99% for runtime code — see [Tiered Confidence Gate](#no-guessing--tiered-confidence-gate-mandatory)). If you cannot meet the applicable threshold, STOP and explain.

   **Prompt Review Gate (ROLE CLARITY):** The Prompt Review Gate is performed by **Copilot** (the executor) on the prompt text **before** running any commands. ChatGPT may draft prompts, but Copilot must first output the gate decision (YES/NO, confidence, PROCEED/STOP). If STOP, Copilot must ask the minimum questions or request edits and must not execute anything.

   **STOP conditions:** 
   - If "Best next step? NO" OR Confidence is below the applicable threshold (< 95% docs, < 99% runtime), STOP immediately and explain why.
   - If "Work state:" != READY, STOP immediately (EXCEPTION: merge/closeout prompts require state = COMPLETE).
   - If prompt is unclear, request clarification from operator.
   - If the prompt adds stricter sequencing/format/tool constraints beyond this protocol (e.g., “Proof-of-Read immediately after Gate”, “Stop immediately on any error”, “no fenced code blocks”, “no rg”), and you are not prepared to follow them exactly with the available tools, you MUST set "Best next step? NO" (or lower your Confidence below threshold) and STOP with the smallest prompt correction needed.
   
   **Command Lock:** NO terminal commands, NO file edits, NO searches until the Prompt Review Gate is printed. If you realize you already ran a command before printing the gate, STOP immediately and report exactly what you ran. The Prompt Review Gate must appear before the first command (including git, npm, editors, search, generators, etc.) in EVERY report without exception. Before any git/grep commands, anchor to repo root using: Set-Location (git rev-parse --show-toplevel); git rev-parse --show-toplevel; Get-Location. Never run git pathspec checks from a subfolder.
   
   **Sequencing (Two-tier Command Lock):** Lock A (hard) forbids terminal execution/edits/searches/network/file writes before the 4-line Gate output. After the Gate, repo sanity commands (e.g., `git status`, `git log`) are allowed before Proof-of-Read; Proof-of-Read must appear before any searches or edits.

   **Gate Approval Checklist (required before answering YES):**
   - Read the entire prompt (all sections) and identify any additional constraints (ordering, formatting, stop-on-error behavior, forbidden tools, etc.).
   - Verify feasibility with available tools (e.g., if `rg` isn’t available, plan to use `git grep` or `Select-String` if allowed by the prompt).
   - Verify you can follow the prompt’s exact ordering (e.g., Proof-of-Read immediately after Gate) without mixing in commands or extra output.
   - If any required constraint cannot be met reliably, do NOT approve the prompt.

   **Preflight (MANDATORY in formal prompts):** Every FORMAL WORK PROMPT must include a short Preflight checklist stating:
   - Expected search tool + approved fallbacks (`rg` → `git grep` → PowerShell `Select-String`)
   - Clean tree expectation (required vs allowed dirty)
   - Sequencing allowance: repo sanity allowed after Gate (Lock B)
   - Command batching: allowed by default; if strict ordering is required, batching is disallowed
   - Required output targets (files to write, if any)

**Triggered Prior Parked-Work Lookup Gate (MANDATORY when triggered):**
Before drafting any implementation or setup prompt in an area likely to have prior parked/paused/salvaged work, the planner must run a targeted prior-work lookup first. This gate is triggered only for likely-reuse areas (not every tiny prompt), including: Playwright, auth, test harness, screenshots/visual evidence, branch cleanup, report UI, x-branch planning, paused/resumed lanes, user statements implying "we already solved this," or any lane where `NEXT.md`, `branches.md`, `ResearchIndex.md`, or R-docs may already contain related work.

Required lookup sources when triggered:
- branch ledger (`branches.md`)
- `NEXT.md`
- `ResearchIndex.md`
- relevant `R-###` docs
- open related PR list (when available)

If related parked/prior work exists, implementation planning must STOP. The next prompt must be an audit/reuse prompt unless there is a clear written reason to ignore prior work.

Required output (canonical):
Prior Parked-Work Lookup:
- Matching parked branches found: YES/NO
- Matching prior reports found: YES/NO
- Open related PRs found: YES/NO
- Reuse path: audit first / cherry-pick / replay / ignore with reason

   **Anti-batching for strict sequencing:** If a prompt requires a strict order across multiple commands, run commands one-at-a-time (no batching). Batching is fine for repo sanity unless a prompt explicitly forbids it.

   **Prompt overrides protocol:** Prompts may impose stricter sequencing than this protocol, but must state it explicitly in a single line:
   - STRICT SEQUENCE: Proof-of-Read must occur before ANY commands.
   
   **Work State Definitions:** See [prompt-lifecycle.md](prompt-lifecycle.md) for state definitions and STOP rules.

## Prompt Classes (Request Types)

Two request types are recognized:

**FORMAL WORK PROMPT** (required for execution):
- Required for: ANY terminal commands, file edits, tests/builds, commits, merges
- Format: Single fenced code block with PROMPT-ID + GOAL + SCOPE + TASKS + END PROMPT marker
- Enforcement: MUST include Story ID + NEXT STEP citation from <DOCS_ROOT>/project/NEXT.md (exception: protocol maintenance)
- All gates apply: Prompt Review Gate, Command Lock, Proof-of-Read, Green Gate

**CONVERSATIONAL REQUEST** (discussion/analysis only):
- Allowed for: Discussion, planning, analysis, critique, recommendations, verification audits
- Format: Natural language (no PROMPT-ID required)
- Restrictions: MUST NOT run terminal commands, edit files, or claim Green Gate results. Read-only tools (read_file, grep_search, list_dir, git log/status/diff) allowed.
- If conversational request asks for work execution: respond by drafting a FORMAL WORK PROMPT (with Story ID + NEXT citation) rather than STOP.

## Vibe Skills (Minimal Shorthand Layer)

### Why Vibe Skills exist

- Reduce cognitive load by naming recurring workflows.
- Improve onboarding consistency for new contributors.
- Do not replace protocol authority; this file remains primary.
- Do not bypass gates, thresholds, or required artifacts.

**Design rule:** Vibe Skills are shorthand labels only. They map 1:1 to existing protocol behavior and add no new logic.

Operator responsibility remains goal-first: Stephen/operator states the work goal and constraints.

Operators are not required to select a Vibe Skill by name. The planning assistant may select the appropriate skill based on the requested work. The executing agent must confirm the selected skill fits the task during the Prompt Review Gate before proceeding.

### Skill: vibe-plan

- **Purpose:** Shorthand for start-of-session planning and NEXT-aligned execution setup.
- **When to use:** At session start and before drafting or running an implementation prompt.
- **Required inputs (existing):**
    - Session-start audit result (RUN START OF SESSION DOCS AUDIT)
    - Control Deck files: <DOCS_ROOT>/project/VISION.md, <DOCS_ROOT>/project/EPICS.md, <DOCS_ROOT>/project/NEXT.md
    - Prompt goal/scope under review
- **Required outputs (existing):**
    - Prompt Review Gate + Proof-of-Read + Comprehension Self-Check
    - Explicit NEXT alignment in the prompt (Story ID + Next Step sentence + DoD snippet)
- **Exact mapping to existing rules:**
    - [Core Rules (Prompt Review Gate + Proof-of-Read)](#core-rules-non-negotiable)
    - [Vision & User Story Gate](#vision--user-story-gate-mandatory-for-work-prompts)
    - [Focus Control](#focus-control)

### Skill: vibe-hunt

- **Purpose:** Shorthand for evidence-first bug investigation and root-cause discovery.
- **When to use:** Regressions, unknown failures, or root cause uncertainty before implementation.
- **Required inputs (existing):**
    - Observed failing behavior (repro/log/symptom)
    - Investigation scope and target area
    - Existing artifacts needed for evidence collection
- **Required outputs (existing):**
    - Preflight evidence tied to concrete files/output
    - Evidence Pack captured and indexed as required
    - Explicit stop/pivot when evidence contradicts assumptions
- **Exact mapping to existing rules:**
    - [Preflight Evidence Gate (No Guessing)](#preflight-evidence-gate-no-guessing)
    - [No Guessing / Tiered Confidence Gate](#no-guessing--tiered-confidence-gate-mandatory)
    - [RESEARCH-ONLY Command Lock](#research-only-command-lock-mandatory)
    - [Evidence Pack Requirement](#evidence-pack-requirement-mandatory)
    - [Research Saved + Indexed](#research-saved--indexed-mandatory)
    - [Resilience Rules (STOP / PIVOT)](#d-stop--pivot-rule-when-evidence-contradicts-prompt)

### Skill: vibe-check

- **Purpose:** Shorthand for validation, diff-aware review, proof reporting, and pre-commit confidence checks.
- **When to use:** After edits and before commit/merge/handoff claims.
- **Required inputs (existing):**
    - Current change diff and files touched
    - Required stack-aware validation gates
    - Evidence produced by tests/builds/checks
- **Required outputs (existing):**
    - Green Gate results for required checks
    - Report summary of files changed and proof
    - Confidence statement at the applicable threshold before claiming completion
- **Exact mapping to existing rules:**
    - [Green Gate — Stack-Aware Rules](#green-gate--stack-aware-rules)
    - [Response Structure](#response-structure)
    - [No Guessing / Tiered Confidence Gate](#no-guessing--tiered-confidence-gate-mandatory)
    - [PR / Branch Hygiene Gate](#pr--branch-hygiene-gate-mandatory)

### Triggered Micro-Routine: Research Readiness Sweep

This is a micro-routine to reduce execution friction by preempting near-term research gaps. It is not a research phase, not a backlog builder, and must remain strictly bounded.

- **Trigger-based only (run only when one trigger applies):**
    - Starting a new EPIC
    - Multi-repo planning or coordination
    - Anticipated heavy AI usage (large prompts, research-heavy tasks)
- **Must not run:** This routine MUST NOT be run during normal small-scope or in-progress work.
- **Hard output limits (anti-sprawl):**
    - Identify max 3-5 research gaps
    - Recommend max 1-3 new research docs
    - Each item must map directly to near-term NEXT work
    - If a gap cannot be tied to a concrete NEXT step, it must NOT be included.
- **Canonical output format (exact):**

        Research Readiness Report

        Repo:
        Current direction (1-2 lines):
        Next likely work (3-5 bullets):
        Existing research coverage (brief):
        Gaps (max 3-5):
        Recommended research docs (max 1-3):
        Explicitly NOT researching (anti-scope):

- **Role alignment (low operator burden):**
    - Operator states goal only
    - Planning assistant may trigger the sweep when conditions match
    - Executing agent confirms fit during the Prompt Review Gate
    - Operator is not required to remember or invoke this routine
- **No new systems / no duplication:**
    - Reuse [Research Saved + Indexed](#research-saved--indexed-mandatory)
    - Reuse [research-standard.md ResearchIndex rules](../standards/research-standard.md#researchindexmd-format-canonical-reference)
    - Reuse [No Guessing / Tiered Confidence Gate](#no-guessing--tiered-confidence-gate-mandatory)
    - No new storage locations or artifacts beyond normal research docs

## Vision & User Story Gate (MANDATORY for work prompts)

**Canonical Active Plan:** `<DOCS_ROOT>/project/NEXT.md` is the single source of truth for ACTIVE STORY + NEXT STEP.

Every work prompt MUST include:
1. **Story ID** (from <DOCS_ROOT>/project/NEXT.md)
2. **Next step sentence** (verbatim or near-verbatim from <DOCS_ROOT>/project/NEXT.md)
3. **DoD snippet** (1 sentence Definition of Done)
4. **Copy Source Decision** (TS vs JSON vs content schema vs admin pipeline) when touching user-facing copy
5. **3-Party Approval Gate declaration:** "3-Party Approval Gate: satisfied" OR "in Alignment Mode" (see [alignment-mode.md](alignment-mode.md) → 3-Party Approval Gate (Canonical))

**"Best next step? YES" is ONLY allowed if:**
- The prompt's GOAL matches NEXT STEP for the ACTIVE STORY (<DOCS_ROOT>/project/NEXT.md), AND
- It is a single tiny step with a testable proof (RED→GREEN or docs-only evidence), AND
- Repo safety gates are satisfied (clean tree, tests pass, build passes), AND
- 3-Party Approval Gate is satisfied (see [alignment-mode.md](alignment-mode.md) → 3-Party Approval Gate (Canonical))

**<DOCS_ROOT>/project/NEXT.md Freshness Rule:** "Best next step? YES" is only possible when the ACTIVE NEXT STEP is still current. If you just completed it (work shipped per DoD), the next action is closeout/advance <DOCS_ROOT>/project/NEXT.md, NOT new feature work. Detection: run `git diff --name-only HEAD~1..HEAD`; if `<DOCS_ROOT>/project/NEXT.md` is not in the diff after the NEXT STEP is shipped, STOP and advance NEXT.md before starting new work.

**Population Gate Pre-Flight:** Population Gate is verified during the Start-of-Session Doc Audit (after reading <DOCS_ROOT>/project/VISION.md, <DOCS_ROOT>/project/EPICS.md, and <DOCS_ROOT>/project/NEXT.md), not in the Prompt Review Gate. The Doc Audit MUST have been run in this session and returned Population Gate PASS before any coding work. If Doc Audit has not been run or returned FAIL, STOP and run/remediate it first (see [Start-Here-For-AI.md](../../Start-Here-For-AI.md)).

**Doc Audit Sequencing:** Doc Audit is a **session-level gate**, not a per-prompt gate.

- **Session level (once per session):** Doc Audit runs at session start via `RUN START OF SESSION DOCS AUDIT` (which invokes `tools/session-start.ps1`). The wrapper is audit-only by default: it reports advisory clean-close proof state, kit drift, packet status, Consumer-Kit Drift Gate, Staleness Expiry Gate, Decision-Queue Gate, Tool/Auth Fragility Gate, and doc-audit Population Gate without auto-updating the kit or auto-syncing the packet. If update or packet sync is needed, the operator must run it explicitly after the audit reports the required action. Clean-close proof state is continuity evidence only; current live audit results remain authoritative. Doc Audit MUST have returned PASS in this session before any coding work begins.
- **Per-prompt level:** Doc Audit does NOT re-run before each prompt. The Prompt Review Gate references the session-level Doc Audit result. If Doc Audit was not run this session or returned FAIL, STOP and run/remediate it first.
- **Post-commit rerun trigger:** After each commit, run rerun-trigger detection to determine whether Doc Audit must be rerun (see [required-artifacts.md](../required-artifacts.md) "Doc Audit Rerun Detection" for the git command and path rule).

Ordered sequence within a session:
1. `RUN START OF SESSION DOCS AUDIT` (session-level, once)
2. First prompt: Prompt Review Gate → Proof-of-Read → work
3. After each commit: check rerun trigger → rerun if triggered

**Consumer Start-Here:** Consumer repos should create `<DOCS_ROOT>/Start-Here-For-AI.md` from [templates/start-here-template.md](../templates/start-here-template.md) — a thin-shell consumer file containing only repo-specific paths, overlays, and local notes. Do not copy kit protocol text into it.

**Tech Debt Rule:** Any TECH-DEBT prompt and any new tech-debt row MUST include a Story ID (even if it's a "Maintenance/Protocol" story). Put it in the tech-debt row description as: "Story: <ID> — …".

**Alignment Mode (Start-of-Session):**
If `<DOCS_ROOT>/project/NEXT.md` is missing/unclear/outdated OR **Control Deck Population Gate FAIL** (placeholders detected in <DOCS_ROOT>/project/VISION.md, <DOCS_ROOT>/project/EPICS.md, or <DOCS_ROOT>/project/NEXT.md) → STOP coding and enter Alignment Mode. See [alignment-mode.md](alignment-mode.md) for 3-Party Approval Gate (Canonical), placeholder remediation, and questions to ask Stephen + Copilot before coding. Update `<DOCS_ROOT>/project/*` (VISION/EPICS/NEXT) before any code work.

2. **Proof-of-Read**: Proof-of-Read MUST appear after the Gate and BEFORE any searches or edits (file path + quote of 1-2 complete sentences 10-50 words + "Applying: <rule name>"). Repo sanity commands may run between the Gate and Proof-of-Read.

   **Comprehension Self-Check (Required):** Immediately after Proof-of-Read, the agent MUST answer these 3 questions in its output BEFORE proceeding to any work:
   - Q1: "What exactly will change?" (name specific file(s)/section(s) and intended diff — one line)
   - Q2: "What is explicitly out of scope?" (one line)
   - Q3: "What is the next command + the pass/fail gate?" (exact next command — one line)

   If the agent cannot answer any question with concrete specifics, it must STOP and ask Stephen (or enter RESEARCH-ONLY mode per existing rules). The self-check answers must appear every time Proof-of-Read is required.

3. **Single-Block Prompts**: All operator prompts are one fenced code block ending with `# END PROMPT`.
4. **Green Gate (Stack-Aware)**: See [Green Gate — Stack-Aware Rules](#green-gate--stack-aware-rules) below. At minimum, the primary build must pass before any commit.
5. **Flake Protocol**: If a test fails then passes on rerun without code changes:
   - Mark as "FLAKE SUSPECT" in completion report
   - Create tech debt ticket in same session (add row to tech-debt-and-future-work.md)
   - Include in completion report footer: "Flake suspect? YES/NO"
   - Do NOT ignore — flakes indicate race conditions or cleanup issues
6. **Stop on Error**: On non-zero exit, stop and propose smallest fix (unless the error is classified as "recoverable once" under Resilience Rules (v7 patch)).
6. **Measure Production First**: If a prompt asserts "production has X / doesn't have Y" or any feature is content-dependent, the FIRST step is to identify the production artifact (generated JSON/db/API), record property chains + counts + one example item, and add/confirm a shape-proof + contract test BEFORE changing behavior. Tests must use real production JSON for content-dependent behavior; avoid invented fixtures.
7. **Terminology Lock**: Terminology caused model drift; lock UI copy to a dictionary; never infer data shape from labels.
8. **Guard Rejection Visibility**: Any canActivate/redirect-to-review must emit a single reason code in dev (console or debug overlay); no console spam in prod; deterministic route behavior remains.
9. **Verification Mode**: Read-only audit prompts must not include edits, tests, builds, or merges. See [verification-mode.md](verification-mode.md) for allowed commands, forbidden actions, required output format, and STOP boundaries.
10. **Search + Recovery Reporting**: If a prompt performs codebase searching, the report MUST include:
   - "Search method used: rg | git grep | Select-String"
   - "Recovery applied: <none | retry | fallback>"

## Focus Control

### Goal Anchor (Mandatory per session)

- North Star (1 sentence): what "done" means in human terms
- Current Slice (1 sentence): smallest shippable outcome for today
- Proof (1-3 bullets): observable checks that confirm progress

**Rule:** No cleanup/research/process work may start unless Goal Anchor exists for the session.

#### North Star Source of Truth

- North Star MUST come from the project Control Deck (VISION/EPICS/NEXT or equivalent)
- The AI MUST NOT invent North Star
- If North Star is not found in available docs/context, the AI MUST:
    - Output: "North Star: UNKNOWN (needs Control Deck)"
    - Propose ONE clearly labeled candidate sentence based on evidence
    - Ask Stephen to confirm or replace with a single sentence
    - STOP (do not proceed with implementation planning until confirmed)

### Drift Triggers (Objective STOP conditions)

If ANY trigger occurs, the AI MUST STOP and run Reset Ritual before continuing:
- Two consecutive prompts without advancing a Proof item
- >=20 minutes spent on process/docs/cleanup without shipping progress
- BranchAudit FAIL OR forbidden-prefix branches exist
- User expresses confusion/frustration ("chaos", "this is nuts", "lost faith", etc.)
- Scope expands before finishing Current Slice (new epics/stories/topics mid-slice)

### Reset Ritual (90 seconds)

Steps:
- Restate Goal Anchor
- List top 3 active threads
- Park 2 threads to Future Work (with an explicit outcome + proof)
- Choose 1 next action that advances Proof
- Write the next prompt constrained to that one action only

**Rule:** The next prompt after a reset MUST target only one Proof-advancing action.

### Parking Lot rule (prevents distraction)

When a new concern appears:
- Capture it to Future Work in <2 minutes
- Immediately return to Current Slice

**Rule:** Parking entries must be "outcome + proof", not status.

### Mid-Session Reset (Operator Confusion Recovery)

**Trigger phrase:** `RUN MID-SESSION RESET`

**Purpose:** When the operator loses confidence about the current state mid-session — which branch is active, whether hidden work exists, whether docs match reality — this protocol stops edits and re-establishes ground truth before resuming.

This is NOT end-of-session closeout. This is NOT the Reset Ritual (which re-prioritizes threads). This is a fast reality check for operator confusion.

**When to invoke:**
- "I don't know which branch has the real work"
- "I'm not sure what NEXT.md says vs what I'm actually doing"
- "I'm afraid there's hidden uncommitted work somewhere"
- "My confidence dropped and I should not keep editing blindly"
- "Docs and Git reality seem misaligned"

**Steps (under 2 minutes):**

1. **STOP EDITS** — No more file changes until the reset completes.

2. **Reality Snapshot** — Gather and print:

   | Check | Command / Source |
   |-------|-----------------|
   | Current branch | `git branch --show-current` |
   | Working tree | `git status --short` (dirty / clean) |
   | Stash list | `git stash list` |
   | Open PRs (if available) | `gh pr list --state open` or session-start audit |
   | NEXT.md current step | Read `<DOCS_ROOT>/project/NEXT.md` first actionable line |
   | Work matches NEXT.md? | YES / NO / UNCLEAR |

3. **Classify Confusion** — Pick the primary bucket:

   | Bucket | Meaning |
   |--------|---------|
   | **Branch confusion** | Unsure which branch has real work or which is the active lane |
   | **Scope confusion** | Current edits have drifted from the stated goal / NEXT.md |
   | **Docs/state drift** | NEXT.md, PAUSE.md, or branch ledger no longer reflects reality |
   | **Hidden-work fear** | Suspicion that uncommitted or stashed work exists somewhere |
   | **Confidence too low** | Cannot name the next safe edit with ≥95% confidence |

4. **Research-Only Fallback** — If the confusion bucket is "Confidence too low" OR the reality snapshot reveals unexpected state (dirty tree you cannot explain, branches you don't recognize), enter **RESEARCH-ONLY mode** immediately. Do not resume edits until confidence reaches ≥95%.

5. **State Next Safe Step** — Before resuming edits, write one sentence:
   > "The next safe step is: ___"

   If you cannot write that sentence with confidence, stay in RESEARCH-ONLY.

**Rule:** No edits may resume after a mid-session reset until step 5 is complete.

## Staleness Classification (Session Boundary vs Active Work)

**Purpose:** Prevent false-alarm investigations during active implementation. Not every out-of-date file is a problem. This table defines severity so agents and operators can distinguish expected drift from real breakage.

| File / Artifact | Mid-Session Staleness | Severity | Required Action |
|---|---|---|---|
| **forGPT/ copies** | Expected between sync points | **Normal** | No action. forGPT is a checkpoint snapshot, not a live mirror (see below). |
| **VERSION-MANIFEST.md** | Expected between sync points | **Normal** | No action. Hashes prove what was synced and when; mismatch after edits is routine. |
| **PAUSE.md** (blank/template) | Expected during active work | **Normal** | No action. PAUSE.md is populated at session close only. |
| **branches.md** | Expected after branch operations | **Normal** | No action until end-of-session cleanup. |
| **NEXT.md** not updated after completing step | — | **Actionable** | Update before next prompt. NEXT.md is the live work-state authority. |
| **NEXT.md** age >7 days (time-based) | — | **WARN** | Review Immediate Next Steps before trusting; no automatic block on age alone. |
| **NEXT.md** contradicts current repo state (e.g., completed work still listed as next; required content missing after DoD; outdated instructions tied to active code) | — | **BLOCK** | Do not proceed. Reconcile NEXT.md with actual repo state before any new work. |
| **Manifest mismatches after fresh sync** | — | **Actionable** | Re-run sync; if it fails again, investigate. |
| **Source file missing from manifest** | — | **Bug** | Investigate immediately. |
| **Sync script error** | — | **Bug** | Investigate immediately. |
| **Required file missing after session-start audit** | — | **Bug** | Fix before proceeding. |

**Mid-session NEXT.md review:** Trigger-based, not routine. Re-check "Immediate Next Steps" only after meaningful state change — for example: PR merged, task abandoned, blocker discovered, remote/repo state materially changed, or the current "next" item was completed. Do not add standing mid-session NEXT.md review to per-prompt checklists.

### forGPT Freshness Rule

forGPT is a **point-in-time snapshot** for agent handoff, not a live mirror of canonical docs.

**Sync schedule (when forGPT MUST be current):**
- Session start audit (reported by `session-start.ps1`; run packet sync explicitly if the audit says the packet is stale or missing)
- Session end (run `run-vibe -Tool sync-forgpt` before handoff)
- Explicit agent handoff (GPT ↔ Copilot)
- Major milestone close

**Between sync points, stale forGPT copies are NOT a workflow failure.**
Do not investigate or repair forGPT mid-session unless there is evidence of **actual breakage** — meaning: sync script errors, missing expected files after sync, or manifest/file mismatch immediately after a fresh sync run.

Small timing gaps (edits after last sync) are routine, low-severity drift — not system failures.

## Green Gate — Stack-Aware Rules

**Purpose:** Ensure builds/tests pass before commit, using the correct toolchain for the project type.

**Authority:** Gate decisions MUST come from [`<DOCS_ROOT>/project/stack-profile.md`](../../project/stack-profile.md). Do not interpret or guess — read the declared gates.

**Standard:** See [stack-profile-standard.md](../standards/stack-profile-standard.md) for how to create/update stack profiles.

### A) Read Stack Profile First

Before running any gate commands:
1. Open `<DOCS_ROOT>/project/stack-profile.md`
2. Find the "Gate Configuration" section
3. Run ONLY the gates marked "Required: YES" for the change type

**No interpretation:** If stack-profile says "JS Build: N/A", do not run npm build even if package.json exists.

### B) .NET Gate (as declared in stack-profile)

**Build (REQUIRED per stack-profile):**

    msbuild <YourProject>.csproj /p:Configuration=Release

**Unit Tests (if test project exists):**
- Check: `Test-Path **/<YourProject>.Tests.csproj` or similar
- When tests exist: Run via VS Test Explorer or `vstest.console.exe`

**Tech Debt:** CLI test runner not standardized yet. See [tech-debt-and-future-work.md](../../project/tech-debt-and-future-work.md).

### C) JS Gate (React, Angular, Node.js Apps)

**Applicability Rule:** JS Gate applies ONLY when ALL of:
1. The PR touches files under a directory containing `package.json`, AND
2. That `package.json` has both `scripts.build` AND `scripts.test` defined, AND
3. The stack-profile declares JS gates as required (not just "test harness")

**Rule:** Check `stack-profile.md` — if it says "JS Build: N/A", do not run npm build.

**Pre-check (if stack-profile unclear):** Read `package.json` and verify purpose + scripts:

    Get-Content package.json | ConvertFrom-Json | Select-Object -ExpandProperty scripts

**If stack-profile declares JS gates required:**

    npm run build
    npm run test

**If stack-profile declares JS gates N/A:** Document in report: "JS Gate: N/A (per stack-profile)"

### D) Docs-Only Gate

For docs-only changes (`.md` files only):
- No build required
- Population Gate (no TBD/TODO/PLACEHOLDER) MUST pass
- Spell-check encouraged but not blocking

### E) Gate Summary (Read from stack-profile.md)

Refer to [`<DOCS_ROOT>/project/stack-profile.md`](../../project/stack-profile.md) for the authoritative gate configuration.

**Example Summary (per stack-profile):**

| Gate | Command | Required |
|------|---------|----------|
| .NET Build | `msbuild <YourProject>.csproj /p:Configuration=Release` | ✅ YES |
| .NET Tests | (none configured) | N/A |
| JS Build | (per stack-profile) | N/A |
| E2E | (per stack-profile) | Optional |

---

## Resilience Rules (v7 patch)

These rules reduce false STOPs caused by tooling and environment variability, while preserving strict safety around edits, scope, and canonical docs.

### A) Two-tier Command Lock

- **Lock A (Hard):** No edits, searches, network access, or file writes before the 4-line Gate. Violating Lock A is always STOP.
- **Lock B (Soft):** After the Gate, repo sanity commands are allowed before Proof-of-Read. Violating Lock B is recoverable only if no edits occurred and Recovery Policy (below) is followed.

### B) Search tool fallbacks

Required search order for codebase search:
1) `rg` (if installed)
2) `git grep`
3) PowerShell `Select-String`

Tool absence (e.g., “rg not found”) is NOT an error if you switch to the next approved fallback and record it in the report (“Search method used: …”).

### C) Recoverable error policy

**Recoverable once** (choose ONE recovery path):
- command not found (tooling)
- interrupted command (`^C`)
- transient path mismatch
- missing optional file
- empty search results

**Recovery rule:** Retry once OR switch to the approved fallback once. If it still fails, STOP and give minimal unblock instructions.

**Non-recoverable (always STOP):**
- edits made before the Gate
- failing tests/builds during code prompts (unless the prompt explicitly instructs fixing)
- scope violations
- missing required canonical docs (e.g., `<DOCS_ROOT>/project/NEXT.md`, required handoff/protocol files)

### D) STOP / PIVOT Rule (When Evidence Contradicts Prompt)

When the agent discovers that the repo state differs from what the prompt assumed, it must follow one of two paths before making any edits.

**PIVOT REPORT** (when a better alternative exists):

    PIVOT REPORT
    Expected (from prompt): <what prompt assumed>
    Found (evidence): <what actually exists, with file:line>
    Proposed pivot: <safer alternative>
    Risk assessment: <why pivot is better>

Proceed with pivot only if: identical behavior, equal or narrower scope, and the existing hook is stable. Otherwise STOP and ask the operator.

**Contradiction STOP** (when evidence contradicts the prompt):

    STOP: PROMPT CONTRADICTED BY EVIDENCE
    Prompt assumption: <what prompt said>
    Evidence: <what file:line actually shows>
    Request: Clarify scope or update prompt

**Confidence integration:**
- ≥95% (docs/research) / ≥99% (runtime): evidence captured and consistent with plan.
- Below threshold: evidence incomplete — STOP or enter RESEARCH-ONLY mode.
- Evidence contradicts prompt: STOP immediately (see Contradiction STOP above).

## Docs PR Consolidation Rule

**Purpose:** Minimize open PRs and reduce review burden by consolidating docs changes.

### Rule

1. **Extend existing docs PR:** If a docs portability/standards PR already exists on the current branch (e.g., PR #38), add commits to it rather than opening a new PR.

2. **Separate runtime from docs:** Keep runtime code changes in their own PRs. Do not mix runtime fixes with docs-only changes.

3. **When to open a new docs PR:**
   - No existing docs PR is open on the branch
   - The change is unrelated to the existing PR's scope
   - The existing PR is blocked/stale and a fresh start is needed

### Rationale

Multiple small docs PRs create:
- Review fatigue for approvers
- Merge conflicts between docs branches
- Difficulty tracking what's "current"

One consolidated docs PR with clear commits is easier to review and merge.

## Preflight Evidence Gate (No Guessing)

This section prevents structural assumptions that lead to incorrect edits or scope creep.

### A) Structural Assumption Ban

No assumptions about:
- Existing IDs or classes (verify in-file before using as selectors)
- Which stylesheet is loaded on a page (verify layout file references)
- Selector scope or specificity (verify no conflicts in target stylesheet)
- File locations or paths (verify existence before referencing)
- HTML wrapping or container structure (verify actual markup)

**Rule:** If not verified in-file, STOP. Do not guess or assume from memory or naming conventions.

### B) Preflight Evidence Requirement

Before making changes that depend on structure, capture evidence by quoting line ranges (or short excerpt) that proves:

1. **Hook existence:** The wrapper ID/class exists in the view OR is confirmed absent (if adding new)
2. **CSS location:** The CSS rule is currently present (and where exactly)
3. **Stylesheet loading:** The target external stylesheet is actually loaded on the page (verify in layout file)

**Evidence format in report:**

    PREFLIGHT EVIDENCE
    Hook: id="teach" exists at Views/Teach/Index.cshtml:30
    Current CSS: li.disabled at Views/Teach/Index.cshtml:15-20 (inline <style>)
    Target stylesheet: Content/css/style.css loaded via _Layout.cshtml:45

### C) Two-Phase Default

If the change touches CSS scope/structure, default to a two-phase approach:

1. **Research-only prompt first:** Inventory + evidence + proposed change (no edits)
2. **Implementation prompt second:** Execute with verified evidence

**Single-step exception:** Implementation is allowed in one prompt only when:
- Evidence is trivial (e.g., existing ID clearly visible in attached context)
- Evidence is explicitly included in the prompt output before edits

### D) Confidence Gate Update

- **≥95%:** Evidence captured and consistent with plan (docs/research scope)
- **≥99%:** Evidence captured, reproduced, and side-effects ruled out (runtime/code scope)
- **Below threshold:** Evidence incomplete or contradicts plan — STOP and gather evidence first

**Rule:** If Confidence is below the applicable threshold due to missing structural evidence, STOP and gather evidence first.

**Note:** This is the same percentage scale used in the Prompt Review Gate and Evidence Pack Confidence Statement.

---

## No Guessing / Tiered Confidence Gate (MANDATORY)

**Purpose:** Prevent speculative changes that cause churn, regressions, and wasted effort.

### A) Tiered Confidence Rule

Confidence thresholds vary by scope. Higher-risk scopes require higher confidence.

| Scope | Threshold | Action if below |
|-------|-----------|------------------|
| Low-risk (docs, tests, reports) | ≥95% | May proceed |
| Production/runtime code | ≥99% | May proceed |
| Any scope below threshold | — | STOP — enter RESEARCH-ONLY mode |

**Clarification:** "Best next step?" and "Confidence" in the Prompt Review Gate are **Copilot's** (executor's) gate questions, not planner statements. Copilot evaluates confidence as a percentage using the same scale as the Evidence Pack Confidence Statement.

**What "95% confidence" means (low-risk):**
- You have verified evidence for every structural assumption
- You know the exact files, line ranges, and dependencies affected
- You can predict the outcome of your change with near-certainty

**What "99% confidence" means (production/runtime):**
- All of the above, PLUS:
- You have reproduced the issue or behavior under investigation
- You have confirmed no side effects on adjacent features
- You have identified or written tests that cover the change

**Primary Priorities:** See [working-agreement-v1.md → Primary Priorities (Non-Negotiable)](working-agreement-v1.md#primary-priorities-non-negotiable) for prompt-only mode, one-prompt rule, tiny-step TDD default, and Stephen cognitive style. These govern all GPT interactions.

### B) Dual-Agent Research Requirement

When confidence is below the applicable threshold, **both AI agents** (ChatGPT and Copilot) MUST request more research before proceeding:

- **ChatGPT (Planner):** MUST NOT produce implementation prompts when confidence is below threshold. Instead, produce a RESEARCH-ONLY prompt.
- **Copilot (Executor):** MUST NOT execute code changes when confidence is below threshold. Instead, STOP and request evidence gathering.

**Handshake phrase:** "Confidence <95% — entering RESEARCH-ONLY mode" (or "<99%" for production scope)

### C) No Guessing Enforcement

**NEVER guess about:**
- Root cause of bugs without reproduction
- File locations or code structure without verification
- Database state without query evidence
- Runtime behavior without instrumentation or logs
- Configuration precedence without documented proof

**If you don't know, SAY SO.** Then gather evidence.

---

## RESEARCH-ONLY Command Lock (MANDATORY)

**Purpose:** Ensure research phases produce evidence, not side effects.

### A) When RESEARCH-ONLY Applies

RESEARCH-ONLY mode is triggered when:
1. Confidence is <95%
2. Prompt explicitly declares `Scope: RESEARCH-ONLY`
3. Investigating a bug without reproduction evidence
4. Analyzing behavior without instrumentation data

### B) RESEARCH-ONLY Allowed Actions

| Action | Allowed |
|--------|---------|
| `read_file`, `grep_search`, `list_dir` | ✅ YES |
| `git log`, `git diff`, `git status` | ✅ YES |
| `git show` (read commits/branches) | ✅ YES |
| Database SELECT queries (read-only) | ✅ YES |
| `gh pr list`, `gh pr view` (read) | ✅ YES |
| Creating markdown docs in `research/` | ✅ YES |

### C) Prior Research Lookup (MANDATORY)

**Rule:** Every RESEARCH-ONLY output MUST include a "Prior Research Lookup" section. The lookup MUST happen BEFORE any new investigation begins.

**Step 1 — Run the tool:**
```powershell
.\tools\check-prior-research.ps1 -Terms "<term1>","<term2>"
```
This searches `<DOCS_ROOT>/research/ResearchIndex.md` and all `R-###-*.md` files. If the tool is unavailable (e.g., in ChatGPT), use manual grep:
```powershell
Select-String -Path "<DOCS_ROOT>/research/*.md" -Pattern "<term>"
```

**Step 2 — Read matches:** If the tool returns matches, READ the referenced documents before proceeding. Do not start new research if the answer already exists.

**Step 3 — Document the lookup in your output:**

1. **States the exact search commands used** (tool invocation or manual grep)
2. **Lists any matching document IDs found:**
   - R-### (Research docs)
   - REPORT-### (Analysis reports)
   - POLICY-### (Policy docs)
   - Which documents were actually read
3. **OR explicitly states:** "No relevant prior research found" (only after searching ResearchIndex.md + research/ folder)

**If this section is missing, the RESEARCH-ONLY output is INVALID.** Stop and add the lookup before drawing conclusions.

**Why this matters:** Prevents duplicate research, ensures knowledge accumulation, and catches cases where the answer already exists.

### D) RESEARCH-ONLY Forbidden Actions

| Action | Forbidden |
|--------|-----------|
| Editing runtime code (`.cs`, `.vb`, `.cshtml`, `.js`, `.ts`) | ❌ NO |
| Creating branches for code changes | ❌ NO |
| Opening PRs with code changes | ❌ NO |
| Running builds or tests that modify state | ❌ NO |
| Database INSERT/UPDATE/DELETE | ❌ NO |
| Adding instrumentation/logging to runtime code | ❌ NO |

### E) Exiting RESEARCH-ONLY

To exit RESEARCH-ONLY mode:
1. Complete an Evidence Pack (see below)
2. Confidence MUST reach ≥95%
3. Explicitly declare: "RESEARCH-ONLY complete — confidence now ≥95%"

### F) External Research Escalation

When blocked by external facts and Copilot has no web access, follow [working-agreement-v1.md § External Research Escalation](working-agreement-v1.md).

---

## INSTRUMENTATION (CODE-OK) Scope (MANDATORY)

**Purpose:** Allow temporary diagnostic code when research requires it, with strict guardrails.

### A) When INSTRUMENTATION Applies

INSTRUMENTATION mode is triggered ONLY when:
1. RESEARCH-ONLY is insufficient (cannot gather evidence without runtime observation)
2. Prompt explicitly switches mode: "Switching from RESEARCH-ONLY → INSTRUMENTATION (CODE-OK)"
3. Stephen approves the instrumentation scope

### B) INSTRUMENTATION Allowed Actions

| Action | Allowed |
|--------|---------|
| Adding `Console.WriteLine` / `Debug.WriteLine` for diagnostics | ✅ YES |
| Adding temporary logging to capture state | ✅ YES |
| Adding `// INSTRUMENTATION:` comments marking temporary code | ✅ YES |
| Creating a dedicated instrumentation branch | ✅ YES |

### C) INSTRUMENTATION Guardrails

1. **Labeling:** All instrumentation code MUST include comment: `// INSTRUMENTATION: <ticket-id> — REMOVE AFTER DIAGNOSIS`
2. **Scope limit:** Maximum 20 lines of instrumentation per file
3. **No persistence:** Instrumentation code MUST NOT be merged to develop/main
4. **Follow-up task:** Every INSTRUMENTATION session MUST create a TD-### task: "Remove instrumentation from <files>"
5. **Evidence capture:** Instrumentation output MUST be captured in the Evidence Pack

### D) INSTRUMENTATION vs RESEARCH-ONLY Distinction

| Mode | Code Changes | Evidence Output |
|------|--------------|-----------------|
| RESEARCH-ONLY | ❌ None | R-### doc with search/query evidence |
| INSTRUMENTATION (CODE-OK) | ✅ Temporary diagnostics only | R-### doc with runtime output evidence |

**Rule:** Never mislabel INSTRUMENTATION work as RESEARCH-ONLY. If you're adding code, you're in INSTRUMENTATION mode.

---

## Evidence Pack Requirement (MANDATORY)

**Purpose:** Ensure every diagnosis has reproducible proof, not speculation.

### A) Required Evidence Pack Sections

Every research effort MUST produce an Evidence Pack containing:

| Section | Content |
|---------|---------|
| **Repro Steps** | Numbered steps to reproduce the issue |
| **Environment Fingerprint** | OS, .NET version, IIS Express/IIS, browser, date/time |
| **DLL Hashes/Timestamps** | `Get-FileHash` and `Get-Item` on relevant binaries |
| **Connection Targets** | Actual database servers/databases being hit |
| **Observed Error** | Exact error message, stack trace, or unexpected behavior |
| **DB Proof** | Query results demonstrating database state |
| **Diff Proof** | `git diff` showing code differences between working/broken |
| **Decision** | What the evidence proves and recommended action |

### B) Evidence Pack Template


See [standards/evidence-pack-template.md](../standards/evidence-pack-template.md) for a complete template with field-by-field guidance.

### C) Confidence Statement

Every Evidence Pack MUST end with a Confidence Statement:

    ### Confidence Statement
    Confidence: <percentage>%
    Basis: <1-2 sentences explaining why this confidence level>
    Ready to proceed: YES / NO (if <95%, NO)

---

## Research Saved + Indexed (MANDATORY)

**Purpose:** Ensure all research is discoverable and not lost.

### A) Every Research Effort Produces R-###

**Rule:** Every research session MUST create a research document:
- Location: `<DOCS_ROOT>/research/R-###-<Title>.md`
- Naming: Sequential 3-digit number (e.g., R-016, R-017)
- Content: Evidence Pack + Confidence Statement

### B) ResearchIndex.md Update Required

**Rule:** Every new R-### document MUST be added to `<DOCS_ROOT>/research/ResearchIndex.md` in the same commit.

Index entry MUST use the structured format defined in
[research-standard.md](../standards/research-standard.md#researchindexmd-format-canonical-reference)
and include:
- Report ID
- Date
- PROMPT-ID (if applicable)
- Area
- Status + Confidence
- **Keywords** (3–8, lowercase, comma-separated — critical for search)
- Summary (1 sentence)
- File path

### C) No Orphan Research

**Anti-pattern:** Research findings mentioned only in chat, not saved to docs.

**Rule:** If you gathered evidence, it MUST be saved. "I checked and found X" without an R-### is incomplete research.

---

## PR / Branch Hygiene Gate (MANDATORY)

**Purpose:** Prevent work loss from orphaned branches and stale PRs.

### A) No New Sprint Work with Orphaned Branches

**Rule:** Before starting new sprint work, verify no unmerged runtime branches exist without a PR.

Check command:
    git branch -a --no-merged origin/develop | Select-String -NotMatch "docs/"

If runtime branches exist without PRs: STOP and either open PRs or document why they're parked.

### B) Open PR Ledger

**Rule:** Maintain awareness of open PRs. At session start, run:
    gh pr list --state open --json number,title,headRefName

If PRs are aging (>2 days without merge), flag for review.

### C) Docs-Only PRs

Docs-only PRs (no runtime code) MAY be merged with less scrutiny, but MUST still be tracked and not abandoned.

### D) Runtime-Weighted Merge Review

**Runtime file definition:** controllers, services/helpers, models/entities,
repositories, migrations, middleware, routing, and API handlers. Docs-only
files (markdown, config comments, test fixtures) do not count toward this threshold.

**Merge block — any Yes answer from the completion report self-state check
(see [copilot-instructions-v7.md § Backend/Runtime Completion Reports](copilot-instructions-v7.md#backendruntime-completion-reports--additional-required-fields))
blocks merge until the concern is resolved or explicitly accepted by Stephen.**

**Hostile Self-Audit (mandatory) — triggered by EITHER condition:**

1. **Volume trigger:** PR changes 9 or more runtime files.

2. **Cross-layer trigger:** PR changes a cross-layer runtime slice, defined as
   any combination that spans request-handling + business-logic + persistence:
   - controller + helper/service + entity/model
   - controller + helper/service + database/migration
   - controller + model/entity + repository/query/persistence
   - or equivalent: any two of {controller, service, model} plus the third
     OR any of those three plus a migration or query file

When triggered, before requesting merge the executor MUST:

    1. Re-read every changed runtime file top-to-bottom.
    2. For each file, answer: "Does this change introduce an assumption
       the rest of the runtime path does not yet satisfy?"
    3. Report findings in the completion report under:
       Hostile Self-Audit: PASS (no cross-layer assumptions violated)
       — or —
       Hostile Self-Audit: FAIL — <one-line description per concern>
    4. If FAIL: treat as merge-blocked until concern is resolved.

---

## Remote Reality Gate (MANDATORY at Session Boundaries)

**Purpose:** Verify that session close and session open are grounded in remote/GitHub truth, not only local git state. Local cleanliness is necessary but not sufficient.

### Definitions

**Active runtime branch:** Any local or remote branch that is not merged into the repo's default branch on GitHub AND has at least one of: an open PR, commits ahead of the default branch, or explicit ACTIVE/PAUSED classification in NEXT.md or branches.md.

**Remote Reality Status (3-status model):**

| Status | Meaning |
|--------|---------|
| **PASS** | Fetch succeeded; all active branches classified; NEXT.md and branches.md match current remote/PR state |
| **WARN** | Mismatch found (stale NEXT.md, unclassified branch, PR on wrong base, branch ahead of origin) but repairable now; repair or document as debt before declaring session close |
| **BLOCKED** | Remote verification could not complete (gh unavailable, network/auth failure, or `-SkipFetch` used); record "Remote Reality: BLOCKED — [reason]" in PAUSE.md |

### A) Session Close — Required Evidence

Before declaring "ready to pause," "done," or handing off, produce evidence or a BLOCKED declaration covering:

    1. git fetch --all --prune                                                     → OK / FAILED / BLOCKED
    2. git status --porcelain=v1 -uall                                            → CLEAN / DIRTY
    3. git branch -vv                                                              → branch + upstream + ahead/behind
    4. git rev-list --left-right --count origin/<default>...HEAD                  → behind N / ahead N
    5. gh pr list --state open --json number,title,headRefName,baseRefName,url    → table or "none"
    6. Active branch classification (see §B)                                      → one status per branch
    7. NEXT.md vs remote: does active story describe uncommitted work?            → CURRENT / STALE

        Remote Reality: PASS | WARN | BLOCKED

The `run-vibe -Tool end-session` script surfaces items 1–5 automatically when `gh` is available.

### B) Active Branch Classification (Required per Branch at Session Close)

For every branch returned by `git branch --no-merged origin/<default>`, record one classification:

- **ACTIVE** — work in progress on this branch (no PR yet)
- **PR OPEN** — open pull request exists for this branch
- **PARKED** — no open PR; intentionally paused; document last commit date in branches.md
- **MERGED** — already merged remotely; local branch pending deletion
- **OBSOLETE** — no PR, no recent activity; ready to delete

Unclassified branches = automatic **WARN** condition.

### C) Session Start — Remote Reality Check (After Break)

After resuming from PAUSE.md, before starting new work:

    1. git fetch origin
    2. NEXT.md currency: is ACTIVE STORY branch still open (not yet merged)?
       → gh pr list --state open --json number,title,headRefName | filter for active branch
    3. branches.md currency: do listed branches match remote state?

    Status: PASS | WARN (repair or document as debt) | BLOCKED (gh unavailable — note in PAUSE.md)

### D) Acceptable and Unacceptable Closure Language

**Acceptable** (with Remote Reality evidence cited):
- "Remote Reality: PASS. NEXT.md current. Open PRs: [list]. Branch [name]: behind 0 / ahead 0."
- "Remote Reality: WARN. Branch [name] ahead 2 of origin/<default> — pushed before close."
- "Remote Reality: BLOCKED — gh auth unavailable. Local state clean. Noted in PAUSE.md."

**Not acceptable** without Remote Reality evidence:
- "Repo is clean." — local-only claim; does not establish remote truth
- "We're in good shape." — no evidence cited
- "Ready to continue next session." — no NEXT.md or PR check documented
- "Safe to pause." — no remote fetch evidence

---

## Workspace Reality Gate (MANDATORY at Session Close)

**Purpose:** Verify that the full local workspace is accounted for before declaring session close. Active-lane green does NOT mean the workspace is clean. Tracked-file cleanliness does NOT mean safe-to-pause.

### Definitions

**Active Lane reality:** The current branch has no uncommitted tracked changes, tests pass (if applicable), and the branch is up to date with its upstream. This is necessary but NOT sufficient for session close.

**Remote Reality:** The remote/GitHub state matches local expectations (fetch succeeded, PRs classified, NEXT.md current). Governed by [Remote Reality Gate](#remote-reality-gate-mandatory-at-session-boundaries).

**Workspace Reality:** The full local workspace — all branches, worktrees, stashes, untracked files, and leftover items — is accounted for and classified. This gate exists because active-lane green can mask significant workspace debt.

**Clean Field:** All three realities (Active Lane + Remote Reality + Workspace Reality) qualify. Only then may `CLEAN FIELD READY: YES` be declared.

### Workspace Reality Status (3-status model)

| Status | Meaning |
|--------|---------|
| **PASS** | All evidence categories checked; all leftover items classified; counts within default caps |
| **WARN** | Leftover items exist but are classified and within caps; at least one requires attention before next session |
| **BLOCKED** | Caps exceeded, unclassified items remain, or evidence could not be gathered |

### Required Evidence Categories

At session close, produce evidence covering all of the following:

    1. git status --porcelain=v1 -uall          → dirty + untracked file count
    2. git branch -vv                            → all local branches + upstream + ahead/behind
    3. git branch --no-merged origin/<default>   → unmerged branch count
    4. git worktree list                         → worktree count (1 = normal; >1 = extra)
    5. git stash list                            → stash count
    6. gh pr list --state open --json number,title,headRefName,baseRefName,url → open PR count + PR IDs

Every leftover non-main item (branch, worktree, stash, untracked cluster) MUST appear in a disposition table.

### Required Disposition Model

Every leftover non-main item must be classified using one of:

| Disposition | Meaning |
|-------------|---------|
| **ACTIVE** | Work in progress; has a clear next step |
| **PR OPEN** | Open pull request exists for this item |
| **PARKED** | Intentionally paused; documented in PAUSE.md or branches.md |
| **MERGED** | Already merged remotely; local artifact pending cleanup |
| **OBSOLETE** | No PR, no recent activity; safe to delete |
| **DECISION NEEDED** | Ambiguous; requires operator judgment before next session |
| **BLOCKED** | Depends on external factor (approval, upstream, etc.) |

Unclassified items = automatic **BLOCKED** condition for the gate.

### Default Caps (Kit Portable Defaults)

These are conservative defaults. Consumer repos may override via overlay.

| Category | Default Cap | Exceeding Cap → |
|----------|-------------|-----------------|
| Active implementation lanes | ≤ 2 | WARN (≤ 3) / BLOCKED (> 3) |
| Local-only unmerged branches (no PR, no ACTIVE/PARKED classification) | ≤ 3 | WARN (≤ 5) / BLOCKED (> 5) |
| Extra worktrees (beyond primary) | ≤ 1 | WARN (= 2) / BLOCKED (> 2) |
| Stash entries | ≤ 2 | WARN (≤ 4) / BLOCKED (> 4) |
| DECISION NEEDED items in queue | ≤ 3 | WARN (≤ 5) / BLOCKED (> 5) |

### Safe Cleanup Policy

At session close, the end-session tool or operator may clean up items that are **high-confidence junk only**:

**Safe to auto-clean (report-first, opt-in):**
- Local branches already merged into default and deleted on remote
- Worktrees pointing to branches that no longer exist

**Never auto-delete:**
- Stashes (always require operator review)
- Branches with unmerged commits
- Branches classified DECISION NEEDED
- Anything requiring operator judgment

**Default behavior:** Report candidates only. No deletion without explicit opt-in.

### WIP Storage Preference

Branches are the preferred WIP storage mechanism. Use stash only for short-lived interruption handling (minutes to hours). Multi-day or unique WIP belongs on a named branch with at least one commit.

**Rationale:** Stashes lack names, descriptions, and upstream tracking. Branches are visible to the disposition model, classification, and Remote Reality Gate. Stashed work is invisible to all session-boundary gates except the count cap.

### Workspace Reality and Closure Language

The following closure language is **FORBIDDEN** unless the full contract (Active Lane + Remote Reality + Workspace Reality) qualifies:

- "END OF SESSION: Clean"
- "Repo is clean"
- "All good"
- "Safe to pause"
- "Ready to continue"

**The ONLY acceptable clean-field declaration is:**

    CLEAN FIELD READY: YES

This requires ALL of:
- Active Lane: no uncommitted tracked changes
- Remote Reality: PASS (or BLOCKED with explicit note in PAUSE.md)
- Workspace Reality: PASS

If any gate is WARN or BLOCKED:

    CLEAN FIELD READY: NO
    Active Lane: <status>
    Remote Reality: <PASS | WARN | BLOCKED>
    Workspace Reality: <PASS | WARN | BLOCKED>
    Action items: <list>

---

## End-of-Session Full Contract (Canonical Meaning of "RUN END OF SESSION")

**Purpose:** Define what "RUN END OF SESSION" means so it can never be reduced to "tracked files are clean."

### Canonical Definition

"RUN END OF SESSION" means executing the full end-of-session contract, which includes ALL of:

**Tool-automated (surfaced by `tools/end-session.ps1`):**

1. **Normal end-session flow** — run `tools/end-session.ps1` (or `run-vibe -Tool end-session`)
2. **Remote Reality Gate** — fetch, classify branches, verify PR state
3. **Workspace Reality Gate** — worktrees, stashes, untracked files, dirty file count, non-merged branch count
4. **Final clean-field verdict** — `CLEAN FIELD READY: YES` or `NO` with evidence
5. **Clean-close proof maintenance** — write the repo-local clean-close proof only when `CLEAN FIELD READY: YES`, and remove any prior proof on `CLEAN FIELD READY: NO`

**Operator obligations (not automated by the tool):**

5. **Disposition table** — classify every leftover non-main item (branch, worktree, stash) using the disposition model above
6. **Safe auto-cleanup** — review cleanup candidates reported by the tool; delete only high-confidence junk with explicit opt-in
7. **Record parked leftovers** — document any PARKED or DECISION NEEDED items in PAUSE.md
8. **Write exact next step** — update PAUSE.md with concrete resumption instructions
9. **Verify PAUSE.md** — confirm the handoff state is complete before closing the session
10. **NEXT.md freshness** — if session work changed current priorities or closed planned work, update `NEXT.md` before wrap-up so the next session does not inherit stale "Immediate Next Steps"

The tool surfaces evidence and verdicts; the operator is responsible for classification, cleanup decisions, NEXT.md freshness, and PAUSE.md updates.

### Category Error Prevention

The following category error MUST NOT occur:

    ❌ Active lane looks green → declare "END OF SESSION: Clean"
    ❌ Local tracked files are clean → declare "safe to pause"
    ❌ No git status changes → skip Workspace Reality check

**Correct reasoning:**

    ✅ Active lane clean? (necessary but not sufficient)
    ✅ Remote Reality: PASS | WARN | BLOCKED? (separate check)
    ✅ Workspace Reality: PASS | WARN | BLOCKED? (separate check)
    ✅ All three qualify? → CLEAN FIELD READY: YES
    ✅ Any gap? → CLEAN FIELD READY: NO + action items

### Cleanup Closure Rule

Cleanup is part of done. Deferred cleanup ("I'll clean it up next session") is not a valid closeout strategy. Any workspace residue must be classified, resolved, or explicitly parked with an owner and date before session close.

### Stale/Dirty Triage Path

**Purpose:** Give operators one low-stress, code-protective order of operations when opening or closing a messy repo.

1. **Start with session-start audit first** (`RUN START OF SESSION DOCS AUDIT`). If any gate is BLOCKED, follow required actions before edits.
2. **If the repo is dirty, classify before acting:** active WIP, stale WIP, or ambiguous residue.
3. **Preserve code first (safety default):**
    - Multi-day or unique WIP → commit to a named branch.
    - Stash only for short-lived interruption handling.
    - If unsure, preserve on a branch and classify as `DECISION NEEDED`.
4. **Re-verify freshness before trusting state:** apply [Staleness Expiry Gate](#staleness-expiry-gate-mandatory-at-session-boundaries). `EXPIRED`/`BLOCKED` means stop and re-verify before proceeding.
5. **Classify leftovers using the required disposition model** from [Workspace Reality Gate](#workspace-reality-gate-mandatory-at-session-close); unclassified leftovers are blocking.
6. **Apply [Safe Cleanup Policy](#safe-cleanup-policy):** report-first, opt-in cleanup only, no automatic deletion of ambiguous items.
7. **End with explicit closeout truth:** declare `CLEAN FIELD READY: YES` only when Active Lane + Remote Reality + Workspace Reality all qualify; otherwise `NO` with action items.

This path clarifies operator order only. It does not replace or relax any existing gate.

### Tool Enforcement

The `tools/end-session.ps1` script MUST:
- Surface all three verdicts (Active Lane, Remote Reality, Workspace Reality) separately
- Print `CLEAN FIELD READY: YES` only when the full contract qualifies
- Print `CLEAN FIELD READY: NO` with specific action items when any gate fails
- Write the repo-local clean-close proof only after a clean close qualifies, and remove any prior proof on non-clean close
- Never equate "no tracked changes" with "clean field"
- Exit nonzero whenever `CLEAN FIELD READY: NO`

---

## Consumer-Kit Drift Gate (MANDATORY at Session Start in Consumer Repos)

**Purpose:** Verify that the consumer repo's kit subtree is current, uncontaminated, and correctly wired before starting work. A consumer repo can look green locally while running stale or locally divergent kit content.

**Applicability:** This gate applies only to consumer repos that embed vibe-coding-kit via `git subtree`. It does NOT apply to the kit source repo itself.

### Definitions

**CURRENT consumer:** The consumer's kit subtree version matches the published kit version, sentinel file content matches the kit source, and required consumer-side wiring exists. The consumer is safe to proceed.

**STALE consumer:** The consumer's kit subtree version is behind the published kit version. The subtree has not been locally contaminated — it needs the explicit `run-vibe -Tool kit-update` repair path to catch up. Session work may proceed with awareness, but kit-dependent gates may enforce outdated rules.

**DIVERGENT consumer:** The consumer's kit subtree contains content that differs from the corresponding kit source version. This means someone committed changes inside the `<DOCS_ROOT>/vibe-coding/` subtree prefix outside of a subtree pull. This is always a problem — the consumer's kit content no longer matches any published kit state.

### Consumer-Kit Drift Status (3-status model)

| Status | Meaning |
|--------|---------|
| **PASS** | CURRENT — version matches, sentinel files match kit source, required consumer wiring exists |
| **WARN** | STALE or incomplete — version lag detected, or remote version unavailable, or minor consumer wiring gaps |
| **BLOCKED** | DIVERGENT — sentinel file content differs from kit source for the matching version, indicating local subtree contamination |

### Required Evidence

At session start, `tools/session-start.ps1` gathers and reports:

    1. Kit version (local)          → from <DOCS_ROOT>/vibe-coding/VIBE-CODING.VERSION.md
    2. Kit version (remote/published) → from vibe-coding-kit remote ref
    3. Version comparison            → MATCH / LAG / UNAVAILABLE
    4. Sentinel file integrity       → compare blob hashes of key files between local subtree and kit source
    5. Consumer wiring existence     → required consumer-side artifacts present

**Sentinel files checked for integrity:**
- `VIBE-CODING.VERSION.md` — version source of truth
- `protocol/protocol-v7.md` — authoritative protocol rules
- `protocol-lite.md` — quick reference

If version matches but any sentinel file blob differs from the kit source → **DIVERGENT**.

### Consumer Wiring Requirements

Consumer repos are expected to maintain these artifacts outside the kit subtree:

| Artifact | Path | Required |
|----------|------|----------|
| Overlay index | `<DOCS_ROOT>/overlays/OVERLAY-INDEX.md` | YES |

Missing required wiring with the kit current → WARN. Doc-audit catches most structural requirements separately (Control Deck, Population Gate, etc.).

### Operator Response

| Status | Action |
|--------|--------|
| **PASS** | Proceed normally |
| **WARN (STALE)** | Run `run-vibe -Tool kit-update` to update the embedded kit, or document version lag as known debt |
| **WARN (unavailable)** | Proceed with awareness that currency could not be verified (offline) |
| **BLOCKED (DIVERGENT)** | STOP. Investigate committed changes inside the kit subtree. Revert local contamination, then rerun `run-vibe -Tool kit-update` to restore kit integrity |

### Forbidden Language

Do not describe a consumer repo as "current", "up to date", or "properly configured" without Consumer-Kit Drift evidence. The session-start audit block surfaces the drift verdict automatically.

---

## Staleness Expiry Gate (MANDATORY at Session Boundaries)

**Purpose:** Prevent parked work, handoff state, and temporary items from sitting indefinitely without review. Time-sensitive state loses trustworthiness silently — this gate makes aging residue visible and actionable.

**Applicability:** Evaluated at session start (before trusting handoff state) and at session close (before stamping new handoff state). Applies to any repo using the vibe-coding session workflow.

### Definitions

**CURRENT:** The artifact has been reviewed or updated within the freshness window. Safe to trust and act on.

**STALE:** The artifact is past the freshness window but within the expiry horizon. It may still be accurate but MUST be reviewed before being trusted.

**EXPIRED:** The artifact is past the expiry horizon. It MUST NOT be trusted without full re-verification and renewal.

### Staleness Expiry Status (3-status model)

| Status | Meaning |
|--------|---------|
| **PASS** | All checked artifacts are CURRENT — within freshness windows |
| **WARN** | At least one artifact is STALE — review and renew before trusting |
| **BLOCKED** | At least one artifact is EXPIRED — full re-verification required before proceeding |

### Covered Artifact Classes

| Artifact Class | Evidence Source | Why It Can Go Stale |
|----------------|---------------|---------------------|
| **PAUSE.md handoff state** | `Date:` header field | External changes (merged PRs, upstream moves, team decisions) silently invalidate assumptions |
| **Individual PARKED items** | Disposition table last-activity date in Notes column | Parked items intended for short hold quietly become abandoned |
| **Git stash entries** | `git stash list --format="%ci"` (committer date) | Stashes intended as short-term holds silently become permanent; invisible to disposition model |
| **Local branches (no upstream, no PR)** | `git for-each-ref --format="%(committerdate:iso)" refs/heads/` | Local-only branches without upstream or PR classification go stale without visibility |
| **Extra worktrees (beyond primary)** | `git worktree list --porcelain` + ref last-commit date (`git log -1 --format="%ci" <ref>`) | Detached or forgotten worktrees can hide aging, unclassified branch debt |
| **NEXT.md active step** | `git log -1 --format="%ci" -- <DOCS_ROOT>/project/NEXT.md` (last commit date of NEXT.md) | NEXT.md is updated at task completion; a stale NEXT.md means completed work was not closed out, or the active step no longer reflects reality |

**Not covered (no canonical home yet):** Temporary waivers, one-off exceptions, ad-hoc overrides. If a waiver mechanism is added, it should integrate with this gate's expiry model.

### Required Evidence

At session boundaries, the following evidence is gathered:

    1. PAUSE.md location         → found / not found / template placeholder
    2. PAUSE.md Date field       → parsed date or unparseable
    3. Age in days               → (today − Date)
    4. Classification            → CURRENT / STALE / EXPIRED
    5. Individual PARKED items   → operator reviews disposition table dates
    6. NEXT.md last commit date  → git log -1 --format="%ci" -- <DOCS_ROOT>/project/NEXT.md
    7. NEXT.md age in days       → (today − last commit date)
    8. NEXT.md classification    → CURRENT / STALE / EXPIRED
    9. Worktree list             → git worktree list --porcelain
   10. Worktree ref age          → last commit date per attached ref (operator review)
   11. Worktree classification   → CURRENT / STALE / EXPIRED

### Threshold Table (Portable Defaults)

These are conservative defaults. Consumer repos may override via overlay.

| Artifact Class | PASS (CURRENT) | WARN (STALE) | BLOCKED (EXPIRED) |
|----------------|----------------|--------------|-------------------|
| **PAUSE.md handoff state** | ≤ 7 days | 8–30 days | > 30 days |
| **Individual PARKED items** | ≤ 14 days since last activity | 15–45 days | > 45 days |
| **Git stash entries** | ≤ 3 days | 4–14 days | > 14 days |
| **Local branches (no upstream, no PR, no ACTIVE/PARKED classification)** | ≤ 14 days since last commit | 15–30 days | > 30 days |
| **Extra worktrees (beyond primary)** | ≤ 14 days since last commit on attached ref | 15–30 days | > 30 days, unknown ref age, or detached/unowned worktree |
| **NEXT.md active step** | ≤ 7 days since last commit | 8–21 days | > 21 days |

### What the Thresholds Mean

**PAUSE.md ≤ 7 days:** Handoff state was created or verified within the last week. Context is likely still accurate.

**PAUSE.md 8–30 days:** Handoff state is over a week old. External factors may have invalidated assumptions. Review and update Date before relying on the state.

**PAUSE.md > 30 days:** Handoff state is over a month old. Statistically unreliable. Re-verify all items against current repo/remote state, rebuild PAUSE.md, then proceed.

**Individual PARKED items ≤ 14 days:** Recently parked; intended short-term hold.

**Individual PARKED items 15–45 days:** Aging. Re-evaluate: remain PARKED, promote to ACTIVE, or reclassify as OBSOLETE.

**Individual PARKED items > 45 days:** Likely abandoned. Must be reclassified (ACTIVE, OBSOLETE, or DECISION NEEDED) before declaring workspace accounted for.

**Git stash entries ≤ 3 days:** Recent interruption stash; within expected short-lived hold window.

**Git stash entries 4–14 days:** Stale. Should be promoted to a named branch or applied and discarded.

**Git stash entries > 14 days:** Expired. Almost certainly abandoned or forgotten. Must be reviewed: apply to a branch, or drop after confirming no unique work.

**Local branches (no upstream) ≤ 14 days:** Recent local work; within expected active-development window.

**Local branches (no upstream) 15–30 days:** Stale. Re-evaluate: push to remote, classify as PARKED, or delete if obsolete.

**Local branches (no upstream) > 30 days:** Expired. Likely abandoned. Must be classified (ACTIVE with upstream, PARKED, OBSOLETE) or deleted before declaring workspace accounted for.

**Extra worktrees (beyond primary) ≤ 14 days:** Recent parallel work context; keep classified and owned.

**Extra worktrees (beyond primary) 15–30 days:** Stale. Review ownership and intent; either reclassify as ACTIVE/PARKED or close as obsolete.

**Extra worktrees (beyond primary) > 30 days or unknown ref age:** Expired. Treat as untrusted residue until ownership, attached ref, and disposition are explicitly confirmed.

### Operator Actions

| Status | At Session Start | At Session Close |
|--------|-----------------|------------------|
| **PASS** | Proceed normally | Update PAUSE.md Date to today |
| **WARN** | Review PAUSE.md; confirm or update state; update Date; then proceed | Re-verify all STALE items; update dates and classifications |
| **BLOCKED** | STOP. Re-verify all handoff state against current reality. Rebuild PAUSE.md if necessary | Escalate: EXPIRED items must be reclassified before writing new PAUSE.md |

### Tool Enforcement

- `tools/session-start.ps1` parses PAUSE.md `Date:` field and surfaces the freshness verdict automatically
- Individual PARKED item review is an operator responsibility surfaced by WARN/BLOCKED status
- Worktree-age review is currently an operator responsibility (inspect `git worktree list` and attached ref age) until script automation is added
- At session close, the operator MUST update the PAUSE.md Date field as part of the End-of-Session Full Contract

### Boundary Note — Adjacent Gates

**Tool/Auth Fragility Gate** (degraded tools, auth, remote access): Separate concern from handoff-state staleness. See [Tool/Auth Fragility Gate](#toolauth-fragility-gate-mandatory-at-session-boundaries).

---

## Decision-Queue Gate (MANDATORY at Session Boundaries)

**Purpose:** Ensure that items classified as DECISION NEEDED are explicit, well-formed, bounded in count, and reviewed at every session boundary. The Workspace Reality Gate already caps the number of DECISION NEEDED items, but does not enforce structure or lifecycle. This gate fills that gap.

### Distinction from Workspace Reality Gate

| Concern | Workspace Reality Gate | Decision-Queue Gate |
|---------|----------------------|---------------------|
| What it checks | Count of DECISION NEEDED items among all leftover workspace items | Structure, ownership, and lifecycle of each decision item |
| When it fires | Session close (disposition table) | Session start (PAUSE.md review) and session close (PAUSE.md population) |
| Failure mode | Too many undifferentiated leftovers | Decision items are missing required fields, have no owner, or have accumulated without resolution |

### Well-Formed Decision Item (Required Fields)

Every item classified as DECISION NEEDED in the disposition table MUST also appear in the PAUSE.md Decision Queue section with:

| Field | Required | Description |
|-------|----------|-------------|
| Item | Yes | Short label (e.g., branch name, feature name, or topic) |
| Decision Owner | Yes | Who must decide — `Stephen` or `Agent` or specific name |
| Why Needed | Yes | One-sentence statement of what must be decided |
| Date Added | Yes | Date the item entered DECISION NEEDED status (YYYY-MM-DD) |
| Recorded In | No | Link to PAUSE.md, NEXT.md, or R-### where context lives |

An item in the disposition table classified DECISION NEEDED without a matching entry in the Decision Queue section is **malformed** — it counts toward the BLOCKED threshold.

### Decision-Queue Status (3-status model)

| Status | Meaning |
|--------|---------|
| **PASS** | All DECISION NEEDED items are well-formed; count within cap (≤ 3) |
| **WARN** | Items are well-formed but count is elevated (4–5), OR 1 item is missing a required field |
| **BLOCKED** | Count exceeds 5, OR 2+ items are malformed (missing required fields), OR any item has been in DECISION NEEDED for > 30 days without review |

### Thresholds

| Condition | PASS | WARN | BLOCKED |
|-----------|------|------|---------|
| Well-formed DECISION NEEDED items | ≤ 3 | 4–5 | > 5 |
| Malformed items (missing required fields) | 0 | 1 | ≥ 2 |
| Age of oldest unreviewed item | ≤ 14 days | 15–30 days | > 30 days |

### Decision-Queue Lifecycle

1. **At session close:** Operator classifies items as DECISION NEEDED in the disposition table AND populates the Decision Queue section in PAUSE.md with all required fields.
2. **At session start:** Review the Decision Queue section. For each item, confirm it is still unresolved or reclassify (RESOLVED, ACTIVE, OBSOLETE). Update the Date field if the item was reviewed and kept.
3. **Resolution:** When a decision is made, remove the item from the Decision Queue section and reclassify the corresponding disposition entry (typically to ACTIVE, PARKED, or OBSOLETE).

### Tool Enforcement

- `tools/session-start.ps1` parses the PAUSE.md Decision Queue section and surfaces the count and verdict automatically
- Malformed-item detection is an operator responsibility surfaced by WARN/BLOCKED status
- Age-based checks are automated when Date Added fields are parseable

### Boundary Note — Alignment with Workspace Reality Gate

The Workspace Reality Gate's default cap of `DECISION NEEDED items in queue ≤ 3 / WARN ≤ 5 / BLOCKED > 5` remains authoritative for count-based enforcement at session close. This gate adds structure and lifecycle requirements that the count-based cap alone cannot enforce. Both gates must PASS for `CLEAN FIELD READY: YES` — the WRG at close, the DQG at start.

---

## Tool/Auth Fragility Gate (MANDATORY at Session Boundaries)

**Purpose:** Ensure the system cannot claim truthful verification when parts of its toolchain are unavailable, unauthenticated, or degraded. A gate verdict of PASS is meaningless if the tool that produces the evidence could not run.

### Problem This Gate Solves

Session-boundary gates depend on external tools (`gh`, `git fetch`, remote refs). When these tools fail:
- Some scripts fall back silently to partial results
- Audit output may still appear normal
- Gate verdicts like "Remote Reality: PASS" or "OpenPRs=0" can be **false reassurance** if the tool that would have surfaced problems was unavailable

This gate exists to make the verification chain's health explicit rather than implied.

### Dependency Classification (3-status model)

Each tool/auth dependency in the verification chain is classified:

| Classification | Meaning |
|----------------|---------|
| **AVAILABLE** | Tool is present, authenticated (if applicable), and returned a usable result |
| **DEGRADED** | Tool is present but returned an error, or auth failed, or result was partial — fallback used |
| **UNAVAILABLE** | Tool is not installed, not found on PATH, or produced no usable output at all |

### Covered Dependencies

The gate covers only dependencies that the kit's session-boundary scripts actually use. Do not add speculative entries.

| Dependency | Used By | Truth Claim Affected | Fallback Exists | Fallback Preserves Truth |
|------------|---------|---------------------|-----------------|--------------------------|
| `gh` CLI (installed + authenticated) | session-start (§6 Open PRs), end-session (§8b Remote Reality) | PR count, Remote Reality verdict | Yes — `UNKNOWN` / `BLOCKED` | **No** — PR state is unknown; Remote Reality cannot be PASS |
| `git fetch` (remote connectivity) | session-start (§3 kit fetch, §3c version lag), end-session (§4 fetch, §8b ahead/behind) | Consumer-Kit Drift currency, Remote Reality ahead/behind, non-merged branch accuracy | Partial — stale local refs used | **No** — remote-dependent verdicts are based on stale data |

**Not covered** (out of scope):
- `git` itself — already enforced by hard-stop at script entry; no degraded mode possible
- Network connectivity generally — covered implicitly by `git fetch` failure
- CI/CD integrations, external APIs — kit does not use these

### Tool/Auth Fragility Status (3-status model)

| Status | Meaning |
|--------|---------|
| **PASS** | All dependencies AVAILABLE; all gate verdicts are fully trustworthy |
| **WARN** | At least one dependency DEGRADED or UNAVAILABLE, but the affected truth claims are already downgraded (e.g., Remote Reality: BLOCKED reflects the degradation) |
| **BLOCKED** | A dependency is UNAVAILABLE or DEGRADED and the affected gate verdict does NOT already reflect the degradation — the system is making a claim it cannot support |

### Classification Rules

| Condition | Verdict |
|-----------|---------|
| `gh` AVAILABLE + `git fetch` succeeded | **PASS** |
| `gh` UNAVAILABLE but Remote Reality already WARN or BLOCKED | **WARN** — degradation is honestly surfaced |
| `gh` UNAVAILABLE and Remote Reality claims PASS | **BLOCKED** — false reassurance |
| `git fetch` failed but all remote-dependent verdicts already WARN or BLOCKED | **WARN** — degradation is honestly surfaced |
| `git fetch` failed and any remote-dependent verdict claims PASS | **BLOCKED** — stale refs masquerading as truth |
| Both `gh` UNAVAILABLE and `git fetch` failed | **WARN** if all affected verdicts are already downgraded; **BLOCKED** otherwise |

### Required Evidence

At each session boundary where Tool/Auth Fragility is assessed, produce:

1. **Dependency inventory** — for each covered dependency: AVAILABLE / DEGRADED / UNAVAILABLE
2. **Affected verdicts** — which other gate verdicts depend on the degraded tool
3. **Honest disclosure** — whether the affected verdicts already reflect the degradation or are falsely reassuring

### What Action Is Required

| Status | Action |
|--------|--------|
| **PASS** | Proceed normally |
| **WARN** | Record which dependencies are degraded in the session audit block or PAUSE.md. Other gate verdicts are already honest — no additional action required |
| **BLOCKED** | STOP. Fix the toolchain issue (install `gh`, authenticate, restore network) or explicitly downgrade the affected gate verdicts to WARN/BLOCKED before proceeding. Do not claim PASS for a gate whose evidence tool was unavailable |

### Tool Enforcement

- `tools/session-start.ps1` tracks `gh` availability and `git fetch` outcome, then surfaces a combined `ToolAuth` verdict in the audit block
- `tools/end-session.ps1` tracks `gh` availability and `git fetch` outcome, then surfaces a `ToolAuth` verdict in the footer
- Both scripts already downgrade Remote Reality to BLOCKED or WARN when `gh` fails — the gate makes this explicit and adds a single aggregated signal

### Boundary Note — Relationship to Other Gates

This gate does not replace or override other gate verdicts. It is a **meta-gate** that assesses whether the evidence behind other gates is trustworthy. When Tool/Auth Fragility is WARN or BLOCKED, the affected gate verdicts should be interpreted with the stated caveats, not treated as fully verified.

---

## Manual Test Checklist Artifact (MANDATORY)

**Purpose:** Make manual testing reproducible and auditable.

### A) Manual Test Is a Document

**Rule:** Every manual test session MUST produce a checklist document:
- Location: `<DOCS_ROOT>/testing/manual/` or in the relevant R-### report
- Format: Numbered test cases with IDs

### B) Required Checklist Format

| Test ID | Description | Expected Outcome | Actual | Pass/Fail |
|---------|-------------|------------------|--------|-----------|
| MT-001 | <what to do> | <what should happen> | <what happened> | ✅ / ❌ |
| MT-002 | ... | ... | ... | ... |

### C) Test Artifact Retention

**Rule:** Manual test checklists are evidence. They MUST be:
- Committed to the repo (not just in chat)
- Referenced in PR descriptions when validating fixes
- Linked from relevant R-### documents

---

## Help Triggers + Churn Circuit Breaker (Solution-Agnostic)

This section defines when to STOP and ask for help instead of proceeding with uncertain edits.

### A) Churn Circuit Breaker (WHEN TO STOP AND ASK FOR HELP)

Stop execution and request a report if ANY of these are true:

1. **Multi-tenant/scenario copy without registry key** — You are adding narrative/copy to a multi-tenant or multi-scenario app AND the copy is not already keyed/registry-scoped (e.g., `introByScenario[scenarioId]`).
2. **Cross-cutting change without call-site map** — A change touches 2+ routes/components OR duplicates logic across files, and you do not have a map of affected call sites.
3. **Unknown runtime key** — You do not know the exact runtime key (scenarioId/tenantId/etc.) that gates the change.
4. **Recent revert/rewrite** — A prior step in this session had to be reverted/rewritten due to missing invariants (e.g., cross-scenario bleed, missing registry).
5. **Audit outcome WARN/RED** — Investigation outcome is WARN or RED (audit report) and the next step involves refactoring.
6. **Unfamiliar files without map** — You need line-precise edits across unfamiliar files and do not have a map of call sites/tests.

When ANY of these triggers fire, STOP and follow the Help Ladder (below).

### B) Help Ladder (WHAT HELP TO ASK FOR)

Use this escalation order:

1. **Local search fallback first** — If the uncertainty is purely "find call sites," use git grep / Select-String and report findings before editing.
2. **Request Agent Report (read-only)** — If uncertainty remains after local search, request an Agent Report (read-only investigation) before coding.
3. **Timebox a spike (read-only)** — If still unclear, timebox a spike (read-only) and report back before committing to implementation.

### C) Agent Report Template

When requesting an Agent Report, use this structure:

    PROMPT-ID: REPORT-<TOPIC>-<NNN>
    
    Goal: <1-sentence description of what needs to be understood>
    Scope: Read-only investigation; no code edits.
    
    Required sections in report:
    - Runtime key plumbing (how scenarioId/tenantId flows through the app)
    - Call sites (files/lines that need updates)
    - Duplication map (where logic is repeated across files)
    - Smallest safe diff steps (ordered list of minimal changes)
    - Tests impacted (which test files/specs to update)
    
    Output: Single markdown report in <DOCS_ROOT>/status/, no fenced code blocks.
    
    # END PROMPT

## Interface Forecast Micro-Gate (MANDATORY before first wiring step)

**Purpose:** Reduce return-type churn by designing interfaces upfront.

**Before writing the first line of wiring code (connecting helper to component), complete this checklist:**

### Interface Forecast Checklist

- [ ] **Define v1 return shape** — Write the full TypeScript return type BEFORE implementation
- [ ] **Prefer stable objects over primitives** — Return `{ value, metadata }` not just `value`
- [ ] **List likely-to-change fields** — Mark fields that may expand (use `?` optional or plan for additions)
- [ ] **Confirm downstream consumers** — List which components/services will consume this interface

### Anti-Churn Patterns

**DO:** Return full objects from the start

    // Good: Stable object, easy to extend
    interface Result { messageId: string; layers: { l1: string; l2: string; l3: string } }

**DON'T:** Return primitives then refactor to objects later

    // Bad: Forces downstream changes when you need metadata
    function getMessage(): string  // v1
    function getMessage(): { text: string; id: string }  // v2 (breaking)

### When to Skip

Interface Forecast is NOT required for:
- Pure refactors (no new interfaces)
- Docs-only changes
- Test-only changes (S1A RED-LOCK)

---

## Copy & Semantics Gate (MANDATORY for UX/copy/narration changes)

Before changing any user-facing copy (coach/tutor text, labels, microcopy, narration, prompts), you MUST write down:

1. **Section Map** (screen structure)
   - List the sections in order as users see them (e.g., Meta line → Prompt → Controls → Coach → Continue).

2. **Semantic Hierarchy**
   - Assign roles / header levels (e.g., H1 page intent, H2 prompt, H3 helper/coach).
   - State what is PRIMARY vs SUPPORTING vs OPTIONAL.

3. **Copy Source Decision**

Choose ONE:
- **TS constant** (only if stable and unlikely to churn)
- **JSON asset dictionary** (preferred when iterating)
- **Content schema** (content/categories/*.json) when copy should be content-owned
- **Admin pipeline** (only when we explicitly scope it)

**Rule**: If copy is likely to iterate, move it OUT of TypeScript first (JSON dictionary minimum) before "voice" tuning.

**Evidence to include in the report**:
- The final Section Map + chosen Copy Source.

## Required Reading (Proof-of-Read List)

Before starting work, read and quote from these files:
- `<DOCS_ROOT>/vibe-coding/protocol/protocol-v7.md` (this file)
- `<DOCS_ROOT>/vibe-coding/protocol/copilot-instructions-v7.md`
- `<DOCS_ROOT>/vibe-coding/protocol/stay-on-track.md`
- `<DOCS_ROOT>/vibe-coding/protocol/working-agreement-v1.md`
- `<DOCS_ROOT>/status/branches.md`
- `<DOCS_ROOT>/testing/test-catalog.md` (required when touching tests)

**Required Reading Integrity Check (MANDATORY):**
If a required-reading document is missing from the repo:
1. STOP — do not claim Proof-of-Read PASS for missing files
2. Choose one of:
   - (A) Create a minimal stub for the missing doc, OR
   - (B) Update the required-reading list to reference a correct/existing doc
3. Document which option was chosen in the report

You may NOT proceed with work while required-reading files are missing.

## Required Reading Sets (by Prompt Type)

### Work Prompts (S0A / S1A / S2A)

Full reading set:
- `<DOCS_ROOT>/vibe-coding/protocol/protocol-v7.md`
- `<DOCS_ROOT>/vibe-coding/protocol/copilot-instructions-v7.md`
- `<DOCS_ROOT>/vibe-coding/protocol/stay-on-track.md`
- `<DOCS_ROOT>/vibe-coding/protocol/working-agreement-v1.md`
- Relevant story doc(s) for the work
- `<DOCS_ROOT>/testing/test-catalog.md` (if tests may be touched)

### Closeout Prompts (S2C merge/closeout)

Minimal reading set (merge-focused):
- `<DOCS_ROOT>/vibe-coding/protocol/protocol-v7.md` (S2C / Merge Checklist section)
- `<DOCS_ROOT>/vibe-coding/templates/closeout-artifact-verification-template.md`
- `<DOCS_ROOT>/status/branches.md`
- `<DOCS_ROOT>/vibe-coding/protocol/stay-on-track.md` (only when scope includes strict guardrails)

**Note**: S2C prompts that include additional work beyond merge should use the full Work Prompt reading set.

## Prompt Structure

~~~markdown
PROMPT-ID: <ID>
## GOAL
## SCOPE GUARDRAILS
## TASKS
# END PROMPT
~~~

## Response Structure

**CRITICAL:** The entire response (from PROMPT-ID through final summary) must be ONE copy-paste ready markdown document. Do NOT fragment output or treat "the report" as separate from "the response."

1. **PROMPT-ID** (mandatory first line): Echo exact PROMPT-ID from the executed prompt. If prompt lacks PROMPT-ID, STOP and request corrected prompt.
2. **Prompt Review Gate** (mandatory, exactly 4 lines, BEFORE any work or Proof-of-Read):
   - What: (1-line summary)
   - Best next step? YES/NO
   - Confidence: <percentage>%
   - Work state: READY|IN-PROGRESS|COMPLETE|MERGED|OBSOLETE
   
   **Command Lock enforcement:** NO commands, edits, or searches are allowed before printing these 4 lines. If Confidence is below the applicable threshold (< 95% docs, < 99% runtime), Best next step != YES, or Work state != READY (except merge/closeout requiring COMPLETE), STOP and explain.
3. **Proof-of-Read** (mandatory after the Gate; must appear before any searches or edits; 1-2 complete sentences 10-50 words per file)
4. **Work** (execute tasks only after gate passes; repo sanity commands may run before Proof-of-Read)
5. **Green Gate** (run tests + build)
6. **Summary** (what changed, files touched)

### Session Sequencing Rule (Hard Stop)
- Do not propose or author a new operator prompt until the full Copilot completion report for the current prompt has been pasted and acknowledged in chat.
- If an operator says “wait for Copilot’s report” (or any phrasing that the prior report is still pending), STOP immediately and wait for their confirmation before resuming.

**Report Formatting Rule (STRICTLY ENFORCED):**
- ZERO fenced code blocks anywhere in your response (no ``` markers)
- Use 4-space indentation for command output, code snippets, and examples
- The response IS the report - one continuous markdown document
- Operator must be able to copy the entire response with one selection

## Lean Prompts and Context Budgeting (MANDATORY)

**Purpose:** Preserve context window budget. Large pasted docs and verbose reports consume tokens that should be spent on reasoning and code.

### Two-Layer Prompt Pattern

Prompts should separate execution instructions from reference material:

1. **Execution Prompt** — The tasks, scope, and gates (compact; fits in one screen)
2. **Read List** — File paths only, not pasted content. The executor reads them on demand.

**Example read list (preferred):**

    Read before work:
    - protocol/protocol-v7.md (§ Green Gate)
    - <DOCS_ROOT>/project/NEXT.md

**Anti-pattern (banned by default):** Pasting entire file contents into a prompt. Link to file paths + quote only the relevant lines (10-50 words) instead.

### Delta-Only Reports

Completion reports must include ONLY:

- **Changes made** (files + what changed, 1 line per file)
- **Proof** (command output, test results — summarized unless failing)
- **Verdict** (PASS/FAIL + next step)

**Raw evidence** (full terminal output, large diffs) is included ONLY when:
- A gate is failing and the output is needed for diagnosis
- The operator explicitly requests it

### Report Size Guardrail

If a report would exceed ~200 lines, split into:
1. Summary report (changes + verdict)
2. Evidence appendix (linked, not inlined — saved to `<DOCS_ROOT>/status/` if needed)

## Lint-Suppress Before Lint-Fix (MANDATORY DEFAULT)

**Default action:** When working code triggers a lint warning, **suppress with rationale** rather than "fix" the code.

**Rule:** If a linter (ESLint, TSLint, etc.) complains about intentionally-designed code:
- **DO:** Add `// eslint-disable-next-line <rule> -- <rationale>` immediately above the line
- **DO NOT:** "Fix" the code to satisfy the linter unless you have explicit behavior verification

**Escalation:** Only "fix" (change code to satisfy linter) if the prompt explicitly includes:
1. Behavior contract (what the code does before/after)
2. Verification plan (test or smoke that proves behavior unchanged)
3. Approval for behavioral change in scope

**ESLint Suppression Placement (MANDATORY):**
- `eslint-disable-next-line` must be immediately above the suppressed line (not on same line, not separated by blank lines)
- Must include 1-line rationale after `--`

**Background:** See postmortem `docs/postmortems/2026-01-08-postmortem-lint-cleanup-regression.md` — "fixing" react-hooks/exhaustive-deps warnings broke SignalR multiplayer functionality.

## Hook Dependency Change Gate (React/TS Projects Only)

> **Applies to:** React/TypeScript projects with hooks. Skip for ASP.NET MVC projects.

**Rule:** Any change to React hook dependency arrays (`useEffect`, `useCallback`, `useMemo`) is a **behavioral change**, not a cleanup.

**Rationale:** Dependency arrays control when effects re-run. Adding/removing deps changes execution timing and can introduce race conditions.

**Hook Deps Change Block (REQUIRED for any deps modification):**

    HOOK DEPS CHANGE
    File: <path>
    Hook: <useEffect/useCallback/useMemo> at line <N>
    BEFORE deps: [<list>]
    AFTER deps: [<list>]
    Rationale: <why this change is necessary>
    Behavior contract: <what should happen before and after>
    Verification: <test name or smoke sequence proving behavior preserved>

**STOP condition:** If you cannot complete this block, do not modify the dependency array. Use `eslint-disable-next-line` instead.

## Cleanup Scope Rule (MANDATORY for lint/formatting/hygiene stories)

> **Note:** React-specific items below (hook dependency arrays) apply only to React/TS projects.

**Rule:** Cleanup stories may NOT introduce runtime behavior changes.

**Prohibited in cleanup scope:**
- Modifying React hook dependency arrays (React/TS only)
- Adding guards/refs that change execution flow
- Changing connection lifecycle or subscription timing
- Altering state update sequences

**If lint can only be satisfied via behavior change:**
1. STOP the cleanup story
2. Split into a separate story with explicit behavior scope
3. New story must include behavior contract + verification (test or smoke)

**Safe cleanup actions:**
- Removing unused imports/variables
- Renaming private identifiers
- Reformatting/indentation
- Adding type annotations
- Suppressing lint warnings with rationale

## Hot File Protocol (General)

Hot files include any of the following:
- Files over ~300 LOC that coordinate routing, state, or persistence
- Known churn magnets (list yours in a consumer overlay; see [hot-files-overlay.example.md](../templates/hot-files-overlay.example.md))
- Files touched in the last three prompts (detect via: git log --oneline --follow -3 -- <file>)

When a prompt touches a hot file, you MUST pick one of two paths:
1. **Analysis-first prompt**: map the file’s responsibilities, enumerate entry points, and list all impacted tests before any edits.
2. **Full-file replacement prompt**: replace the entire file in one shot (single edit) and run tests/build in the same prompt.

Piecemeal line edits on hot files are forbidden. If a prompt would require them, STOP and request the operator restructure the work.

## Pre-S2C Sync Check (Mandatory)

Before starting any S2C (merge) prompt, check if your branch is behind main:

~~~powershell
git fetch origin
git log HEAD..origin/main --oneline
~~~

If behind main: run an S2B sync step first (merge origin/main into branch), then run the applicable Green Gate (see [Green Gate — Stack-Aware Rules](#green-gate--stack-aware-rules)).

## S2C / Merge Checklist

Before closing any S2C (merge/closeout) prompt:

- [ ] Green Gate passes (stack-aware — see [Green Gate — Stack-Aware Rules](#green-gate--stack-aware-rules))
  - .NET: `msbuild` succeeds
  - JS (if applicable): `npm run build` + `npm run test` succeed
- [ ] Verify artifacts exist on main (file presence + key strings)
- [ ] Include Artifact Verification table in completion report

See `docs/protocol/closeout-artifact-verification-template.md`.

## GREEN Means Merge Now (Mandatory)

Any branch that reaches 🟢 GREEN must be merged (S2C) in the same session.

If you cannot merge immediately, add a **PARKED** row to `<DOCS_ROOT>/status/branches.md` including:
- Why parked
- Exact next prompt ID to resume
- Date/time parked

## Enforcement

- Missing Proof-of-Read → STOP
- Confidence < 95% → STOP and clarify (< 99% for runtime/code execution)
- Test/build failure → STOP and fix before proceeding
- Missing artifact verification in S2C → incomplete closeout

## Coverage Checklist for cross-cutting work (MANDATORY)

**Objective definition (a change is cross-cutting if ANY of):**
- Touches 2+ routes (count distinct route definitions in your routing config; parameterized variants count separately if separate route configs), OR
- Changes a shared file imported by 3+ components, OR
- Modifies global CSS variables/shared copy dictionaries/typography standards

**Examples (non-exhaustive):**
- Palette CSS variables (--mg-primary, --mg-bg, etc.)
- Voice/tone adjustments (disclaimers, calm language, medical framing)
- Layout grids or spacing systems
- CTA button styles or labels
- Shared UI components (headers, footers, navigation)
- Monospace rendering or typography standards

For ANY cross-cutting change, your completion report MUST include a route coverage table using the actual project routes from your consumer overlay
(see [project-routes-overlay.example.md](../templates/project-routes-overlay.example.md)):

   Route        | Status
   -------------|-------------------------------
   /<route-1>   | UPDATED or NO CHANGE REQUIRED (reason)
   /<route-2>   | UPDATED or NO CHANGE REQUIRED (reason)
   /<feature>/:id | UPDATED or NO CHANGE REQUIRED (reason)
   …            | (one row per route in your app)

Status values must be exactly **UPDATED** or **NO CHANGE REQUIRED** with a short justification. Do not invent alternate labels. If you cannot complete this table, STOP and clarify scope.

**Old Pattern Search (MANDATORY STOP CONDITION):**
- Command used: paste the exact search/grep command you ran for the retired pattern.
- Total matches found: include the count and note which files were inspected.
- Remaining occurrences: list intentional exceptions or confirm 0. If you cannot show this search, STOP and request help before editing further.

## UX Proof requirement for user-visible changes (MANDATORY)

For any change affecting what users see (copy, layout, tone, labels, disclaimers, visualizations):

Your completion report MUST include:

**Proof-of-Experience Block (Before / After / Where):**
- What the user sees now: quote the current copy or describe the DOM
- What changed: show Before → After for the exact element(s)
- Routes displaying this change: map to the same consumer overlay coverage list
- Visual verification: screenshot description or DOM snippet confirming the new state

Without proof-of-experience, UX work is incomplete and prone to regression.

## Bundle warnings policy (STANDARD)

Bundle size warnings are informational during demos but must be resolved or tracked before pre-release:
- Warnings under +1 kB per component: acceptable; note briefly in the report.
- Warnings over +1 kB: document rationale and mitigation plan (ticket link or TODO) before shipping pre-release builds.
- Persistent growth trend (3+ commits): flag for optimization review and propose a fix path.

**Pre-release definition:** Any tagged release candidate (vX.X.X-rc1 or later). Demo branches and dev commits exempt. Bundle warnings do NOT block Green Gate by themselves, but you must either fix or track them before tagging a release candidate.

## Prompt Authoring — Test-Touch Rule

Any prompt that may touch `*.spec.ts` MUST include the Test-Touch Block from:
`docs/protocol/test-touch-block-template.md`

---

## Remote Target Preflight (MANDATORY for DEV/STAGE/PROD automation)

**Trigger:** Any prompt that hits DEV, STAGE, or PROD via Playwright, Selenium, or browser automation, OR any network-dependent CI gate.

**Required Checks (run in order before browser automation):**

1. DNS Resolution: `nslookup <hostname>` or `Resolve-DnsName <hostname>`
2. HTTP HEAD: `curl -I --max-time 30 http://<hostname>` or `Invoke-WebRequest -Uri "http://<hostname>" -Method Head`
3. HTTPS HEAD: `curl -I --max-time 30 https://<hostname>` or `Invoke-WebRequest -Uri "https://<hostname>" -Method Head`

**Stop Rule:** If any preflight check fails, STOP immediately and create a research artifact (R-###) or tech debt item (TD-###) documenting the failure before continuing. Do not attempt browser automation until preflight passes.

**Redaction Rule:** Never include secrets, credentials, or API keys in logs or output.

---

## Environmental Debug Timebox (MANDATORY)

When debugging environmental issues (network, TLS, proxy, machine-specific):

**Hard Limits:**
- Maximum 20 minutes OR 3 meaningful variations (config/URL/wait mode/machine/network)
- If the failure mode does not change after 3 variations: STOP

**Stop Procedure:**
1. Document the failure in a research artifact (R-###)
2. Create a tech debt item (TD-###) with clear Definition of Done
3. Park the work and pivot to next-highest ROI task (docs, CI gates, other stories)

**Rationale:** Environmental issues often require server-side, network, or machine changes that Copilot cannot fix. Persisting wastes time.

---

## Shell Discipline (MANDATORY)

**Default Shell:** PowerShell

**Rules:**
1. All prompts MUST use PowerShell syntax unless explicitly stated otherwise
2. Do NOT mix cmd.exe operators (e.g., `&&`) with PowerShell constructs (e.g., `$env:VAR`)
3. Use semicolons (`;`) to chain PowerShell commands, not `&&`
4. If cmd.exe is required, the prompt MUST explicitly state "cmd.exe" and use cmd.exe syntax throughout

**Example (correct):**
    Set-Location C:\repo; $env:VAR='value'; npm run test

**Example (wrong):**
    cd C:\repo && $env:VAR='value'; npm run test

---

## CI Gate Order Policy (MANDATORY)

Minimum CI gates in execution order:

1. **Build Gate (compile)** — MSBuild/dotnet build; most reliable; pure compile check
2. **Stage Health Gate (curl/HEAD)** — Simple network verification; no browser
3. **Automated Tests (unit/integration)** — When available; no external dependencies
4. **Browser E2E (optional)** — Most fragile; run last; requires stable preflight + health gates

**Policy:** Browser E2E should NOT be a required gate until:
- Remote Target Preflight passes consistently
- Stage Health Gate passes consistently
- TLS/SSL issues on target environment are resolved or explicitly bypassed

---

## Blocked Goal Procedure (MANDATORY)

When a goal is blocked by environmental, infrastructure, or external issues:

**Immediate Actions:**
1. Create a research artifact (R-###) documenting:
   - What was tried (commands, configs)
   - Evidence of failure (error messages, logs)
   - Root cause hypothesis
2. Create a tech debt item (TD-###) with:
   - Clear Definition of Done
   - Validation steps
   - Evidence links to R-###
3. Link both in ResearchIndex.md and tech-debt-and-future-work.md

**Pivot:** After documenting, pivot to the next-highest ROI work:
- CI gates (build, health check)
- Documentation updates
- Other stories in the backlog

**Anti-Pattern:** Do NOT continue attempting variations beyond the timebox. Do NOT leave blocked work undocumented.

---

## Waiting-for-Approver Workflow (MANDATORY)

**Purpose:** Define allowed work while PRs await Maintainer (or other approver) review.

### A) Allowed While Waiting

| Action | Allowed |
|--------|---------|
| Continue work on feature branches | ✅ YES |
| Docs-only PRs and commits | ✅ YES |
| Research and investigation | ✅ YES |
| Keep branches current (git merge origin/develop) | ✅ YES |
| Open new PRs for independent work | ✅ YES |

### B) Not Allowed

| Action | Forbidden |
|--------|-----------|
| Merge to develop without approval | ❌ NO |
| Stack dependent PRs (PR B depends on unmerged PR A) | ⚠️ AVOID |
| Assume PR will be merged "soon" | ❌ NO |

### C) PR Communication

**One Merge Packet comment per PR:**
- Add a single comment summarizing: what the PR does, test evidence, merge dependencies
- Do NOT spam multiple reminder comments
- If PR ages >48h, one polite ping is acceptable

### D) Branch Currency

**Keep branches current:** Before resuming work on a branch:

    git fetch origin
    git merge origin/develop

This reduces merge conflicts when approval comes.

### E) Update NEXT.md

If blocked on approvals, update NEXT.md:
- Status: BLOCKED
- Blocked By: PR #NN awaiting approval
