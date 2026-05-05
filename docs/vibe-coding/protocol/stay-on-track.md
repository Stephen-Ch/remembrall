# Stay on Track — Vibe-Coding Protocol

> **File Version:** 2026-01-18

## Purpose
Keep AI focused and prevent scope creep.

## Before Every Response
Did I print the Prompt Review Gate before doing anything? If not, STOP.
Ask yourself:
1. Did I complete Proof-of-Read?
2. Does my plan match the prompt's GOAL exactly?
3. Am I staying within SCOPE GUARDRAILS?
4. Is my confidence ≥95% (≥99% for runtime/code execution)?
5. Am I waiting for the previous Copilot report to be pasted/acknowledged before pushing for a new prompt?
6. If something looks like a bug, have I confirmed the production content counts/state before “fixing” it?

## Red Flags (STOP if any)
- [ ] Adding features not in the prompt
- [ ] Changing files outside scope
- [ ] Skipping Proof-of-Read
- [ ] Confidence < 95% (< 99% for runtime/code execution)
- [ ] Tests/build not run after code changes
- [ ] Making assumptions instead of asking

## Recovery
If you went off track:
1. STOP immediately
2. State what went wrong
3. Propose correction
4. Wait for operator approval

## Scope Boundaries
- **DOCS ONLY** prompts: Do NOT touch app code
- **CODE** prompts: Do NOT add dependencies without approval
- **REFACTOR** prompts: Keep behavior identical
- **S1A sanity check**: If S1A tests pass, STOP — test isn't asserting behavior or you implemented

## Cross-cutting changes require coverage proof

When changing shared patterns (palette CSS variables, voice/tone, layout grids, CTA buttons, disclaimers, UI copy dictionaries, monospace rendering), you MUST verify coverage across the real project routes/screens:

Mandatory route coverage list — use the routes declared in your consumer overlay
(see [project-routes-overlay.example.md](../templates/project-routes-overlay.example.md)):
- /<route-1> (<ComponentName>)
- /<route-2> (<ComponentName>)
- /<feature>/:id (<ComponentName>; include parameterized variants if touched)
- …(one row per route in your app)

For each route, report status exactly as **UPDATED** (specify the change) or **NO CHANGE REQUIRED** (explain why untouched). Mix-and-match language is not allowed; stick to those two values so reviewers can diff coverage quickly.

### Old-pattern search requirement

Before claiming coverage complete:
1. Run a search/grep for the retired pattern (old class, variable, copy, or logic) across the repo.
2. Paste the command, total matches found, and note any intentional leftovers.
3. Confirm duplicates were removed or explicitly parked. If you cannot show the search results, STOP and request a scoped-down prompt.

### UX/copy changes require proof-of-experience

For any user-visible change (copy, layout, tone, CTA labels, disclaimers), include in your completion report:

**Proof-of-Experience Block (Before / After / Where):**
- What the user sees now (quote or DOM snippet)
- What changed (Before → After, tied to the same element)
- Where it appears (list every affected route from your consumer overlay coverage list)
- Visual verification (screenshot description or DOM snippet for layout/visual shifts)

Without proof-of-experience, UX work is incomplete.

### Dev-server interference check

Before running `npm start`, verify whether another dev server is already running. Only stop `node` processes if they are blocking your session:

    Get-Process | Where-Object { $_.ProcessName -eq "node" }

If (and only if) the above shows a conflicting server, stop those processes and retry `npm start`.

## Prompt Compliance Checklist
- [ ] Read all required docs
- [ ] Output Proof-of-Read
- [ ] Output Prompt Review Gate
- [ ] Execute only what's in TASKS
- [ ] Run Green Gate
- [ ] Summarize changes
