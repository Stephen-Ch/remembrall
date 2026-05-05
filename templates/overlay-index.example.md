# Overlay Index — Consumer Template

> **File Version:** 2026-02-26

## Purpose

Lists the standard consumer overlay files. Copy this file to `<DOCS_ROOT>/overlays/overlay-index.md` and use it as the manifest for your project's overlay set.

## Overlay Review Gate

Before accepting this overlay into the consumer repo:

- Best next step? (YES/NO)
- Confidence: <percentage>%

## Instructions

Copy into consumer repo at `<DOCS_ROOT>/overlays/overlay-index.md` and edit there.  
Do NOT edit this template inside the kit head — it will be overwritten on subtree pull.

## Standard Overlays

| Overlay | Consumer Location | Purpose |
|---------|-------------------|---------|
| stack-profile.md | `<DOCS_ROOT>/overlays/stack-profile.md` | Install/build/test/start commands + tech constraints |
| merge-commands.md | `<DOCS_ROOT>/overlays/merge-commands.md` | Build Gate + Test Gate commands for merge workflow |
| hot-files.md | `<DOCS_ROOT>/overlays/hot-files.md` | Files/folders requiring analysis-first or full-file replacement |
| repo-policy.md | `<DOCS_ROOT>/overlays/repo-policy.md` | Branch policy, PR rules, merge method, naming conventions |
| visibility-contract.md | `<DOCS_ROOT>/overlays/visibility-contract.md` | PR dashboard, branch ledger, next-step, and resume links |

Each overlay has a kit template under `templates/<name>-overlay.example.md`.  
Copy the template, fill in project-specific values, and commit to the consumer repo.
