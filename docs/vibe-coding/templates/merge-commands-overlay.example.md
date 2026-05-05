# Merge Commands — Consumer Overlay Template

> **File Version:** 2026-02-26

## Purpose

Defines the exact Build Gate and Test Gate commands for this repo's merge workflow. The merge prompt template reads these commands instead of hardcoding stack-specific invocations.

## Overlay Review Gate

Before accepting this overlay into the consumer repo:

- Best next step? (YES/NO)
- Confidence: <percentage>%

## Instructions

Copy into consumer repo at `<DOCS_ROOT>/overlays/merge-commands.md` and edit there.  
Do NOT edit this template inside the kit head — it will be overwritten on subtree pull.

---

## Test Gate

Run before merge and again after merge on main:

```
<your-test-command>
```

Must be GREEN (all tests pass). If any test fails, STOP.

## Build Gate

Run before merge and again after merge on main:

```
<your-build-command>
```

Must be GREEN. Classify warnings as NEW or PRE-EXISTING. NEW warnings = STOP.

## Additional Gates (optional)

Add any repo-specific gates below (e.g., lint, type-check, bundle budget):

```
<your-additional-gate-command>
```
