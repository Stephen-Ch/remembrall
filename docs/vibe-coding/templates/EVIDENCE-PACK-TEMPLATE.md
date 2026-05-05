# Evidence Pack Template

> **When to use:** Confidence <95% on any diagnosis or proposed fix.  
> **Rule:** No code changes until this pack is complete and confidence ≥95%.  
> **Full standard:** See [research-standard.md](../standards/research-standard.md) for header format, required sections, and indexing rules.

---

## Prior Research Lookup (MANDATORY)

**Commands used:**
```powershell
# Example — adapt search terms to your investigation
Select-String -Path "<DOCS_ROOT>/research/*.md" -Pattern "<your-term>"
Select-String -Path "<DOCS_ROOT>/research/ResearchIndex.md" -Pattern "<your-term>"
```

**Matching document IDs found:**
| ID | Title | Relevant? | Read? |
|----|-------|-----------|-------|
| R-### | <!-- title --> | Yes/No | Yes/No |
| <!-- or --> | | | |
| _None found_ | — | — | — |

**Summary:** <!-- "Reviewed R-001, R-005; no prior work on this exact issue" OR "No relevant prior research found" -->

---

## Issue Summary

**Ticket/ID:** (e.g., PR #27, EPIC-005-S02, ad-hoc investigation)

**Symptom (exact):**
<!-- What is observed? Be specific. -->

**Expected behavior:**
<!-- What should happen instead? -->

---

## Reproduction Steps

1. <!-- Step 1 -->
2. <!-- Step 2 -->
3. <!-- Observe: [symptom] -->

**Environment:**
- OS: 
- .NET Version: 
- IIS: Express / Full
- Browser: 
- Date/Time: 

---

## Source Locations

| File | Line(s) | Relevance |
|------|---------|-----------|
| <!-- path --> | <!-- L### --> | <!-- why this file matters --> |

**Grep/Search Proof:**
    <!-- paste command + output -->

---

## Hard Evidence (at least one required)

Choose the appropriate evidence type:

- [ ] **DB SELECT output** — Query + results showing actual data state
- [ ] **Runtime capture** — Console output, debugger screenshot, or log excerpt
- [ ] **ELMAH/Error log** — Stack trace or error entry
- [ ] **Request/Response payload** — Network tab capture or Fiddler trace
- [ ] **Diff proof** — `git diff` showing code differences between working/broken

**Evidence:**
    <!-- paste here -->

---

## Competing Hypotheses

| # | Hypothesis | Evidence For | Evidence Against | Falsification Test |
|---|------------|--------------|------------------|-------------------|
| 1 | <!-- hypothesis --> | <!-- what supports it --> | <!-- what contradicts it --> | <!-- how to disprove --> |
| 2 | <!-- hypothesis --> | <!-- what supports it --> | <!-- what contradicts it --> | <!-- how to disprove --> |

---

## What Would Change My Mind

<!-- List specific observations that would shift your diagnosis -->

1. If I observed X, I would conclude Y instead.
2. If query Z returned different results, hypothesis 1 would be falsified.

---

## Confidence Statement

**Confidence:** ___%

**Basis:** <!-- 1-2 sentences explaining why -->

**Ready to proceed:** YES / NO

---

## Decision

**Root cause:** <!-- if confidence ≥95% -->

**Recommended action:** <!-- next step -->
---

## Calibration Examples (When is confidence <95%?)

### Example 1: Missing Runtime Proof / Cannot Reproduce

| Field | Value |
|-------|-------|
| **What we know** | Error message says "NullReferenceException in GradeAssessment" |
| **What we don't know** | Which code path triggers it; what input data causes it |
| **Smallest next proof** | Add `Console.WriteLine` or debugger breakpoint; reproduce with known test data |
| **Why confidence <95%** | Cannot propose a fix without knowing the null variable and trigger condition |

### Example 2: Config Ambiguity (Multiple Connection Systems)

| Field | Value |
|-------|-------|
| **What we know** | App has two connection systems: <YourModel> (EF) and <YourConnectionName> (raw ADO.NET) |
| **What we don't know** | Which one is actually used at runtime for the failing operation |
| **Smallest next proof** | Query both connection strings; add logging to capture which path executes |
| **Why confidence <95%** | Fixing the wrong connection config will have no effect |

### Example 3: External DLL / Stale Binary Risk

| Field | Value |
|-------|-------|
| **What we know** | Code references enum `syntax_Cause_and_Effect` from parseTaggerEnums DLL |
| **What we don't know** | Whether the deployed DLL contains that enum value |
| **Smallest next proof** | Run `Get-FileHash bin/parseTaggerEnums.dll`; compare timestamps; inspect with ILSpy or reflection |
| **Why confidence <95%** | If the binary is stale, the fix requires rebuilding/deploying the DLL, not changing calling code |