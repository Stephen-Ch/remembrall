# X-Branch Findings Template

> **Purpose:** Structured findings report for x-branch experiments.
> **When to use:** Every x-branch must produce a findings artifact using this template before the branch is deleted.
> **Where to save:** `<DOCS_ROOT>/research/` (recommended) or `<DOCS_ROOT>/status/`. If findings warrant indexing, rename to `R-###-<Title>.md` and add to ResearchIndex.md.

---

## Header

    # X-Branch Findings: <branch-name>

    | Field | Value |
    |-------|-------|
    | **Branch** | `x/<name>` |
    | **Date** | YYYY-MM-DD |
    | **PROMPT-ID** | (if applicable, else "N/A") |
    | **Exit State** | Reject / Adopt Conceptually |
    | **Timebox** | 1 session / extended (state duration) |

---

## Sections

### 1. Experiment Question

What question or hypothesis was this experiment testing? One or two sentences.

### 2. Method

What did you actually do? List the key actions taken, files created/modified on the x-branch, and tools used. Keep it factual.

### 3. Evidence

What did you observe? Include relevant output, measurements, screenshots, or file references. Use the same evidence format as [research-standard.md](../standards/research-standard.md#citing-evidence):

    Source: <file-path>:<line-range>

    Command: <command-run>
    Output: <relevant-output>

### 4. Conclusion

What did the experiment prove or disprove? State clearly.

### 5. Keep / Discard

| Item | Keep | Discard | Notes |
|------|------|---------|-------|
| (concept, pattern, approach, file, etc.) | X or — | X or — | Why |

### 6. Next Action

- **If Reject:** State what was learned and why no further action is needed.
- **If Adopt Conceptually:** State the exact NEXT.md entry that must be created for clean re-implementation. Include: story ID (if applicable), scope, and what the normal branch should implement based on these findings.

---

## Promotion Checklist (Optional)

If findings are substantial enough to be indexed as a formal research doc:

- [ ] Rename file to `R-###-<Title>.md`
- [ ] Add required header block from [research-standard.md](../standards/research-standard.md#required-header-block)
- [ ] Add entry to `ResearchIndex.md` with keywords
- [ ] Verify `check-prior-research.ps1` can find it
