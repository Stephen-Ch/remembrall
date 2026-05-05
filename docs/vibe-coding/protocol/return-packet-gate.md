# Return Packet Gate — Vibe-Coding Protocol

> **File Version:** 2026-02-26

## Purpose

The Return Packet Gate is a research checkpoint that produces dated status documents (return packets) before starting high-risk or uncertain work. Return packets inform story selection, risk assessment, and prompt planning without modifying runtime code.

---

## What Is a Return Packet?

A **return packet** is a markdown research artifact stored in `<DOCS_ROOT>/status/` with the naming convention:

```
return-packet-YYYY-MM-DD-<topic-slug>.md
```

Return packets contain:

- **Required reading quotes** — Proof the agent read project context
- **Executive summary** — Current state, gap, goal, non-goal, first step
- **Code topology map** — File/method/line tables showing current implementation
- **Risk analysis** — Gaps, severity, impact
- **Smallest-first test/story list** — Prioritized work items
- **Best next tiny step** — Single actionable next move
- **Citations** — File paths + line numbers for all claims

Return packets are **research-only**; they never contain runtime code changes.

### Execution Policy

**GitHub.com Agent** is the designated creator of return packets in `<DOCS_ROOT>/status/`. This is the **only** allowed research artifact creation by that agent — no ad-hoc research docs, no unstructured reports. All other research output from GitHub.com Agent must be delivered in chat.

This policy aligns with the Agent Safety Policy in [working-agreement-v1.md](working-agreement-v1.md).

---

## When to Run the Return Packet Gate

### Mandatory Triggers

Run the gate when ANY of these conditions apply:

| Trigger | Description |
|---------|-------------|
| **Alignment Mode** | NEXT.md is unclear, stale, or conflicting with repo state |
| **Hot-file work** | About to touch any file listed in `<DOCS_ROOT>/overlays/hot-files.md` (consumer-defined). If hot-files.md is missing, create it from `templates/hot-files-overlay.example.md` before proceeding with hot-file work. |
| **High uncertainty** | Domain is unfamiliar; no prior experience with this area |
| **Regression risk** | Recent incidents or postmortems in this area |
| **Cross-system work** | Change spans backend + frontend + database |

### Optional Triggers

Consider running the gate for:

- Large refactors (>5 files)
- New feature areas not covered by existing tests
- Work touching auth/identity flows
- Changes to real-time messaging payload contracts

---

## Acceptance Criteria (What "Good" Looks Like)

A return packet passes review when:

- [ ] **Exists in <DOCS_ROOT>/status/** with correct naming convention
- [ ] **Has required reading quotes** with line numbers
- [ ] **Executive summary** answers: current state, gap, goal, non-goal, first step
- [ ] **Code map** uses tables with file/method/line columns
- [ ] **Risk analysis** has severity ratings (Critical/High/Medium/Low)
- [ ] **Smallest-first list** is prioritized (Priority 1 = smallest, most impactful)
- [ ] **Best next tiny step** is a single testable action
- [ ] **Citations** exist for every claim (file path + line numbers)
- [ ] **No runtime code changes** — research-only
- [ ] **Under 600 lines** — focused, not exhaustive

---

## 4-Party Handoff Flow

The Return Packet Gate operates across 4 parties with clear responsibilities:

### Party Roles

| Party | Role | Responsibility |
|-------|------|----------------|
| **Stephen** | Owner/Decider | Names goal, constraints, scope; approves outputs |
| **ChatGPT** | Planner/Prompt Writer | Produces GitHub agent prompt using template; converts return packets into tiny-step prompts |
| **GitHub.com Agent** | Researcher | Executes return-packet prompt; creates <DOCS_ROOT>/status/ artifacts |
| **Copilot VS Code** | Executor | Runs tiny-step prompts; commits code; applies Green Gate |

### Handoff Sequence

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Stephen identifies goal/constraints                          │
│    "I want to understand MongoDB concurrency risks before       │
│     making changes to GameStateService"                         │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. ChatGPT produces GitHub agent prompt                         │
│    Uses template from:                                          │
│    <DOCS_ROOT>/vibe-coding/templates/github-agent-return-packets-      │
│    prompt-template.md                                           │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. GitHub.com Agent executes prompt                             │
│    Creates return packet(s) in <DOCS_ROOT>/status/                     │
│    Research only — no runtime code changes                      │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. ChatGPT converts return packets into prompts                 │
│    - Reviews return packet findings                             │
│    - Updates NEXT.md with Inputs/Research links                 │
│    - Generates tiny-step prompts for Copilot                    │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. Copilot VS Code executes prompts                             │
│    - Runs Prompt Review Gate                                    │
│    - Applies Green Gate (tests pass)                            │
│    - Commits code changes                                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## How to Reference Return Packets in NEXT.md

When return packets exist, NEXT.md MUST link to them under an "Inputs/Research" section:

```markdown
## Inputs/Research

Return packets informing this work:
- [return-packet-YYYY-MM-DD-<topic-slug>.md](../status/return-packet-YYYY-MM-DD-<topic-slug>.md)
```

This creates traceability from the active story back to the research that informed it.

---

## Template Location

Ready-to-paste prompts for GitHub.com agent:

**[github-agent-return-packets-prompt-template.md](../templates/github-agent-return-packets-prompt-template.md)**

Contains:
- 3-report mode (comprehensive research)
- 1-report mode (focused single topic)
- Template variables for customization

---

## Example Return Packets

Example naming patterns (replace placeholders with your project's topics):

| File | Topic | Date |
|------|-------|------|
| `return-packet-YYYY-MM-DD-realtime-debug-001.md` | Real-time messaging diagnostics | *(your date)* |
| `return-packet-YYYY-MM-DD-data-integrity-001.md` | Data layer concurrency/integrity | *(your date)* |
| `return-packet-YYYY-MM-DD-ci-regression-001.md` | CI regression test coverage | *(your date)* |

---

## Integration with Other Protocol Docs

- **[alignment-mode.md](alignment-mode.md)** — Return Packet Gate is triggered when Alignment Mode detects hot-file or high-uncertainty work
- **[required-artifacts.md](required-artifacts.md)** — NEXT.md must link to return packets under "Inputs/Research"
- **[working-agreement-v1.md](working-agreement-v1.md)** — Defines 4-party roles and handoff responsibilities
- **[protocol-v7.md](protocol-v7.md)** — Master protocol; Return Packet Gate is a pre-flight research step
