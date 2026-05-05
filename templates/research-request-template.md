# Research Request Template

> **Purpose:** Structured handoff format for requesting research from ChatGPT (or any web-capable agent) when Copilot cannot verify external facts locally.
>
> **When to use:**
> - Confidence is below 95% and local evidence is insufficient to raise it.
> - The question requires web access or deep research that Copilot lacks.
> - You need a reproducible, auditable research packet back (not a vague answer).
>
> **Rule:** This template reinforces the existing escalation rules. If confidence < 95%, you MUST stop implementation. Do not guess. Use this template to request the missing evidence.

---

## Header (Prompt Review Gate)

```
PROMPT-ID: <PROJECT>-<AREA>-<SLUG>-<SEQ>
TYPE: Research-only
SCOPE: <repo or directory scope>
BRANCH: <current branch>
```

## Research Request

**What (research question):**
<!-- One clear question. What do you need to know? -->

**Why (decision it will unblock):**
<!-- What implementation decision is blocked until this is answered? -->

**Constraints (what NOT to do / scope):**
<!-- e.g., "Do not propose code changes", "Limit to official docs", "Kit repo only" -->

**Sources required:**
<!-- web | official docs | codebase | npm registry | GitHub issues | etc. -->

**Deliverables (file(s) to create + exact target path):**
<!-- e.g., "Create R-042-Widget-API-Options.md in <DOCS_ROOT>/research/" -->

**Acceptance checks (objective, measurable):**
<!-- e.g., "Answer includes version numbers for the last 3 releases", "Cites at least 2 official sources" -->

**Stop conditions (what triggers STOP + ask Stephen):**
<!-- e.g., "If no official source confirms, STOP and report inconclusive" -->

---

## Evidence Pack (returned by researcher)

### Commands / searches run

```
<!-- List exact commands, URLs visited, search queries used -->
```

### Key excerpts / quotes

<!-- Quote the relevant findings. Include source URL or doc path for each. -->

| # | Finding | Source |
|---|---------|--------|
| 1 | <!-- excerpt --> | <!-- URL or file:line --> |
| 2 | <!-- excerpt --> | <!-- URL or file:line --> |

### Links / citations

- <!-- Full URLs or repo-relative paths to sources consulted -->

---

## Confidence Gate (after research)

```
Confidence: <percentage>%
Justification: <why this level — cite evidence above>
```

- If confidence >= 95%: research is complete. Proceed to implementation prompt.
- If confidence < 95%: flag remaining gaps and escalate to Stephen.
