# Research Documentation Standard

> **Scope:** Portable across all repos using the vibe-coding bundle.
> **Authority:** Canonical source for research doc structure and evidence format.

---

## Purpose

This standard defines the required structure for research documents
(`R-###-<Title>.md`). It complements the canonical protocol rules for
research modes and confidence thresholds, which live in
[protocol-v7.md](../protocol/protocol-v7.md).

---

## Required Header Block

Every research document MUST start with this header:

    # R-###: <Title>

    | Field | Value |
    |-------|-------|
    | **Date** | YYYY-MM-DD |
    | **PROMPT-ID** | (if applicable, else "N/A") |
    | **Area** | (e.g., Scoring, UI, Database, CI) |
    | **Status** | DRAFT / COMPLETE |
    | **Confidence** | ##% |
    | **Evidence Links** | (file paths, PR numbers, or "see below") |

Field definitions:
- **Date:** When research began (ISO format).
- **PROMPT-ID:** The prompt that triggered this research (if any).
- **Area:** Functional area being investigated.
- **Status:** DRAFT while gathering evidence; COMPLETE when conclusions final.
- **Confidence:** Percentage confidence in conclusions (see thresholds below).
- **Evidence Links:** Quick pointers to key evidence (detailed evidence in body).

---

## Confidence Thresholds

Rule: Apply tiered confidence thresholds before moving from research to implementation.

See: [protocol-v7.md § No Guessing / Tiered Confidence Gate](../protocol/protocol-v7.md#no-guessing--tiered-confidence-gate-mandatory)

Summary for research docs:
- **95% minimum** for low-risk scope (docs, tests, reports).
- **99% minimum** for production/runtime code changes.
- Below threshold -> remain in RESEARCH-ONLY mode; no code changes.

Every research doc must end with a confidence statement:

    Confidence: ##%
    Basis: <1-2 sentences>
    Ready to proceed: YES / NO

---

## Required Sections

Every research doc MUST include these sections (in order):

### 1. Issue Summary
- **Symptom:** What is observed (exact behavior).
- **Expected:** What should happen instead.
- **Impact:** Who/what is affected.

### 2. Reproduction Steps
Numbered steps to reproduce. Include environment details, test data
identifiers, and exact sequence of actions.

### 3. Evidence Gathering
How evidence was collected: commands used (with output), file paths and
line numbers, query results (anonymized if needed).

### 4. Competing Hypotheses
At least 2 hypotheses with evidence for, evidence against, and a
falsification test for each.

### 5. What Would Change My Mind
Specific observations that would shift diagnosis.

### 6. Decision / Conclusion
What the evidence proves, recommended action, remaining unknowns.

### 7. Confidence Statement
See format above.

---

## Citing Evidence

### File References

    Source: Controllers/GradeController.cs:L145-L160

### Command Evidence

    Command: Select-String -Path "*.cs" -Pattern "CalculateScore"
    Output:
      GradeController.cs:145:    var score = CalculateScore(rubric);

### Database Evidence

    SELECT StudentId, Score FROM Submissions WHERE LessonId = 123;
    -- Result: 15 rows, scores range 0-100

---

## Research Modes (Canonical Reference)

Rule: RESEARCH-ONLY permits evidence gathering without code edits; INSTRUMENTATION permits temporary diagnostics only under strict guardrails.

See:

- **RESEARCH-ONLY mode:**
  [RESEARCH-ONLY Command Lock](../protocol/protocol-v7.md#research-only-command-lock-mandatory)
- **INSTRUMENTATION (CODE-OK) mode:**
  [INSTRUMENTATION Scope](../protocol/protocol-v7.md#instrumentation-code-ok-scope-mandatory)

---

## Prior Research Lookup (Canonical Reference)

Rule: Every RESEARCH-ONLY output MUST include a prior research lookup section before starting new investigation.

See: [protocol-v7.md § Prior Research Lookup](../protocol/protocol-v7.md#c-prior-research-lookup-mandatory)

---

## Indexing Rule (Canonical Reference)

Rule: Every new research document MUST be added to ResearchIndex.md in the same commit.

See: [protocol-v7.md § Research Saved + Indexed](../protocol/protocol-v7.md#research-saved--indexed-mandatory)

---

## ResearchIndex.md Format (Canonical Reference)

The index MUST be structured for keyword/semantic search so that
Copilot, ChatGPT, and `check-prior-research.ps1` can find prior work
efficiently. Each entry uses this format:

```markdown
### R-###: <Title>

| Field | Value |
|-------|-------|
| **Date** | YYYY-MM-DD |
| **PROMPT-ID** | KIT-xxx-### or N/A |
| **Area** | Scoring, UI, Database, CI, Protocol, etc. |
| **Status** | DRAFT / COMPLETE |
| **Confidence** | ##% |
| **Keywords** | keyword1, keyword2, keyword3 |
| **Summary** | One sentence describing findings |
| **File** | `<DOCS_ROOT>/research/R-###-<Title>.md` |
```

**Keyword rules:**
- Include 3–8 keywords per entry.
- Use lowercase, comma-separated.
- Include synonyms and acronyms (e.g., `NRE, null reference, NullReferenceException`).
- Include file names, class names, or feature names when relevant.

**Why keywords matter:** The `check-prior-research.ps1` tool greps the
index before every research session. Sparse keywords = missed matches =
duplicate research.

---

## Document Lifecycle

1. **Create:** Start with DRAFT status; fill header + sections as evidence arrives.
2. **Update:** Add evidence, refine hypotheses, update confidence.
3. **Complete:** Set status to COMPLETE when conclusions are final.
4. **Archive:** Completed research remains in place; do not delete.

**Addendum Rule:** If new information surfaces for a COMPLETE doc, create a
new doc (R-###-Addendum-<Original>) rather than modifying conclusions.

---

## Quick Checklist

Before marking research COMPLETE:

- [ ] Header block filled (all 6 fields)
- [ ] Reproduction steps documented
- [ ] At least 2 competing hypotheses listed
- [ ] "What would change my mind" section populated
- [ ] Confidence meets threshold (95% docs / 99% runtime) with basis stated
- [ ] Added to ResearchIndex.md
