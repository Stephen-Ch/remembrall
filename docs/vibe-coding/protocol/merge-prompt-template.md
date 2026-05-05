# Merge Prompt Template — Vibe-Coding Protocol

> **File Version:** 2026-02-26

## Purpose
Define the canonical fast-forward-only merge workflow to ensure clean git history and reproducible merge procedures.

Build and test commands are **not hardcoded** in this template. Read your repo-specific commands from `<DOCS_ROOT>/overlays/merge-commands.md` (preferred) or `<DOCS_ROOT>/overlays/stack-profile.md` (fallback). If these overlays are missing, create them from the kit templates before attempting merge gates.

## REPO ROOT ANCHOR (MANDATORY FIRST COMMANDS)
Run these before any other command, from any shell:
    $root = git rev-parse --show-toplevel
    Set-Location $root
    git rev-parse --show-toplevel
    git rev-parse --show-prefix
    Get-Location
All subsequent git/grep commands must use `git -C "$root" ...` and full canonical paths `<DOCS_ROOT>/project/*`, `<DOCS_ROOT>/testing/*`. Never rely on bare filenames or linkified paths.
For Control Deck checks, use the explicit Population Gate command:
    git -C $root grep -n -i -E "(TBD|TODO|TEMPLATE|PLACEHOLDER|FILL IN|COMING SOON|XXX|FIXME|TO BE DETERMINED|<fill)" -- <DOCS_ROOT>/project/VISION.md <DOCS_ROOT>/project/EPICS.md <DOCS_ROOT>/project/NEXT.md

## Prerequisites
- Work state: COMPLETE (feature branch committed, tests GREEN, build GREEN)
- Feature branch exists and is up-to-date with work
- No merge conflicts expected

## Canonical Merge Sequence

### Step 1: Verify Feature Branch State
On feature branch:

    git status --porcelain
    # Must be clean (or show only intended uncommitted docs if prompt allows)
    
    git log --oneline -1
    # Record commit hash
    
    <your-test-command>        # from <DOCS_ROOT>/overlays/merge-commands.md
    # Must be GREEN
    
    <your-build-command>       # from <DOCS_ROOT>/overlays/merge-commands.md
    # Must be GREEN (classify warnings: NEW vs PRE-EXISTING)

If any gate fails, STOP. Fix on feature branch before proceeding.

### Step 2: Commit Remaining Work (if needed)
If tree shows uncommitted changes that are in-scope:

    git add <files>
    git commit -m "<message>"
    git log --oneline -1
    # Record new commit hash

If tree shows unexpected changes, STOP and report.

### Step 3: Switch to Main
    git checkout main
    git pull --ff-only
    # Must succeed (no merge required)
    # Confirms main synced with origin/main

If pull fails or requires merge, STOP. Resolve conflict separately.

### Step 4: Fast-Forward Merge
    git merge --ff-only feature/<branch-name>

STOP condition: If merge fails with "fatal: Not possible to fast-forward", report:
- Feature branch may not be rebased on latest main
- Merge history diverged
- Propose rebase or investigate

### Step 5: Verify on Main
Run gates again on main:

    <your-test-command>        # from <DOCS_ROOT>/overlays/merge-commands.md
    # Must be GREEN (same test count as feature branch)
    
    <your-build-command>       # from <DOCS_ROOT>/overlays/merge-commands.md
    # Must be GREEN (same bundle size and warnings as feature branch)

If results differ between main and feature branch, STOP and investigate.

### Step 6: Push to Origin
    git push
    # Pushes main to origin/main

### Step 7: Final Verification
    git status -sb
    # Must show: ## main...origin/main (synced, no ahead/behind)
    
    git status --porcelain
    # Must be clean

If tree not clean or branch not synced, STOP and report.

## Required Report Fields

After successful merge, report must include:

### 1. Directory Buckets Summary (NO filenames/paths)
- Narrative MUST list ONLY directory buckets.
- Example: "docs/project: 2 files; app/src/...: 1 file"
- Do not list filenames in narrative; VSCode may linkify file mentions.

### 2. Raw Evidence Outputs (authoritative; paste verbatim)
- `git -C $root diff --name-only`
- `git -C $root ls-files <DOCS_ROOT>/project/VISION.md <DOCS_ROOT>/project/EPICS.md <DOCS_ROOT>/project/NEXT.md <DOCS_ROOT>/testing/test-catalog.md`
- Population Gate command + result
- doc-audit output

### 3. Branch Context
- Feature branch name
- Starting commit (main before merge)
- Ending commit (feature branch HEAD)
- Ahead/behind status before pull

### 4. Merge Result
- Fast-forward confirmation (commit range)

### 5. Test Results
- Feature branch: test count + time
- Main branch: test count + time (must match feature)

### 6. Build Results
- Feature branch: bundle size
- Main branch: bundle size (must match feature)

### 7. Warnings Classification
For each warning, state: NEW or PRE-EXISTING

Example:
- Bundle budget exceeded (78.92 kB) → PRE-EXISTING
- html2canvas ESM warning → PRE-EXISTING

### 8. Push Confirmation
- Push output (objects sent, delta)
- Final git status -sb (confirming sync)

### 9. Commit Hash
- Final commit hash on main after merge

## STOP Conditions

STOP immediately if:
- Feature branch tests/build fail
- Main branch tests/build fail or differ from feature
- git pull --ff-only fails
- git merge --ff-only fails
- git push fails
- Tree dirty after push
- Branch not synced after push
- NEW warnings appear (not present on feature branch)

## Example Merge Prompt

    PROMPT-ID: UX-FEATURE-X-M1-MERGE-TO-MAIN
    
    GOAL: Merge feature/UX-feature-X to main using canonical ff-only workflow.
    
    SCOPE GUARDRAILS:
    - Merge only (no additional implementation)
    - Report required fields per merge-prompt-template.md
    
    TASKS:
    1. Verify feature branch state (clean, tests GREEN, build GREEN)
    2. Checkout main, pull --ff-only
    3. Merge --ff-only feature/UX-feature-X
    4. Verify on main (tests + build match feature)
    5. Push to origin/main
    6. Report: branch context, merge result, tests, build, warnings, push confirmation, commit hash
    
    # END PROMPT

## Integration with Prompt Lifecycle

Merge prompts expect Work state = COMPLETE:
- Feature branch committed
- Tests GREEN
- Build GREEN
- Ready for ff-only merge

If Work state != COMPLETE, merge prompt should STOP.
