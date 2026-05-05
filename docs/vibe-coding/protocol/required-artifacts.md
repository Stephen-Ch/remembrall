# Required Artifacts — Vibe-Coding Kit

**Purpose:** This file is the single source of truth for Doc Audit requirements. Changes to required artifacts must update [VIBE-CODING.VERSION.md](../VIBE-CODING.VERSION.md).

---

## Quick Reference Index

Use this table to find process rules and gates. Each row links to the canonical definition.

| Rule / Gate | Purpose | Where | When to Use |
|-------------|---------|-------|-------------|
| **CORE/STRETCH/CHECKPOINT** | Classify steps for scope control + safe pause points | [required-artifacts.md § Step Classification](#step-classification-core--stretch--checkpoint) | Every step list (story tables, NEXT.md) |
| **Interface Forecast** | Define return types before wiring to reduce churn | [protocol-v7.md § Interface Forecast Micro-Gate](protocol-v7.md#interface-forecast-micro-gate-mandatory-before-first-wiring-step) | Before first wiring step |
| **Closeout Checklist Gate** | Ensure clean handoffs + rollback safety | [closeout template § Closeout Checklist Gate](../templates/closeout-artifact-verification-template.md#closeout-checklist-gate-mandatory-before-marking-story-complete) | Before marking story COMPLETE |
| **Flake Protocol** | Handle flaky tests; require TD ticket | [protocol-v7.md § Core Rule #5](protocol-v7.md#core-rules-non-negotiable) | When test fails then passes on rerun |
| **Agent Safety Policy** | Enforce role boundaries (code vs research) | [working-agreement-v1.md § Agent Safety Policy](working-agreement-v1.md#agent-safety-policy-mandatory) | Any agent task assignment |
| **READ-ONLY Handshake** | Confirm read-only scope for research tasks | [working-agreement-v1.md § Report-Only Handshake](working-agreement-v1.md#report-only-handshake-required-for-read-only-tasks) | Research/audit prompts |
| **PROMPT-ID First Line** | Completion report must start with exact PROMPT-ID | [copilot-instructions-v7.md § Non-Negotiables](copilot-instructions-v7.md#non-negotiables-formal-work-prompts) | Every formal work prompt completion |
| **Flake Suspect Footer** | Report flaky test status in completion | [protocol-v7.md § Core Rule #5](protocol-v7.md#core-rules-non-negotiable) | Every completion report |

---

## Mandatory Project Docs

Every project using the vibe-coding workflow MUST maintain these three Control Deck docs:

### 1. <DOCS_ROOT>/project/VISION.md
**Purpose:** Define project purpose, long-term vision, user promise, and non-goals.

**Minimal content expectations:**
- Purpose: Why the project exists, what problem it solves
- North Star: 1-3 year vision
- User Promise: What experience users can expect
- Non-Goals: Explicit constraints or scope boundaries accepted

**Template:** [<DOCS_ROOT>/project/VISION.template.md](../../project/VISION.template.md)

### 2. <DOCS_ROOT>/project/EPICS.md
**Purpose:** Track high-level epic list with IDs, status, and descriptions.

**Minimal content expectations:**
- Epic List: At least one EPIC-NNN entry
- Each epic must have: Status (PLANNED | IN PROGRESS | COMPLETE), Description (1 paragraph with goals + success criteria)

**Template:** [<DOCS_ROOT>/project/EPICS.template.md](../../project/EPICS.template.md)

### 3. <DOCS_ROOT>/project/NEXT.md
**Purpose:** Canonical active plan defining ACTIVE STORY + NEXT STEP for current work.

**Minimal content expectations (REQUIRED):**
- ACTIVE STORY ID: Story currently being worked on (e.g., EPIC-001-S01 or TD-PROTOCOL-V7-005)
- NEXT STEP: Single sentence describing the next tiny TDD step or docs-only change
- DoD (Definition of Done): What proof confirms this step is complete (tests GREEN? docs exist? evidence gathered?)
- Scope Guardrails: Hard boundaries (files/folders in-scope vs out-of-scope)
- Done When: Specific exit criteria (e.g., "npm test passes", "<DOCS_ROOT>/project/VISION.md exists")
- Last Updated: Date (YYYY-MM-DD format) showing when <DOCS_ROOT>/project/NEXT.md was last refreshed
- **Inputs/Research (when applicable):** Links to return packets in <DOCS_ROOT>/status/ that informed this work (see [return-packet-gate.md](return-packet-gate.md))

**Goal Anchor Fields (Control Deck)**

Copyable block:

    Goal Anchor Fields (Control Deck)
    North Star:
    Current Slice:
    Proof:
    Out of Scope (optional, 1-3 bullets):
    Parking Lot link (optional):

**Placement rule:** Put Goal Anchor Fields in NEXT.md for the current work slice and/or in the active Epic section in EPICS.md. Update at most once per session to avoid churn.

**Template:** [<DOCS_ROOT>/project/NEXT.template.md](../../project/NEXT.template.md)

**Return Packet Linking Rule:**
When return packets exist for the current story, NEXT.md MUST include an "Inputs/Research" section linking to those return packets. This creates traceability from the active story back to the research that informed it.

**<DOCS_ROOT>/project/NEXT.md Lightweight Rule:**
- Keep under ~30 lines total
- Focus only on: Active Story, Next Step, DoD, Scope, Done-When
- No essays or multi-paragraph explanations
- Update in same commit after completing NEXT STEP, or immediate docs-only follow-up
- If updating feels like paperwork, the format is wrong—tighten it

## Step Classification (CORE / STRETCH / CHECKPOINT)

**Purpose:** Prevent scope creep and enable clean pause points.

**Every step list (story step tables, NEXT.md task lists) MUST classify each step as:**

| Classification | Meaning | Closeout Rule |
|----------------|---------|---------------|
| **CORE** | Required for story completion; cannot skip | Must be done before any closeout |
| **STRETCH** | Nice-to-have; deferrable to future work | May be explicitly deferred |
| **CHECKPOINT** | Safe pause/closeout point | Story can close here if needed |

**Rules:**
1. Every step list MUST have at least one CHECKPOINT step
2. CHECKPOINT steps must be placed after meaningful increments (not mid-feature)
3. If closing early at a CHECKPOINT, document what remains in "Deferred to future" section
4. STRETCH steps must never block a CHECKPOINT

**Example step table:**

| Step | Description | Classification |
|------|-------------|----------------|
| S1A | Add failing test | CORE |
| S1B | Implement feature | CORE |
| S1C | Integration test | CORE |
| ✓ | **CHECKPOINT: MVP complete** | CHECKPOINT |
| S1D | Add analytics | STRETCH |
| S1E | Performance optimization | STRETCH |

---

## Doc Audit Workflow

Start-of-Session Doc Audit (see consumer Start-Here doc; repo-specific, referenced in copilot-instructions.md) verifies:
1. VIBE-CODING.VERSION.md exists (version + effective date)
2. required-artifacts.md exists (this file)
3. <DOCS_ROOT>/project/VISION.md, <DOCS_ROOT>/project/EPICS.md, <DOCS_ROOT>/project/NEXT.md all exist with required content

**Doc Audit Rerun Detection:** After each commit, Doc Audit rerun is required if `required-artifacts.md` or Control Deck files changed since last audit. Run:

    git diff --name-only HEAD~1..HEAD

Rerun required if any output path matches:
- `<DOCS_ROOT>/project/` (any Control Deck file — VISION.md, EPICS.md, NEXT.md)
- `<DOCS_ROOT>/vibe-coding/protocol/required-artifacts.md`

**EXCEPTION:** If `HEAD~1` does not exist (initial commit or detached HEAD), treat as rerun required.

If ANY required artifact is missing or <DOCS_ROOT>/project/NEXT.md is unclear/outdated:
- Work state: IN-PROGRESS → STOP CODING
- Enter Alignment Mode (see [alignment-mode.md](alignment-mode.md))
- Ask Stephen minimum questions to finalize VISION/EPICS/NEXT
- Use templates to create missing docs

If ALL required artifacts are present and <DOCS_ROOT>/project/NEXT.md is clear:
- Work state: READY
- Proceed with coding using NEXT STEP as guide

## Control Deck Population Gate (MANDATORY)

**Purpose:** Prevent coding when Control Deck files exist but contain placeholders or trivially empty content.

**PASS/FAIL Rules:**

**FAIL if ANY file contains placeholder markers (case-insensitive):**

Canonical placeholder marker set:
- TBD, TODO, TEMPLATE, PLACEHOLDER, FILL IN, COMING SOON, XXX, FIXME, TO BE DETERMINED, <fill

Any occurrence of these markers in Control Deck files (<DOCS_ROOT>/project/VISION.md, <DOCS_ROOT>/project/EPICS.md, <DOCS_ROOT>/project/NEXT.md) is FAIL.

**Safe scan command (copy/paste ready, repo root required):**

  grep -iE '(TBD|TODO|TEMPLATE|PLACEHOLDER|FILL IN|COMING SOON|XXX|FIXME|TO BE DETERMINED|<fill)' <DOCS_ROOT>/project/VISION.md <DOCS_ROOT>/project/EPICS.md <DOCS_ROOT>/project/NEXT.md

**Alternative with ripgrep (if available):**

  rg -i '(TBD|TODO|TEMPLATE|PLACEHOLDER|FILL IN|COMING SOON|XXX|FIXME|TO BE DETERMINED|<fill)' <DOCS_ROOT>/project/

**WARNING:** Running git ls-files VISION.md from docs/project will return nothing (relative path). Always anchor to repo root using Set-Location (git rev-parse --show-toplevel); git rev-parse --show-toplevel; Get-Location before any git path checks.

**PASS example (no markers):**
"AcmeApp is a training-first application that helps users practice core skills and track progress."

**FAIL example (contains placeholder):**
"Purpose: TBD — needs Stephen's input" (contains TBD placeholder marker)

**FAIL if required fields are missing or trivially empty:**
Use objective word-count thresholds below to determine PASS vs FAIL.

**Per-File Population Requirements (PASS criteria with objective thresholds):**

### <DOCS_ROOT>/project/VISION.md must include:
1. **Purpose** (non-placeholder): >= 25 words explaining why the project exists and what problem it solves
2. **North Star** (non-placeholder): >= 25 words describing the 1-3 year vision
3. **User Promise** (non-placeholder): >= 25 words describing the user experience
4. **Non-Goals** (non-placeholder): At least 2 explicit constraints or scope boundaries ("We are NOT..." format), each >= 10 words

**PASS example (Purpose section):**
"AcmeApp is a training-first application that helps users practice core skills and, optionally, advanced techniques in a low-stakes, learn-by-doing loop. It exists to make decision-making feel understandable, repeatable, and measurable for everyday users."

**FAIL example (Purpose section):**
"A game about politics." (only 4 words, lacks explanation of problem solved)

### <DOCS_ROOT>/project/EPICS.md must include:
1. **At least 1 epic** with unique ID (e.g., EPIC-001, OC-PROTOCOL-V7). Rationale: early-stage projects shouldn't invent fake epics to pass; expand as roadmap solidifies.
2. Each epic must have:
   - **Status**: One of PLANNED | IN PROGRESS | COMPLETE (not "TBD" or empty)
   - **Description**: >= 15 words with goals + success criteria (not placeholder text)

**PASS example (epic description):**
"EPIC-001: Content Pipeline — Build admin workflow for creating question content with JSON validation and preview. Success: Stephen can add 10 questions per hour."

**FAIL example (epic description):**
"Build admin tools." (only 3 words, no goals or success criteria)

### <DOCS_ROOT>/project/NEXT.md must include:
1. **ACTIVE STORY ID** (non-placeholder, not "TBD")
2. **NEXT STEP** (non-placeholder): >= 10 words describing next tiny step
3. **DoD** (Definition of Done, non-placeholder): >= 10 words
4. **Scope Guardrails** (in-scope and out-of-scope lists, non-placeholder): each list >= 1 item with >= 5 words per item
5. **Done When** checklist: at least 3 concrete, actionable items, each item >= 6 words; NONE may contain placeholder tokens (TBD/TODO/etc.); each item must be verifiable (YES/NO proof possible)
6. **Last Updated** (valid date, not "TBD" or placeholder):
   - **REQUIRED FORMAT:** YYYY-MM-DD matching regex: `^[0-9]{4}-[0-9]{2}-[0-9]{2}$`
   - **BASIC RANGE VALIDATION:** Month 01–12, day 01–31
   - **OPTIONAL STRICT CHECK (recommended):** Parseable as real calendar date using: `node -e "const s='2026-01-04'; const d=new Date(s+'T00:00:00Z'); const ok=!Number.isNaN(d.valueOf()) && d.toISOString().slice(0,10)===s; console.log(ok?'PASS':'FAIL');"`

**PASS example (Done When item):**
"npm run test passes with 263 SUCCESS and zero new failures."

**FAIL example (Done When item):**
"Tests pass." (only 2 words, not verifiable — which tests? how many? what counts as pass?)

**PASS example (Last Updated date):**
"2026-01-04" (valid YYYY-MM-DD format, month 01, day 04, both in valid ranges)

**FAIL examples (Last Updated date):**
- "2026-1-4" (missing leading zeros, fails regex)
- "2026-99-99" (invalid month 99 and day 99, fails range check)
- "01/04/2026" (wrong format, fails regex)

**Population Gate Enforcement:**

Population Gate is evaluated during Start-of-Session Doc Audit (after existence check). The verdict is printed once per session. Start-of-Session Doc Audit (see consumer Start-Here doc; repo-specific, referenced in copilot-instructions.md) MUST check Population Gate AFTER existence check:
1. Files exist? (<DOCS_ROOT>/project/VISION.md, <DOCS_ROOT>/project/EPICS.md, <DOCS_ROOT>/project/NEXT.md)
2. **Population Gate: PASS or FAIL?** (scan for placeholders + verify minimum content)

If Population Gate **FAIL** → STOP coding, enter Alignment Mode, remediate placeholders (see [alignment-mode.md](alignment-mode.md) "Populate Control Deck" section).

If Population Gate **PASS** → Work state READY, proceed with coding.

---

Last updated: 2026-03-14
