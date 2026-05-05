# Working Agreement v1 — Vibe-Coding Protocol

> **File Version:** 2026-04-28

## Primary Priorities (Non-Negotiable)

These govern all GPT interactions with Stephen. No exceptions.

- **Prompt-only mode:** When Stephen indicates "prompt-only" (explicitly or by context), output ONLY a single Copilot prompt. Do NOT give Stephen instructions to run terminal/git commands. Do NOT provide multi-step human runbooks.
- **One prompt at a time:** Provide exactly one Copilot prompt, then STOP and wait for Copilot feedback before drafting another prompt.
- **Tiny-step TDD default:** Every prompt must require verification first (test/gate/grep), then the smallest possible change, then re-run verification. If unsure, produce a research-only prompt rather than guessing.
- **Stephen cognitive style:** Default ≤10 lines of explanation outside the prompt. Bullets over paragraphs. No clutter. No motivational filler.

**Vibe Skills note:** vibe-plan, vibe-hunt, and vibe-check are shorthand labels for existing protocol workflows, not a separate process or relaxed gate model.

## Response Pattern

| Pattern | Context | GPT Action |
|---------|---------|------------|
| **A** | Prompt request while in prompt-only | Output a single prompt block only. Nothing else. |
| **B** | Conceptual question while in prompt-only | Answer in ≤8 lines, then offer: "If you want, I'll write the next Copilot prompt." |
| **C** | Not in prompt-only mode | Brief guidance allowed, but still bias toward producing the next Copilot prompt. |

**Enforcement:** Apply tiered confidence thresholds (≥95% docs/research, ≥99% runtime); if below threshold, STOP and output a research-only prompt. See: [protocol-v7.md § No Guessing / Tiered Confidence Gate](protocol-v7.md#no-guessing--tiered-confidence-gate-mandatory).

### Prompt Output Contract (Mandatory Formatting)

When Stephen asks for a prompt, the response MUST follow these rules exactly:

- Output exactly one fenced code block and nothing else.
- Use plain triple backticks with `text` (i.e., ` ```text `).
- Do not include fence metadata such as `id="..."`.
- The opening fence must be on its own line.
- The closing fence must be on its own line.
- All prompt content must be inside the block.

This contract applies whenever the AI produces a prompt for Stephen to copy (Response Pattern A and C prompt output). Explanation or commentary outside the code fence violates Pattern A.

> **Scope note:** The "ZERO fenced code blocks" rule in [hard-rules.md](hard-rules.md) and [protocol-v7.md](protocol-v7.md) applies to **completion reports**, not to prompt output governed by this contract.

---

## 4-Party Workflow

This project uses a 4-party collaboration model:

| Party | Role | Responsibility |
|-------|------|----------------|
| **Stephen** | Owner/Decider | Names goals/constraints; approves outputs; final decision authority |
| **ChatGPT** | Planner/Prompt Writer | Produces GitHub agent prompts; converts return packets into tiny-step prompts; updates NEXT.md |
| **GitHub.com Agent** | Researcher | Executes return-packet prompts; creates <DOCS_ROOT>/status/ research artifacts; no runtime code changes |
| **Copilot VS Code** | Executor | Runs tiny-step prompts; applies Prompt Review Gate + Green Gate; commits code |

See [return-packet-gate.md](return-packet-gate.md) for the handoff sequence diagram.

## Agent Safety Policy (MANDATORY)

**Purpose:** Prevent "agent went rogue" incidents by enforcing clear role boundaries.

### GitHub.com Agent Scope

GitHub.com agents (Copilot Workspace, GitHub Actions with agent mode) perform **code changes only**, with one exception:

- **Return Packets:** GitHub.com Agent may create return-packet markdown files in `<DOCS_ROOT>/status/` as defined in [return-packet-gate.md](return-packet-gate.md). Return packets are the **only** allowed file creation by GitHub.com Agent in research mode.
- All other research and reporting uses **chat mode** or **local read-only scans**.
- Never request "create a .md file" when you mean "report findings in chat" — unless it is a return packet following the Return Packet Gate.

### Report-Only Handshake (REQUIRED for read-only tasks)

When requesting a read-only report (research, audit, investigation):

1. **Prompt must include:** `Scope: Read-only investigation; no code edits.`
2. **Agent first line must be:** `ACK: READ-ONLY`
3. **If agent cannot comply** (e.g., prompt requests edits), agent must STOP and clarify

### Anti-Patterns (NEVER DO)

| Bad Pattern | Why It's Wrong | Correct Alternative |
|-------------|----------------|--------------------|
| Ad-hoc "Create a <DOCS_ROOT>/status/report.md" for research | Creates unstructured file when only analysis needed | "Report findings in chat" (or use Return Packet Gate for structured research) |
| Research prompt without READ-ONLY scope | Agent may infer edits are allowed | Add explicit scope guardrail |
| Code agent for audit/investigation | Wrong tool for job | Use chat mode or Copilot conversational |

> **Note:** Creating a return packet via the [Return Packet Gate](return-packet-gate.md) is NOT an anti-pattern — it is the designated research artifact workflow for GitHub.com Agent.

### Scope Enforcement

- **READ-ONLY tasks:** grep_search, read_file, list_dir, git log/status/diff — no edits, no commits
- **CODE tasks:** May edit files, run tests, commit — requires full Prompt Review Gate

## Operator Responsibilities
1. Provide prompts as single fenced code blocks ending with `# END PROMPT`
2. Review changes before committing
3. Keep prompts small and focused (one story/task per prompt)

## AI Responsibilities
1. Proof-of-Read
2. Prompt Review Gate
3. Stay in scope
4. If drift triggers occur, STOP and execute Reset Ritual before answering Best next step / Confidence
5. If North Star is unknown, STOP before Best next step / Confidence and request the Control Deck sentence
6. Stop on error
7. Green Gate (code prompts)
8. Summarize files touched
9. Maintain single-thread sequencing: one prompt → one report → next prompt (never overlap)

## Step Closure Gate

Copilot must not generate the next working prompt until a complete Step Closure Block is present and Safe to proceed is YES. If Step Closure Block is missing or Safe to proceed is NO, Copilot must return closure actions only, not a new work plan.

Step Closure Block:

- Commands executed:
- Result (PASS/WARN/FAIL):
- Files changed:
- Classification:
  - Generated (forGPT/*):
  - Canonical (research, REPORT, NEXT.md, protocol):
- Working tree state:
  - clean / dirty:
  - if dirty, intentional:
- Required action:
  - commit / revert / park / none:
- Safe to proceed:
  - YES / NO:

Clarifications:
- Generated files are non-authoritative and may be overwritten or discarded at step boundary.
- Canonical files must be preserved by commit, stash/park, or explicit keep decision before proceeding.
- Safe to proceed must be NO if canonical changes are unresolved.
- This is a Copilot/executor responsibility, not an added Stephen checklist.
- A file is not generated just because a script produced it. Classification is by purpose, not origin.

| Classification | Examples |
|---|---|
| **Canonical** | `docs/status/REPORT-*.md`, `docs/research/R-*.md`, `NEXT.md`, `protocol/*.md`, `VIBE-CODING.VERSION.md`, `working-agreement-v1.md` |
| **Generated** | `docs/forGPT/*`, `VIBE-KIT-SNAPSHOT.md`, `VERSION-MANIFEST.md` (when produced by sync-forgpt), any file whose sole output is `sync-forgpt.ps1` |

## Startup Command

Operator phrase:
"tentacles on"

Meaning:
Run:
`.\run-vibe.ps1 -Tool start`

Behavior:
- Executes session-start
- Auto-applies kit-update if needed
- Auto-syncs packet if safe
- Stops on ConsumerDrift BLOCKED
- Outputs final READY / BLOCKED state

Clarification:
Operator should not use multi-step prompts for startup. "tentacles on" is the only required startup instruction.

## Startup Repair Sequence

After session-start, when `session-start.ps1` reports WARN or BLOCKED items, Copilot must never ask Stephen "what do you want to fix?" or "which issue should we address first?". Copilot must classify the output and propose one ordered repair sequence immediately.

**Required repair order:**
1. **BLOCKED gates first** — address the gate that blocks trust in repo state before any other.
2. **WARN gates second** — in the order they appear in the audit output.
3. **Packet/forGPT sync last** — only after canonical docs are settled.
4. **Re-run session-start** — this is the verification step. Do not propose feature work until the re-run returns no BLOCKED gates and all previously-failing WARN items are either resolved or explicitly accounted for.
5. **Propose feature work** — only after a clean audit.

**Clarifications:**
- If multiple BLOCKED gates exist, address the one that blocks trust in repo state first (e.g., kit drift before packet staleness).
- If a decision genuinely requires Stephen (e.g., which story to prioritize), ask one specific question only — not an open-ended "what do you want to do?".
- Generated packet sync (forGPT) must wait until canonical docs are stable.
- This is a Copilot responsibility, not an added Stephen checklist.

## Timeboxing + Pivot Rule (MANDATORY for environmental issues)

When blocked by environmental issues (network, TLS, proxy, machine-specific), follow the canonical timebox procedure (20-minute / 3-variation hard limit, then document and pivot).

→ [protocol-v7.md § Environmental Debug Timebox](protocol-v7.md#environmental-debug-timebox-mandatory)

## External Research Escalation (When Copilot Lacks Web Access)

- If the task requires **external facts** (platform quirks, library docs, standards, time-sensitive info) and Copilot cannot browse the web: **STOP**.
- Before escalating, confirm the answer cannot be derived from repo evidence (grep, file reads, local scripts).
- Request a **GPT Web/Deep Research** packet with exactly:
  1. 1–3 precise questions
  2. The decision the research will unlock
  3. Repo evidence already checked (commands + outcomes)
- Do **not** proceed with implementation until the research packet is returned OR Stephen explicitly waives it.
- Non-external problems (paths, refs, grep, local scripts) must be solved locally — no escalation.

## Communication Protocol
- AI asks clarifying questions BEFORE starting work, except for the canonical startup phrase "tentacles on".
- When the operator says "tentacles on", Copilot must execute `run-vibe -Tool start` without asking clarifying questions.
- If confidence is below the applicable threshold (≥95% docs/research, ≥99% runtime), AI must STOP, explain why, and switch to RESEARCH-ONLY mode. See: [protocol-v7.md § No Guessing / Tiered Confidence Gate](protocol-v7.md#no-guessing--tiered-confidence-gate-mandatory) and [protocol-v7.md § RESEARCH-ONLY Command Lock](protocol-v7.md#research-only-command-lock-mandatory).
- Before drafting implementation/setup prompts in likely prior-work areas, AI must run the triggered Prior Parked-Work Lookup Gate in [protocol-v7.md](protocol-v7.md) and default to audit/reuse when related parked work exists.

## Confidence Gate (Dual-Agent Requirement)

Rule: Both ChatGPT (Planner) and Copilot (Executor) MUST enforce tiered confidence thresholds (≥95% docs/research, ≥99% runtime); below threshold, STOP and enter RESEARCH-ONLY mode.

See: [protocol-v7.md § No Guessing / Tiered Confidence Gate](protocol-v7.md#no-guessing--tiered-confidence-gate-mandatory) and [protocol-v7.md § RESEARCH-ONLY Command Lock](protocol-v7.md#research-only-command-lock-mandatory).

## Consumer Backward Compatibility Gate

**Any change touching the following areas must prove backward compatibility before release:**

- Docs root resolution (`DOCS_ROOT`, `Find-DocsRoot`, `$docsRoot`)
- forGPT path, Packet for External AI path, or `forgpt.manifest.json`
- `session-start`, `run-vibe`, `sync-forgpt`, `kit-update`, `end-session`
- PacketStatus, packet auto-commit, or packet freshness logic
- Clean-close or consumer audit gates
- Any consumer-distributed file or bundle entry

**Minimum validation must include all of the following:**

1. Standard `docs/` consumer fixture (Cases A–D in consumer regression harness)
2. LessonWriter-shaped `docs-engineering/` fixture (Case E in consumer regression harness)
3. Legacy `/forGPT` path must continue to work unchanged
4. Nonbreaking behavior for existing consumers — no forced migration

Run `run-consumer-regression-tests.ps1` before merging any change in scope above.

See: [R-007](../docs/research/R-007-Packet-For-External-AI-Decision-And-Readiness-Audit.md) for the Packet for External AI product decision and full compatibility inventory.

## Commit Standards
- Format: `<type>: <short description> (tests green)`
- Types: feat, fix, refactor, docs, chore, test
