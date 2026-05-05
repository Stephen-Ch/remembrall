# Terminology Template

## Purpose

Prevent model drift by locking UI copy to a dictionary. Never infer data shape from labels.

**Rule:** "Terminology caused model drift; lock UI copy to a dictionary; never infer data shape from labels."

---

## Terminology Mapping Table

Fill this table BEFORE changing vocabulary or UI labels:

| UI Term / Label | Data Key / Property Chain | Behavioral Definition | Allowed Synonyms | Notes / Migration Impact |
|-----------------|---------------------------|----------------------|------------------|-------------------------|
| (example) Category | categories[] | Top-level grouping of questions | Ideal, Value Group | None - consistent across UI |
| (example) Question | categories[].followUps[] | Individual question item | Position, TLQ | Storage uses "followUps" but UI shows "Questions" |

---

## Rules

1. **Terminology caused model drift; lock UI copy to a dictionary; never infer data shape from labels.**
2. UI terms are for user communication only; data keys are for implementation
3. Mapping must be explicit and documented here
4. Changes to UI terms do NOT change data structure
5. Changes to data structure require migration and version bump

---

## When to Use This Template

- Before renaming UI labels or product language
- When adding new concepts to the product
- When documentation and code use different terms for the same thing
- After discovering terminology confusion in postmortems

---

## Example: AcmeApp

See `<DOCS_ROOT>/project/CONTENT-RULES.md` (lines 5-27) for the filled-in version of this template.
