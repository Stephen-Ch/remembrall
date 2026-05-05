# Stack Profile — Consumer Overlay Template

> **File Version:** 2026-02-26

## Purpose

Declares the consumer repo's technology stack, standard commands, and environment constraints. Gates and templates read this overlay instead of hardcoding stack-specific commands.

## Overlay Review Gate

Before accepting this overlay into the consumer repo:

- Best next step? (YES/NO)
- Confidence: <percentage>%

## Instructions

Copy into consumer repo at `<DOCS_ROOT>/overlays/stack-profile.md` and edit there.  
Do NOT edit this template inside the kit head — it will be overwritten on subtree pull.

---

## Standard Commands

| Action | Command | Notes |
|--------|---------|-------|
| Install dependencies | `<your-install-command>` | |
| Build | `<your-build-command>` | |
| Test | `<your-test-command>` | |
| Start (dev) | `<your-start-command>` | |
| Lint | `<your-lint-command>` | Optional |

## Environment Constraints

| Constraint | Value |
|------------|-------|
| OS | Windows / macOS / Linux |
| Shell minimum | PowerShell 5.1 |
| Runtime | `<your-runtime-and-version>` |
| Secrets path | `<path-to-secrets-or-env-file>` |

## Tech Stack Summary

- **Framework:** `<framework-and-version>`
- **Language:** `<language-and-version>`
- **Database:** `<database-if-applicable>`
- **Real-time:** `<messaging-layer-if-applicable>`
- **CI:** `<ci-platform>`
