# Prompt Template

> Copy this template for every prompt. Fill in each section; delete unused optional sections.

---

## Header

```
PROMPT-ID: <PROJECT>-<AREA>-<SLUG>-<SEQ>
TYPE: Research-only | Implementation (docs-only) | Implementation (code + docs)
SCOPE: <repo or directory scope>
BRANCH: <target branch or "new branch off main">
```

## Goal

One or two sentences describing the desired outcome.

### Non-goals (optional)

- Anything explicitly out of scope for this prompt.

## Constraints

- Docs-only / code-only / both.
- ASCII punctuation only (no em dashes, curly quotes).
- Any repo-specific rules (e.g., "do not change audit behavior").

## Confidence Gate (answer BEFORE doing any work)

1. Is this the best next prompt right now? (yes/no)
2. Confidence: <percentage>% that executing this is correct and safe.
3. Risks/unknowns (max 5).
4. If confidence <95%: STOP and output a single best-next RESEARCH-ONLY prompt.
5. If confidence >=95%: proceed with implementation.

## Pre-flight

1. Confirm repo root and branch.
2. Baseline: git status, git diff.
3. Any other preconditions (file exists, dependency installed, etc.).

## Steps

> For Research-only prompts: list research questions and expected outputs.
> For Implementation prompts: list concrete file changes.

### A) <First change group>

1. Step detail.
2. Step detail.

### B) <Second change group> (optional)

1. Step detail.

## Validation / Gates

1. Run gate command(s) and confirm PASS.
2. Manual checks (e.g., verify output, review diff).

## Commit (Implementation only)

- Commit message: `<type>: <short description>`
- Push branch.

## Completion Report (REQUIRED)

Include in every response:

- PROMPT-ID
- Branch name
- Files changed (paths)
- Command results summary (gate PASS/FAIL, warnings)
- Proof of scope: `git diff --name-only origin/main...HEAD`
