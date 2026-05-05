# Visibility Contract Standard (v1)

> **Scope:** Portable across all repos using the vibe-coding bundle.
> **Authority:** Canonical source for the Visibility Contract field definitions and ownership rules.

---

## Purpose

A **visibility contract** is a small set of repo-local values that answer the five questions every session participant asks:

1. What PRs are open right now?
2. What is the next planned step?
3. Where is the branch ledger?
4. Where do I resume safely?
5. Where should I look for local-only cleanup state?

The kit defines the **standard** (field names, surfacing rules, ownership).
Consumer repos provide the **values** (URLs, paths, notes).

---

## Non-Goals

This is a visibility contract, not a project-management framework.

- No dashboard artifact that duplicates NEXT.md, PAUSE.md, or branch ledgers
- No automation of branches, stashes, worktrees, or PRs
- No hardcoded repo-specific URLs, reviewer names, or branch names in the kit
- No ongoing manual bookkeeping beyond filling in the overlay once and updating when values change

---

## Fields

### Required

| Field | Type | Meaning |
|-------|------|---------|
| **pr_dashboard_url** | URL | Link to the repo's open-PR view (e.g., GitHub `/pulls`) |
| **branch_ledger_path** | Path | Repo-relative path to the branch classification / active-branches doc |
| **next_path** | Path | Repo-relative path to the active plan or next-step doc (typically NEXT.md) |

### Strongly Recommended

| Field | Type | Meaning |
|-------|------|---------|
| **pause_path** | Path | Repo-relative path to the pause/resume handoff doc (typically PAUSE.md) |

### Optional

| Field | Type | Meaning |
|-------|------|---------|
| **project_board_url** | URL | Link to an external project board (GitHub Projects, Azure Boards, etc.) |
| **local_state_note** | Text, command, or path | Free-form note, shell command, or doc path for local stash/worktree audit state |

---

## Ownership

| Aspect | Owner |
|--------|-------|
| Field definitions, surfacing rules, template | **Kit** (`standards/`, `templates/`, `tools/`) |
| Field values (URLs, paths, notes) | **Consumer repo** (`<DOCS_ROOT>/overlays/visibility-contract.md`) |

The kit MUST NOT contain repo-specific URLs, paths to real consumer docs, or real reviewer/branch names.

Consumer repos fill in the overlay once, update when values change, and commit it alongside other overlays.

---

## Consumer Location

Consumer repos declare their values in:

    <DOCS_ROOT>/overlays/visibility-contract.md

Where `<DOCS_ROOT>` is the repo's documentation root (`docs/`, `docs-engineering/`, or equivalent).

The kit provides a fill-in template at `templates/visibility-contract-overlay.example.md`.

---

## Surfacing

Populated visibility values are surfaced automatically by `tools/session-start.ps1` during the session audit block. Only fields with real (non-placeholder) values are printed —  unfilled fields are suppressed.

If the overlay file is missing or no values are populated, session-start prints at most a short pointer and does not emit an empty or misleading block.

End-of-session surfacing is not required in v1.

---

## Placeholder Detection

A value is considered **unfilled** if it:
- is empty or whitespace-only
- contains `<` and `>` (template variable pattern)
- matches any of: `TODO`, `TBD`, `PLACEHOLDER`, `FILL`, `TEMPLATE`, `example.com`, `example.org`

Unfilled values MUST NOT appear in session-start output.
