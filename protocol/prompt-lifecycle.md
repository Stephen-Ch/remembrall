# Prompt Lifecycle — Vibe-Coding Protocol

## Purpose
Define explicit states for prompts to prevent stale execution, duplicate work, and scope confusion.

## States

### READY
- Prompt prerequisites match current repo state
- Working tree is clean (or prompt explicitly allows dirty)
- Branch context matches prompt expectations
- All required files exist and are readable
- **Story alignment:** Prompt includes Story ID + NEXT STEP citation from `<DOCS_ROOT>/project/NEXT.md` (EXCEPTION: MERGE/CLOSEOUT prompts and docs-only protocol work may omit Story ID if explicitly scoped as "protocol maintenance")

**Protocol maintenance definition:** Prompts scoped exclusively to <DOCS_ROOT>/vibe-coding/protocol/** (canonical) with GOAL explicitly labeled "protocol maintenance". Legacy docs/protocol/** may be edited ONLY for deprecation notices or cross-reference updates; prefer canonical vibe-coding/protocol/** for substantial changes. Does NOT include arbitrary docs edits outside these directories.

### IN-PROGRESS
- Work has started but not yet committed
- Feature branch exists (if required)
- Some files modified but gates not yet run

### COMPLETE
- All work finished on feature branch
- Tests GREEN
- Build GREEN
- Committed (feature branch HEAD)
- Ready for merge

### MERGED
- Work successfully merged to main
- Feature branch can be deleted
- Prompt execution is finished

### OBSOLETE
- Prompt no longer applicable (work already done via different route)
- Repo state has moved past prompt's starting assumptions
- Prompt should not be executed

## STOP Rules

### Before Starting Work
If the prompt's required start state doesn't match current repo state, STOP immediately and report the mismatch:

- Prompt targets a different project/repo than the current workspace → STOP and report the mismatch
- Prompt says "start on feature branch" but you're on main → STOP
- Prompt says "merge to main" but work not yet committed on feature → STOP
- Prompt says "implement feature X" but feature X already exists → mark OBSOLETE and STOP
- Prompt requires clean tree but tree is dirty → STOP (unless prompt explicitly allows dirty state)
- Prompt references files that don't exist → STOP and report missing dependencies
- **Prompt lacks Story ID + NEXT STEP citation** from `<DOCS_ROOT>/project/NEXT.md` → cannot be READY, STOP and request clarification (EXCEPTION: MERGE/CLOSEOUT prompts and docs-only protocol maintenance work may proceed without Story ID if explicitly scoped)

### Exception: Merge/Closeout Prompts
Merge prompts (S2C/M1) and closeout prompts explicitly expect state = COMPLETE. For these prompts ONLY:
- Work state must be COMPLETE (feature branch committed, tests GREEN)
- Otherwise STOP

## How to Decide State

Run these checks in order:

1. **git branch** — Am I on the expected branch?
2. **git status --porcelain** — Is tree clean or dirty?
3. **git status -sb** — Am I ahead/behind/synced with origin?
4. **git log --oneline -5** — Does the prompt's work already exist in history?
5. **grep/semantic search** — Does the feature/file already exist?

If checks reveal prompt is obsolete or already complete, mark state OBSOLETE and STOP. Do NOT "confirm work already done" unless the prompt explicitly requests verification.

## Examples

### Example 1: Implementation Prompt
Prompt says: "Implement feature X on feature/X branch"

Checks:
- git branch → on main (not feature/X)
- State = NOT READY

Action: STOP. Report "Prompt expects feature/X branch but currently on main. Create branch first or correct prompt."

### Example 2: Merge Prompt
Prompt says: "Merge feature/Y to main"

Checks:
- git branch → on feature/Y
- git status --porcelain → clean
- git log --oneline -1 → shows commit with feature Y work
- State = COMPLETE (ready for merge)

Action: Proceed (state matches merge prompt expectations)

### Example 3: Duplicate Work Detection
Prompt says: "Add JSON copy dictionary for tutor text"

Checks:
- grep search → finds qv2-tutor-copy.json already exists
- git log → shows commit "feat: add JSON copy dictionary" from yesterday
- State = OBSOLETE

Action: STOP. Report "Work already complete (commit abc123). Prompt is OBSOLETE."

## Integration with Prompt Review Gate

The Prompt Review Gate must include a "Work state:" line:

    Work state: READY

If Work state != READY and prompt is not a merge/closeout prompt, STOP immediately.

If Work state = COMPLETE and prompt IS a merge/closeout prompt, proceed.
