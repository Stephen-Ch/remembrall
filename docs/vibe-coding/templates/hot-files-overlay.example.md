# Hot Files — Consumer Overlay Template

> **File Version:** 2026-02-26

## Purpose

Lists files and folders that require extra caution: analysis-first workflow, full-file replacement, or a Return Packet Gate before touching. The Return Packet Gate and other protocol gates reference this overlay to decide when to trigger research checkpoints.

## Overlay Review Gate

Before accepting this overlay into the consumer repo:

- Best next step? (YES/NO)
- Confidence: <percentage>%

## Instructions

Copy into consumer repo at `<DOCS_ROOT>/overlays/hot-files.md` and edit there.  
Do NOT edit this template inside the kit head — it will be overwritten on subtree pull.

---

## Hot Files (check these first)

| File / Folder | LOC | Purpose | Why Hot |
|---------------|-----|---------|---------|
| `<path/to/file>` | `<count>` | `<description>` | `<reason: high churn / >300 LOC / coordination / identity>` |
| `<path/to/file>` | `<count>` | `<description>` | `<reason>` |

## Hot Folders

Directories where any change should trigger careful review:

- `<path/to/folder/>` — `<reason>`
- `<path/to/folder/>` — `<reason>`

## Criteria for Adding Files

Add a file to this list when ANY of these apply:

- **>300 LOC** — Too large for safe inline edits
- **High churn** — Frequently changed, high merge-conflict risk
- **Coordination role** — Orchestrates multiple subsystems
- **Identity/auth** — Security-sensitive paths
- **Real-time messaging** — Payload contract changes affect multiple consumers
