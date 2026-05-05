# Repo Policy — Consumer Overlay Template

> **File Version:** 2026-02-26

## Purpose

Declares the consumer repo's branch policy, PR rules, merge method, and naming conventions. Protocol gates reference this overlay for repo-specific workflow decisions.

## Overlay Review Gate

Before accepting this overlay into the consumer repo:

- Best next step? (YES/NO)
- Confidence: <percentage>%

## Instructions

Copy into consumer repo at `<DOCS_ROOT>/overlays/repo-policy.md` and edit there.  
Do NOT edit this template inside the kit head — it will be overwritten on subtree pull.

---

## Branch Policy

| Setting | Value |
|---------|-------|
| Default branch | `main` |
| Feature branch pattern | `feature/<scope>-<short-description>` |
| X-branch pattern | `x/<experiment-name>` (never merged — see [x-branch-contract.md](../protocol/x-branch-contract.md)) |
| Merge method | Fast-forward only (`--ff-only`) |
| Delete branch after merge | Yes / No |

## PR Rules

| Rule | Value |
|------|-------|
| Required reviewers | `<count>` |
| Required checks | `<list CI checks>` |
| Auto-merge allowed | Yes / No |

## Return Packet Naming Convention

```
return-packet-YYYY-MM-DD-<topic-slug>.md
```

Stored in: `<DOCS_ROOT>/status/`

## Commit Message Convention

```
<type>: <short description> (<scope>)
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
