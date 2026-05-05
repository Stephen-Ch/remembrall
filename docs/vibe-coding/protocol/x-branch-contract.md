# X-Branch Contract — Vibe-Coding Protocol

> **File Version:** 2026-04-19

## Purpose

An **x-branch** is an isolated experimental branch that exists to learn, not to ship. It provides a named, legitimate path for exploratory work that is uncertain, potentially discardable, and valuable mainly for what it teaches.

X-branches solve a missing category between normal branches (intended to ship) and vague research/spike work that has no home. Without them, experimental work either contaminates main through premature merges or disappears into abandoned branches.

---

## When to Use an X-Branch

Use an x-branch when:

- The work is exploratory, uncertain, or potentially discardable
- The main value is learning, not a deliverable
- A normal `feat/`, `fix/`, or `docs/` branch implies merge intent you don't have
- The experiment exceeds the scope of inline INSTRUMENTATION (CODE-OK) mode

**Do NOT use an x-branch for:**

- Ordinary feature work (use `feat/`)
- Bug fixes (use `fix/`)
- Docs-only work (use `docs/`)
- Small inline diagnostics (use INSTRUMENTATION mode — see threshold table below)
- Any work intended for direct merge

---

## Core Rules

### 1. Naming Convention

    x/<descriptive-name>

Examples:

    x/stories-pilot-blackjack
    x/control-deck-reorg
    x/runtime-spike-save-flow

Do not use vague names. The name must describe the experiment.

### 2. Never Merge

An x-branch is **never** merged into main, develop, or any normal integration branch. No exceptions.

If you find yourself wanting to merge an x-branch, that feeling is the signal to stop and write the findings report. The code on the x-branch is evidence, not deliverable.

### 3. Delete After Findings

After the findings artifact is committed (to the normal branch, not the x-branch), delete the x-branch. X-branches are not archives.

### 4. One-Session Timebox

Default expectation: one session. If the experiment needs more time, Stephen must explicitly approve the extension. At timebox expiry, the branch must produce its findings and be closed.

### 5. Exit States

Every x-branch ends in one of two states:

| Exit State | Meaning | Required Action |
|------------|---------|-----------------|
| **Reject** | Experiment did not produce keepable results | Write findings report, delete x-branch |
| **Adopt Conceptually** | Experiment produced results worth keeping | Write findings report, add binding entry to NEXT.md for clean re-implementation on a normal branch, then delete x-branch |

**"Adopt conceptually" requires a NEXT.md entry.** No closeout without a recorded future action for clean re-implementation. This prevents experiments from being "adopted" in theory but forgotten in practice.

### 6. Findings Artifact

Every x-branch MUST produce a findings artifact using the [X-Branch Findings Template](../templates/x-branch-findings-template.md).

The findings doc is committed to the normal working branch (typically `main` or the current docs branch), NOT to the x-branch itself. Location: `<DOCS_ROOT>/research/` or `<DOCS_ROOT>/status/`, following the same conventions as other research/status docs.

**Promotion to R-###:** If the findings are substantial enough to warrant indexing in ResearchIndex.md, rename the file to `R-###-<Title>.md` and add it to the index. This is recommended but not mandatory for v1 — use judgment based on whether future sessions need to find this research.

---

## Request Gate (Lightweight Preflight)

Before opening an x-branch, answer these five fields:

    1. Why is a normal branch the wrong tool?
    2. What question or hypothesis is this experiment testing?
    3. What does success look like?
    4. What artifact will this produce? (findings report path)
    5. Timebox: one session / extended (Stephen-approved)

An x-branch may be requested by Stephen, Copilot, or a project GPT. The request must include these fields.

---

## Relationship to INSTRUMENTATION Mode

INSTRUMENTATION (CODE-OK) mode and x-branches serve different scales of experimental work. Use this threshold table:

| Situation | Use |
|-----------|-----|
| Need to add a few log lines to observe runtime behavior | INSTRUMENTATION mode |
| Temporary diagnostics, max 20 lines per file, labeled for removal | INSTRUMENTATION mode |
| Experiment exceeds 20 lines per file or spans multiple files | X-branch |
| Testing a structural change (new file layout, architecture, workflow) | X-branch |
| Work may produce code you want to keep conceptually but re-implement cleanly | X-branch |
| Quick inline observation, single session, single file | INSTRUMENTATION mode |

**Key distinction:** INSTRUMENTATION mode produces temporary diagnostics that are removed after evidence capture. X-branches produce experimental implementations that are never merged but may inform future clean implementations.

See [protocol-v7.md § INSTRUMENTATION (CODE-OK) Scope](protocol-v7.md#instrumentation-code-ok-scope-mandatory) for the full INSTRUMENTATION rules.

---

## Branch-Hygiene Treatment

X-branches (`x/` prefix) are reported **separately** from normal unmerged branches in end-of-session hygiene:

- Normal unmerged branches: flagged as potential orphans requiring PRs or documentation
- X-branches: reported with age and findings status (has findings artifact / missing findings)

An x-branch older than 1 session without a findings artifact triggers a **WARN**. This is a visibility signal, not a hard stop.

See [protocol-v7.md § PR / Branch Hygiene Gate](protocol-v7.md#pr--branch-hygiene-gate-mandatory) for the full branch-hygiene rules.

---

## Cross-References

- INSTRUMENTATION (CODE-OK) mode → [protocol-v7.md § INSTRUMENTATION Scope](protocol-v7.md#instrumentation-code-ok-scope-mandatory)
- PR / Branch Hygiene Gate → [protocol-v7.md § PR / Branch Hygiene Gate](protocol-v7.md#pr--branch-hygiene-gate-mandatory)
- Findings template → [templates/x-branch-findings-template.md](../templates/x-branch-findings-template.md)
- Research standard → [standards/research-standard.md](../standards/research-standard.md)
- Branch naming conventions → [portability/user-story-stephen-vibe-coding.md § PR/Branch Hygiene](../portability/user-story-stephen-vibe-coding.md#6-prbranch-hygiene-expectations)
