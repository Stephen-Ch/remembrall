# Start Here — [Project Name]

> **Consumer-owned.** This file is repo-specific. Kit rules live in `<DOCS_ROOT>/vibe-coding/`
> and update automatically on subtree pull — do not copy them here.

---

## What this file is for

- Session-start command for this repo (with the actual local path)
- Links to local docs (overlays, control deck, research index)
- Local workspace notes, path quirks, or tool versions
- Local exceptions or overrides to kit defaults

**What does NOT belong here:** gate definitions, session-sequencing rules,
Population Gate text, rerun-trigger commands, Freshness Rule logic, or any
other kit protocol behavior. Those live in `<DOCS_ROOT>/vibe-coding/`.
Copying them here causes cleanup churn after every kit update.

---

## Session Start

    powershell -NoProfile -ExecutionPolicy Bypass -File <SUBTREE>/tools/run-vibe.ps1 -Tool session-start

Chains: kit update → forGPT sync → doc-audit -StartSession → session block. No manual steps needed.

**Manual fallback** (only if `run-vibe.ps1` is unavailable):

    powershell -NoProfile -ExecutionPolicy Bypass -File <SUBTREE>/tools/session-start.ps1

---

## Key Local Docs

| Purpose | Path |
|---------|------|
| Overlay index | `<DOCS_ROOT>/overlays/OVERLAY-INDEX.md` |
| Stack profile | `<DOCS_ROOT>/overlays/stack-profile.md` |
| Merge gates | `<DOCS_ROOT>/overlays/merge-commands.md` |
| Hot files | `<DOCS_ROOT>/overlays/hot-files.md` |
| Repo policy | `<DOCS_ROOT>/overlays/repo-policy.md` |
| Vision | `<DOCS_ROOT>/project/VISION.md` |
| Epics | `<DOCS_ROOT>/project/EPICS.md` |
| Next step | `<DOCS_ROOT>/project/NEXT.md` |
| Research index | `<DOCS_ROOT>/research/ResearchIndex.md` |
| Visibility contract | `<DOCS_ROOT>/overlays/visibility-contract.md` |

---

## Local Notes

<!-- Workspace-specific path notes, tool versions, environment quirks.
     Remove this section if you have nothing repo-specific to add. -->

---

## Local Warnings / Exceptions

<!-- Any deviation from kit defaults — e.g., different Green Gate command,
     branch naming rule, or repo-specific STOP condition.
     Remove this section if you have nothing to add. -->
