# Vibe-Coding Protocol Migration Instructions

**Version:** v7.2.19  
**Last Updated:** 2026-03-14

## Purpose
Guide for migrating vibe-coding protocol v7 to other projects (new projects or upgrading from older protocol versions).

## Core Principle
The protocol is **project-agnostic** by design. Gates, sequencing rules, and enforcement mechanisms never change. Only project-specific context (hot files, routes, tech stack) requires customization.

---

## Breaking Changes (v7.2.19)

- **Confidence line canonicalized to `Confidence: <percentage>%`** across Prompt Review Gate + templates. Old forms (`HIGH/MEDIUM/LOW`, `(0-100)`) are deprecated. After pulling this kit version, run `doc-audit -StartSession` and grep for old confidence formats (should return 0 hits).

---

## Legacy Consumer One-Time Migration Pilot

PROMPT-ID: KIT-LEGACY-CONSUMER-MIGRATION-PILOT-DOCS-AND-DRY-RUN-001

### Why this exists

Some existing consumers may still have older local `tools/kit-update.ps1` versions where the default ref was `main`.
Because `tentacles on` maps to `run-vibe -Tool start`, and start can invoke `kit-update` when lag is detected, those legacy consumers must not use old `tentacles on` as the first migration step.

### Mandatory warning

For existing consumers, do **not** run old `tentacles on` first.
First perform a one-time manual subtree migration to `release/consumer-payload`.

### One-time migration command pattern

Use this pattern:

```powershell
git subtree pull --prefix=<DOCS_ROOT>/vibe-coding `
  https://github.com/Stephen-Ch/vibe-coding-kit.git release/consumer-payload --squash
```

Common prefix examples:

- Standard consumer path: `docs/vibe-coding`
- LessonWriter-shaped path: `docs-engineering/vibe-coding`

### Verification Checklist (post-migration)

All items must pass before returning to normal `tentacles on` usage:

1. Required runtime files are present under `<DOCS_ROOT>/vibe-coding/`:
   - `tools/run-vibe.ps1`
   - `tools/session-start.ps1`
   - `tools/kit-update.ps1`
   - `tools/sync-forgpt.ps1`
   - `README.md`
   - `QUICKSTART.md`
2. Forbidden files are absent from the migrated subtree:
   - `REPORT-KIT-*`
   - `docs/research/*`
   - `kit-workspace/*`
   - consumer postmortem templates/artifacts and internal release-test harness files
3. `<DOCS_ROOT>/vibe-coding/tools/kit-update.ps1` default ref is `release/consumer-payload`.
4. `run-vibe -Tool session-start` completes without HARD STOP after migration.

### Stop Conditions (pilot migration)

Stop immediately if any condition is true:

- Working tree is dirty before migration
- Current branch is not the planned pilot branch
- Subtree source/ref is not `release/consumer-payload`
- Forbidden files appear after subtree pull
- `session-start` hard-stops after migration
- Any step would require force-push

### Rollback and governance note

- Perform migration on an isolated pilot branch in the consumer repo.
- Do not merge the migration branch into the consumer default branch until validation passes.
- If validation fails, revert the migration commit on the pilot branch and reassess.

### Dry-Run Checklist for the future pilot prompt

Use this checklist before touching any real consumer:

1. Identify the consumer `DOCS_ROOT` and exact subtree prefix.
2. Identify current installed kit state (version and local `kit-update.ps1` ref default).
3. Create an isolated migration branch in that consumer.
4. Run one-time subtree pull from `release/consumer-payload`.
5. Verify required/forbidden file assertions and script defaults.
6. Run `run-vibe -Tool session-start` and `run-vibe -Tool doc-audit -Mode Consumer -StartSession`.
7. Commit evidence only if all checks pass.

### Explicit scope statement

This document section is planning and instruction only.
No real consumer migration was executed while creating this update.

---

## Migration Checklist

### Phase 1: Copy Core Bundle (Always Identical)

Copy these files/directories unchanged from source project:

```
<DOCS_ROOT>/vibe-coding/protocol/
├── protocol-v7.md                    # Core rules (gates, sequencing, enforcement)
├── copilot-instructions-v7.md        # Copilot-specific protocol (CUSTOMIZE later)
├── required-artifacts.md             # Doc Audit rules (CUSTOMIZE examples)
├── alignment-mode.md                 # Alignment Mode workflow
├── verification-mode.md              # Verification Mode workflow
├── prompt-lifecycle.md               # State definitions (READY/IN-PROGRESS/etc)
├── stay-on-track.md                  # Cross-cutting coverage rules
├── working-agreement-v1.md           # 3-party sequencing rules
├── merge-prompt-template.md          # Merge/rollback template
└── templates/                        # Control Deck templates
    ├── VISION.template.md
    ├── EPICS.template.md
    └── NEXT.template.md

<DOCS_ROOT>/Start-Here-For-AI.md             # Consumer thin shell — CREATE from templates/start-here-template.md (do NOT copy)
<DOCS_ROOT>/vibe-coding/VIBE-CODING.VERSION.md   # Version tracking
.github/copilot-instructions.md       # Enforcer (points to protocol, CUSTOMIZE path)

### Doc Audit (Low-Noise v1) — Portable Install

- Purpose: Control Deck placeholder scan (<DOCS_ROOT>/project/* only) and NEXT freshness when PRs include non-docs changes.
- Copy these into the target repo:
   - <DOCS_ROOT>/vibe-coding/tools/doc-audit.ps1
   - scripts/doc-audit.ps1
   - docs/vibe-coding.config.json
   - .github/workflows/doc-audit.yml
- Run locally: pwsh ./scripts/doc-audit.ps1
- CI behavior:
   - Placeholder scan is Control Deck only (<DOCS_ROOT>/project/VISION.md, EPICS.md, NEXT.md)
   - NEXT.md update is required only when the PR changes any path outside doc-only prefixes (default: docs/)
```

### Phase 2: Run Project Assessment Prompt

Before customizing, run the diagnostic prompt below to identify what needs adaptation.

### Phase 3: Customize Project-Specific References

**A) Remove project-specific references:**

Search and replace in copied files:
- File headers: `"— ExampleProject"` → `"— [Your Project Name]"`
- Route references: `src/app/app.routes.ts` → `[your routes file path]`
- Example content: Replace ExampleProject VISION/EPICS examples with placeholders

**B) Keep copilot-instructions-v7.md portable; use an overlay for project-specific context:**

Do NOT edit `copilot-instructions-v7.md` directly — it is part of the kit head and will be overwritten on subtree pull. Instead, create a consumer overlay:

1. Copy `templates/copilot-instructions-overlay.example.md` to `<DOCS_ROOT>/overlays/copilot-instructions-overlay.md`
2. Fill in project-specific context (framework, hot files, routes, build commands)
3. Reference the overlay from `.github/copilot-instructions.md`

See [templates/copilot-instructions-overlay.example.md](templates/copilot-instructions-overlay.example.md) for the full template.

**C) Create consumer overlays from kit templates:**

Do NOT edit kit head files — customize via overlays. Copy each template and fill in project-specific values:

| Kit Template | Copy To | Purpose |
|-------------|---------|----------|
| `templates/overlay-index.example.md` | `<DOCS_ROOT>/overlays/overlay-index.md` | Overlay manifest |
| `templates/stack-profile-overlay.example.md` | `<DOCS_ROOT>/overlays/stack-profile.md` | Install/build/test/start commands + constraints |
| `templates/merge-commands-overlay.example.md` | `<DOCS_ROOT>/overlays/merge-commands.md` | Build Gate + Test Gate commands |
| `templates/hot-files-overlay.example.md` | `<DOCS_ROOT>/overlays/hot-files.md` | Hot files requiring analysis-first workflow |
| `templates/repo-policy-overlay.example.md` | `<DOCS_ROOT>/overlays/repo-policy.md` | Branch policy, PR rules, merge method |

The Return Packet Gate reads hot-files.md to decide triggers. The merge prompt template reads merge-commands.md for build/test commands. Both fall back gracefully if overlays are missing, but creating them up front is recommended.

2. **Hot Files** (files >300 LOC or high churn):
   ```markdown
   ## [Project] Hot Files (Two-Path Rule)
   Files requiring analysis-first OR full-file replacement:
   - [path/to/router.ts] - routing config, 350 LOC
   - [path/to/store.ts] - global state, 400 LOC
   - [path/to/main-component.ts] - coordinator, 320 LOC
   ```

3. **Route Coverage Table Pattern** (cross-cutting changes):
   ```markdown
   - Route Coverage Table using [your project] routes from `[routes file path]`:
     | Route | Status | Evidence |
     | ----- | ------ | -------- |
     | [route1] | UPDATED / NO CHANGE REQUIRED | [reason] |
   ```

4. **Content/Build Pipeline** (if applicable):
   ```markdown
   - Content pipeline: [source files] → [build scripts] → [output artifacts]
   ```

**C) Update protocol-v7.md cross-cutting section:**

Line 234 references ExampleProject routes. Update with your project's route structure:
```markdown
For ANY cross-cutting change, your completion report MUST include a route coverage table using the actual [Project] routes from `[routes file path]`:
```

**D) Update required-artifacts.md examples:**

Lines 90-107 use ExampleProject as <DOCS_ROOT>/project/VISION.md example. Replace with generic examples or your project's actual purpose statement.

**E) Create consumer Start-Here from the thin-shell template:**

Do NOT copy `Start-Here-For-AI.md` from another consumer repo. Consumer Start-Here files may contain large amounts of kit protocol text that immediately goes stale on the next kit update.

Instead:

```powershell
Copy-Item "<DOCS_ROOT>/vibe-coding/templates/start-here-template.md" `
          "<DOCS_ROOT>/Start-Here-For-AI.md"
```

Fill in `[Project Name]` and replace all `<DOCS_ROOT>` and `<SUBTREE>` placeholders with this repo's actual paths. Make no other content changes.

**Do not add to Start-Here:** gate definitions, session-sequencing rules, rerun-trigger commands, Population Gate instructions, or any other kit protocol behavior. Those live in `<DOCS_ROOT>/vibe-coding/`. Copying them in creates cleanup work after every kit update.

### Phase 4: Create Control Deck

**If migrating to NEW project (no existing docs):**

1. Copy templates to `<DOCS_ROOT>/project/`:
   ```
   cp <DOCS_ROOT>/vibe-coding/protocol/templates/VISION.template.md <DOCS_ROOT>/project/VISION.md
   cp <DOCS_ROOT>/vibe-coding/protocol/templates/EPICS.template.md <DOCS_ROOT>/project/EPICS.md
   cp <DOCS_ROOT>/vibe-coding/protocol/templates/NEXT.template.md <DOCS_ROOT>/project/NEXT.md
   ```

2. Populate with actual content (work with product owner/Stephen to fill sections)

3. Verify Population Gate PASS:
   ```bash
   # Run placeholder scan
   grep -iE '(TBD|TODO|TEMPLATE|PLACEHOLDER|FILL IN|COMING SOON|XXX|FIXME|TO BE DETERMINED|<fill)' <DOCS_ROOT>/project/VISION.md <DOCS_ROOT>/project/EPICS.md <DOCS_ROOT>/project/NEXT.md
   
   # Should return no matches (exit code 1 means PASS)
   ```

**If migrating to EXISTING project (has <DOCS_ROOT>/project/):**

1. Verify existing VISION/EPICS/NEXT meet required-artifacts.md thresholds:
   - <DOCS_ROOT>/project/VISION.md sections >= 25 words each
   - <DOCS_ROOT>/project/EPICS.md descriptions >= 15 words with goals + success criteria
   - <DOCS_ROOT>/project/NEXT.md NEXT STEP >= 10 words, DoD >= 10 words, Done When items >= 6 words

2. If thresholds not met, expand content before running Doc Audit

### Phase 5: Update Enforcer

Edit `.github/copilot-instructions.md` to point to new protocol location:

```markdown
# Copilot Instructions — [Your Project] (Enforcer)

Before any work:
1) Read `<DOCS_ROOT>/Start-Here-For-AI.md`
2) Follow `<DOCS_ROOT>/vibe-coding/protocol/protocol-v7.md` + `<DOCS_ROOT>/vibe-coding/protocol/copilot-instructions-v7.md`

Non-negotiables (every response):
1) Proof-of-Read (file + quote + "Applying: rule")
2) Prompt Review Gate (what / best next step YES/NO / confidence)
3) Stop on error (non-zero exit → stop, propose smallest fix, wait)
4) Green Gate for code prompts:
   - [your test command, e.g., npm test]
   - [your build command, e.g., npm run build]
```

### Phase 6: Run Initial Doc Audit

After migration complete, verify setup with Start-of-Session Doc Audit:

1. Open Copilot in new project
2. Paste: "Run Start-of-Session Doc Audit"
3. Verify PASS (all 5 checks green)
4. If FAIL, enter Alignment Mode to remediate

---

## Upgrading from Older Protocol Version

**If target project has vibe-coding v6.x or earlier:**

1. Archive old protocol:
   ```bash
   mkdir -p docs/archive/deprecated/
   mv <DOCS_ROOT>/vibe-coding/protocol docs/archive/deprecated/protocol-v6
   ```

2. Copy v7.1.0 bundle fresh (Phase 1 above)

3. Migrate any project-specific customizations from archived version:
   - Check old copilot-instructions for hot files list
   - Check old protocol for route coverage patterns
   - Preserve any working agreements specific to team

4. Update Control Deck if format changed (e.g., <DOCS_ROOT>/project/NEXT.md gained "Done When" section in v7)

5. Run Doc Audit to verify Population Gate with new thresholds

**Breaking changes v6 → v7:**
- Population Gate now requires word-count thresholds (not just "substantive content")
- 3-Party Approval Gate added (alignment-mode.md canonical)
- Prompt Review Gate now 4 lines (was 3 in some v6 variants)
- Command Lock sequencing clarified (reads allowed after gate, before Proof-of-Read)

---

## Project Assessment Diagnostic Prompt

Run this prompt in target project BEFORE migration to identify customization needs:

\`\`\`markdown
PROMPT-ID: VIBE-CODING-V7-PROJECT-ASSESSMENT-001

GOAL: Diagnose project-specific context needed for vibe-coding v7 migration

SCOPE:
- Read codebase structure to identify hot files (>300 LOC, routing/state/coordination)
- Read routing config to identify cross-cutting coverage requirements
- Read package.json + test/build config to identify tech stack
- Read existing <DOCS_ROOT>/project/ (if exists) to assess Control Deck population
- Output assessment report with customization checklist

TASKS:
A) Identify framework + tech stack from package.json dependencies
B) Locate routing configuration file (search for app.routes.ts, routes.tsx, app/\*\*/route.ts patterns)
C) Identify hot files (>300 LOC in src/) focusing on:
   - Routing/navigation coordinators
   - Global state management
   - Main layout/shell components
   - Content pipeline build scripts
D) Check if <DOCS_ROOT>/project/ exists:
   - If YES: read VISION/EPICS/NEXT and assess word counts vs v7 thresholds
   - If NO: note Control Deck creation required
E) Identify cross-cutting patterns (search src/ for shared CSS vars, component libraries, copy dictionaries)
F) Output assessment report with:
   - Framework/stack summary
   - Routes file path + route list
   - Hot files list (path + LOC + purpose)
   - Control Deck status (exists/needs-creation/needs-expansion)
   - Cross-cutting patterns requiring coverage tables
   - Customization checklist (what to update in overlay + protocol-v7.md)

# END PROMPT
\`\`\`

**Assessment Report Format:**

\`\`\`markdown
# Vibe-Coding v7 Migration Assessment — [Project Name]

## Tech Stack
- Framework: [name + version]
- State: [management approach]
- Routing: [library + config file path]
- Build: [tool + commands]
- Tests: [framework + command]

## Hot Files (Candidates for Two-Path Rule)
| File | LOC | Purpose | Churn Risk |
|------|-----|---------|-----------|
| [path] | [count] | [description] | [HIGH/MEDIUM/LOW] |

## Routing Structure
Routes file: `[path to routes config]`

Routes requiring cross-cutting coverage:
- [route1]
- [route2]
...

## Control Deck Status
- `<DOCS_ROOT>/project/VISION.md`: [EXISTS (meets thresholds) / EXISTS (needs expansion) / MISSING]
- `<DOCS_ROOT>/project/EPICS.md`: [EXISTS / MISSING]
- `<DOCS_ROOT>/project/NEXT.md`: [EXISTS / MISSING]

Population Gate blockers:
- [list any sections below word-count thresholds or containing placeholders]

## Cross-Cutting Patterns
Patterns requiring route coverage tables:
- [e.g., Shared CSS variables in styles/theme.scss]
- [e.g., UI component library in src/components/shared]
- [e.g., Copy dictionary in src/i18n/en.json]

## Customization Checklist

### copilot-instructions-v7.md
- [ ] Do NOT edit directly — create a consumer overlay at `<DOCS_ROOT>/overlays/copilot-instructions-overlay.md` instead
- [ ] Copy `templates/copilot-instructions-overlay.example.md` and fill in project-specific context
- [ ] Add hot files, routes, and build commands to the overlay

### Consumer Overlays
- [ ] Copy all templates from `templates/*-overlay.example.md` to `<DOCS_ROOT>/overlays/`
- [ ] Fill in `stack-profile.md` with install/build/test/start commands
- [ ] Fill in `merge-commands.md` with Build Gate and Test Gate commands
- [ ] Fill in `hot-files.md` with files >300 LOC or high churn
- [ ] Fill in `repo-policy.md` with branch/PR/merge conventions

### protocol-v7.md
- [ ] Update cross-cutting route reference (line 234): replace `src/app/app.routes.ts` with `[your routes file]`
- [ ] Update file header (line 1): "— ExampleProject" → "— [Your Project]"

### required-artifacts.md
- [ ] Update <DOCS_ROOT>/project/VISION.md examples (lines 90-107): replace ExampleProject examples with [your project purpose] or generic placeholders

### Start-Here-For-AI.md
- [ ] Create from `templates/start-here-template.md` (do NOT copy from another consumer repo)
- [ ] Fill in `[Project Name]` and replace all `<DOCS_ROOT>` and `<SUBTREE>` placeholders
- [ ] Do not add kit protocol text — keep thin; all protocol behavior lives in `<DOCS_ROOT>/vibe-coding/`

### Control Deck (<DOCS_ROOT>/project/)
- [ ] [Create VISION/EPICS/NEXT from templates OR expand existing to meet thresholds]

## Migration Readiness
- **Ready to migrate?** [YES (all customization identified) / NO (blockers below)]
- **Blockers:** [list any missing info or decisions needed]
\`\`\`

---

## Key Invariants (Never Change Across Projects)

These elements are **project-agnostic** and must remain identical:

### Gates
- Prompt Review Gate format (4 lines: What, Best next step, Confidence, Work state)
- Vision & User Story Gate requirements (Story ID, NEXT STEP citation)
- Proof-of-Read format (file + quote + "Applying: rule")
- Population Gate thresholds (word counts: 25/10/6)
- 3-Party Approval Gate checklist structure

### Sequencing
- Command Lock (no terminal/edits/searches before Prompt Review Gate)
- Session flow (Prompt Review Gate → Proof-of-Read → Doc Audit → work)
- Doc Audit rerun triggers (Control Deck changes since last audit)

### Prompt Classes
- FORMAL WORK PROMPT (requires PROMPT-ID, allows execution)
- CONVERSATIONAL REQUEST (no PROMPT-ID, read-only tools only)

### State Definitions
- READY, IN-PROGRESS, COMPLETE, MERGED, OBSOLETE (from prompt-lifecycle.md)

### Enforcement Rules
- Green Gate (tests + build before commit)
- Hot File Protocol (analysis-first OR full-file replacement)
- Cross-cutting coverage (route table required)
- Scope discipline (stay inside SCOPE GUARDRAILS)

---

## Tunables (Customize Per Project)

These elements **must be adapted** to each project:

### Context
- Project name (file headers)
- Framework/tech stack (copilot-instructions)
- Architecture patterns (copilot-instructions)

### Hot Files
- List of files >300 LOC or high churn
- Routing coordinators
- State management files
- Main layout components

### Routes
- Routes file path
- Route list for coverage tables
- Parameterized route patterns

### Cross-Cutting Patterns
- Shared component libraries
- CSS variable systems
- Copy dictionaries
- Build pipeline artifacts

### Control Deck Content
- <DOCS_ROOT>/project/VISION.md (product purpose, unique to each project)
- <DOCS_ROOT>/project/EPICS.md (feature roadmap, unique to each project)
- <DOCS_ROOT>/project/NEXT.md (current story, unique to each project)

---

## Common Migration Pitfalls

1. **Forgetting to update copilot-instructions hot files** → AI doesn't know which files need analysis-first
2. **Leaving project-specific routes in protocol-v7.md** → cross-cutting coverage tables show wrong routes
3. **Copying Control Deck templates without populating** → Doc Audit FAIL on placeholders
4. **Not running assessment prompt first** → miss project-specific patterns requiring coverage
5. **Changing gate formats** → breaks enforcement consistency across projects
6. **Updating thresholds per project** → Population Gate becomes subjective

---

## Support

For migration questions or protocol issues:
1. Check protocol-reassessment-post-sweep-2026-01-05.md for known gaps
2. Run assessment prompt to diagnose customization needs
3. Verify Control Deck population before first Doc Audit

---

**Last Updated:** 2026-02-26  
**Protocol Version:** v7.2.7
