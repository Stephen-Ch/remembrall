# Visibility Contract — Consumer Template

> **File Version:** 2026-04-14

## Purpose

Declares repo-specific visibility values so session-start and other tools can surface quick links without hardcoding.
Copy this file to `<DOCS_ROOT>/overlays/visibility-contract.md` and fill in your repo's values.

## Instructions

1. Copy to `<DOCS_ROOT>/overlays/visibility-contract.md`
2. Replace placeholder values with real URLs/paths for your repo
3. Delete or leave blank any optional fields you don't use
4. Commit alongside your other overlays

Do NOT edit this template inside the kit head — it will be overwritten on subtree pull.

## Visibility Values

| Field | Value |
|-------|-------|
| **pr_dashboard_url** | `<https://github.com/ORG/REPO/pulls>` |
| **branch_ledger_path** | `<DOCS_ROOT>/project/branches.md` |
| **next_path** | `<DOCS_ROOT>/project/NEXT.md` |
| **pause_path** | `<DOCS_ROOT>/PAUSE.md` |
| **project_board_url** | |
| **local_state_note** | |

### Field Reference

| Field | Required | Meaning |
|-------|----------|---------|
| pr_dashboard_url | Yes | Link to open-PR view |
| branch_ledger_path | Yes | Path to branch classification doc |
| next_path | Yes | Path to active plan / next-step doc |
| pause_path | Recommended | Path to pause/resume handoff doc |
| project_board_url | Optional | Link to external project board |
| local_state_note | Optional | Note, command, or doc path for local stash/worktree state |
