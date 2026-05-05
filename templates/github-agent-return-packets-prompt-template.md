# GitHub.com Agent Return Packets Prompt Template

**Purpose:** Generate research artifacts (return packets) that inform story selection, risk assessment, and prompt planning—without modifying any code.

---

## When to Use

Trigger a GitHub.com agent return-packet run when:

- **Alignment Mode:** NEXT.md is unclear, stale, or multiple paths exist
- **Hot-file work:** About to touch SignalR, GameRepository, Main.js, or identity code
- **High uncertainty:** Domain is unfamiliar; recent regressions in the area
- **Regression risk:** Recent incidents in the area (check postmortems)
- **Cross-system work:** Change spans backend + frontend + Mongo

---

## Inputs Required (Checklist)

Before running the prompt:

- [ ] Repo is accessible to GitHub.com agent
- [ ] Topic areas identified (1–3 topics; e.g., "SignalR diagnostics", "MongoDB concurrency")
- [ ] Desired output filenames decided (use `return-packet-YYYY-MM-DD-<slug>.md` convention)
- [ ] Date known (for filename + report headers)
- [ ] Owner has reviewed VISION.md, EPICS.md, NEXT.md for current context

---

## Template Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `{{DATE}}` | Date for filename and header (YYYY-MM-DD) | `2026-01-09` |
| `{{TOPIC_1}}` | First research topic | `CI-meaningful multiplayer regression tests` |
| `{{TOPIC_2}}` | Second research topic (optional) | `SignalR diagnostics logging plan` |
| `{{TOPIC_3}}` | Third research topic (optional) | `MongoDB concurrency risk map` |
| `{{OUTPUT_1}}` | First output filename | `return-packet-2026-01-09-ci-multiplayer-regression-epic-003.md` |
| `{{OUTPUT_2}}` | Second output filename (optional) | `return-packet-2026-01-09-signalr-diagnostics-td-diag-001.md` |
| `{{OUTPUT_3}}` | Third output filename (optional) | `return-packet-2026-01-09-mongodb-concurrency-td-be-002.md` |
| `{{ID_1}}` | Topic ID or Story ID | `EPIC-003` |
| `{{ID_2}}` | Topic ID or Story ID (optional) | `TD-DIAG-001` |
| `{{ID_3}}` | Topic ID or Story ID (optional) | `TD-BE-002` |

---

## Default 3-Report Mode

Use this when you need comprehensive research across multiple topics.

### Ready-to-Paste GitHub.com Agent Prompt

```
PROMPT-ID: RP-{{DATE}}-{{ID_1}}-{{ID_2}}-{{ID_3}}

## Goal
Produce 3 dated research reports (return packets) under <DOCS_ROOT>/status/.
Research ONLY—do NOT modify any runtime code.

## Required Reading (quote 1-2 lines from each to prove you read them)
- <DOCS_ROOT>/project/VISION.md
- <DOCS_ROOT>/project/EPICS.md
- <DOCS_ROOT>/project/NEXT.md
- <DOCS_ROOT>/testing/test-catalog.md
- <DOCS_ROOT>/project/<YourProject>-KB.md

## Output Files
Create these 3 files under <DOCS_ROOT>/status/:
1. {{OUTPUT_1}}
2. {{OUTPUT_2}}
3. {{OUTPUT_3}}

## Required Sections Per Report

Each report MUST include:

### Header
- Title: Return Packet: <Topic Name> (<ID>)
- Date: {{DATE}}
- Purpose: 1-2 sentence summary
- Audience: Who should read this

### Required Reading Quotes
- Quote 1-2 lines from each doc you read (with line numbers)

### Executive Summary
- Current state (what exists today)
- Gap (what's missing or risky)
- Goal (what we want to achieve)
- Non-goal (what we are NOT doing)
- Recommended first step (single tiny action)

### Current State Map
- Code topology: which files, methods, lines
- Tables with: File | Method | Lines | Purpose | Safety status

### Risk Analysis
- Identify race conditions, missing coverage, contract gaps
- Severity: Critical / High / Medium / Low
- Impact: What breaks if this fails

### Smallest-First Test/Story List
- Prioritized list (Priority 1 = smallest, most impactful)
- Each item: ID, title, estimated effort, files touched

### Best Next Tiny Step
- Single sentence: the next action Copilot should take
- Must be testable (RED→GREEN or docs evidence)

### Citations
- Every claim must include file path + line numbers

## Constraints
- Research only; do NOT modify runtime code
- Do NOT create branches or commits
- Use markdown tables for structured data
- Keep each report under 600 lines
- Focus on actionable findings, not exhaustive documentation

END PROMPT
```

---

## 1-Report Mode (Short)

Use this for focused research on a single topic.

### Ready-to-Paste GitHub.com Agent Prompt

```
PROMPT-ID: RP-{{DATE}}-{{ID_1}}

## Goal
Produce 1 dated research report (return packet) under <DOCS_ROOT>/status/.
Research ONLY—do NOT modify any runtime code.

## Required Reading (quote 1-2 lines from each to prove you read them)
- <DOCS_ROOT>/project/VISION.md
- <DOCS_ROOT>/project/EPICS.md
- <DOCS_ROOT>/project/NEXT.md
- <DOCS_ROOT>/testing/test-catalog.md
- <DOCS_ROOT>/project/<YourProject>-KB.md

## Output File
Create: <DOCS_ROOT>/status/{{OUTPUT_1}}

## Required Sections

### Header
- Title: Return Packet: <Topic Name> ({{ID_1}})
- Date: {{DATE}}
- Purpose: 1-2 sentence summary
- Audience: Who should read this

### Required Reading Quotes
- Quote 1-2 lines from each doc you read (with line numbers)

### Executive Summary
- Current state | Gap | Goal | Non-goal | Recommended first step

### Current State Map
- Code topology with file/method/line tables

### Risk Analysis
- Identify gaps; severity and impact

### Smallest-First Test/Story List
- Prioritized list with effort estimates

### Best Next Tiny Step
- Single testable action

### Citations
- File path + line numbers for all claims

## Constraints
- Research only; no runtime code changes
- Keep report under 400 lines
- Focus on actionable findings

END PROMPT
```

---

## After the Agent Completes

1. **Review outputs** — Verify return packets exist in <DOCS_ROOT>/status/
2. **Update NEXT.md** — Add "Inputs/Research" bullet linking to the return packets
3. **Hand off to ChatGPT** — ChatGPT converts return packets into tiny-step prompts
4. **Execute via Copilot** — Copilot runs prompts with Prompt Review Gate

---

## Example Return Packets

See these real examples for format reference:

- [return-packet-2026-01-09-ci-multiplayer-regression-epic-003.md](../../status/return-packet-2026-01-09-ci-multiplayer-regression-epic-003.md)
- [return-packet-2026-01-09-signalr-diagnostics-td-diag-001.md](../../status/return-packet-2026-01-09-signalr-diagnostics-td-diag-001.md)
- [return-packet-2026-01-09-mongodb-concurrency-td-be-002.md](../../status/return-packet-2026-01-09-mongodb-concurrency-td-be-002.md)
