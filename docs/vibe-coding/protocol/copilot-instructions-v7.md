# Copilot Instructions v7 -- Vibe-Coding Protocol

> **File Version:** 2026-03-16
>
> **Portable.** This file contains Copilot-specific execution guidance only.
> All canonical rules live in [protocol-v7.md](protocol-v7.md).
> Project/stack-specific overrides belong in a consumer-repo overlay
> (see [templates/copilot-instructions-overlay.example.md](../templates/copilot-instructions-overlay.example.md)).

---

## Prompt Classes

Copilot recognizes two request types. Canonical definitions and enforcement
details are in protocol-v7.md:
[Prompt Classes](protocol-v7.md#prompt-classes-request-types).

| Type | Copilot Action |
|------|----------------|
| **Formal work prompt** | Execute following all gates (Gate, Command Lock, Proof-of-Read, Green Gate) |
| **Conversational request** | Read-only tools only; no edits, no terminal commands |

If a conversational request asks for execution, draft a formal work prompt
instead of executing.

---

## Session Start (MANDATORY FIRST COMMAND)

Before any work in a fresh session, run the session-start chain:

    powershell -NoProfile -ExecutionPolicy Bypass -File <SUBTREE>/tools/run-vibe.ps1 -Tool session-start

This chains kit update → forGPT sync → doc-audit -StartSession → prints the session audit block. If any other command is requested first, reply: **Hard Stop. Run RUN START OF SESSION DOCS AUDIT first.**

Fallback (if run-vibe unavailable): `<DOCS_ROOT>/vibe-coding/tools/session-start.ps1`

See [canonical-commands.md → Session Start](canonical-commands.md#session-start-docs-audit-mandatory-first-command) for flags and chain details.

---

## Non-Negotiables (Formal Work Prompts)

These are Copilot-specific execution rules. For the full gate definitions,
see [Core Rules](protocol-v7.md#core-rules-non-negotiable).

**Primary Priorities:** Follow [working-agreement-v1.md → Primary Priorities (Non-Negotiable)](working-agreement-v1.md#primary-priorities-non-negotiable) for prompt-only + one-prompt + tiny-step TDD + brevity rules.

1. **PROMPT-ID first line** -- the completion report must start with
   `PROMPT-ID: <id>`. No headings or text before it.
2. **Prompt Review Gate** -- print the 4-line gate immediately after PROMPT-ID
   and BEFORE anything else (including Proof-of-Read). No commands, edits, or
   searches until these lines are printed (Command Lock).
3. **Proof-of-Read** -- file + quote + "Applying: <rule>". Must appear after
   the Gate and before any searches or edits.
   After Proof-of-Read, complete the **Comprehension Self-Check** (Q1: what changes, Q2: out of scope, Q3: next command + gate) before proceeding.
   See [protocol-v7.md § Comprehension Self-Check](protocol-v7.md#comprehension-self-check-required).
4. **Green Gate** -- run the stack-appropriate gate declared in the consumer
   repo's stack-profile. See [Green Gate](protocol-v7.md#green-gate--stack-aware-rules).
5. **Stop on Error** -- non-zero exit -> stop, propose smallest fix, wait.
6. **One copy-paste document** -- entire response is one continuous markdown
   document with zero fenced code blocks (use 4-space indentation).

---

## Default Formal Report Footer

When a prompt involves codebase searching, include:

    Search method used: rg | git grep | Select-String

When any recovery is used, include:

    Recovery applied: none | retry | fallback

For every formal work prompt, include:

    Help trigger used: YES | NO
    If YES: Report requested: <PROMPT-ID>

Notes:
- Default to fallbacks; never assume rg exists.
- If strict sequencing is required by the prompt, do not batch commands.

---

## Mandatory Help Trigger Check

Before implementing any formal work prompt, verify four conditions.
Full help trigger definitions and the agent report template are in
[Churn Circuit Breaker](protocol-v7.md#help-triggers--churn-circuit-breaker-solution-agnostic).

1. Multi-scenario/tenant copy without registry key? -> STOP.
2. Unknown runtime key path? -> STOP.
3. Edits in 2+ components without call-site map? -> STOP.
4. Refactor without call-site map? -> Propose agent report.

---

## STOP / PIVOT Rule

When evidence contradicts the prompt, follow the PIVOT or Contradiction STOP format before making any edits.

→ [protocol-v7.md § STOP / PIVOT Rule](protocol-v7.md#d-stop--pivot-rule-when-evidence-contradicts-prompt)

### External Research Escalation (no web access)

When blocked by external facts Copilot cannot verify locally, **STOP** and output `NEED GPT WEB RESEARCH`.

→ [working-agreement-v1.md § External Research Escalation](working-agreement-v1.md#external-research-escalation-when-copilot-lacks-web-access)

---

## Sequencing (Hard Rule)

Do not author or request the next prompt until the prior completion report
has been pasted and acknowledged. See
[Session Sequencing Rule](protocol-v7.md#session-sequencing-rule-hard-stop).

If you violate Command Lock or Gate ordering, STOP immediately, report what
happened, and restart from the beginning of the prompt.

---

## Edit Constraints (Defaults)

- Keep steps small unless the prompt explicitly allows more.
- One numbered plan -> execute step 1 only, then report.
- Hot files: analysis-only first prompt. See
  [Hot File Protocol](protocol-v7.md#hot-file-protocol-general).

Consumer repos should list project-specific hot files in their overlay.

---

## Shell and Terminal Policy

- Use PowerShell for terminal commands
  (see [Shell Discipline](protocol-v7.md#shell-discipline-mandatory)).
- Echo CWD once per session.
- No package-manager changes without explicit approval.

---

## Cross-cutting and UX Proof

For cross-cutting or UX work, include the coverage checklist and UX proof
defined in protocol-v7:

- [Coverage Checklist](protocol-v7.md#coverage-checklist-for-cross-cutting-work-mandatory)
- [UX Proof Requirement](protocol-v7.md#ux-proof-requirement-for-user-visible-changes-mandatory)

Consumer repos should map their own routes/controllers in the overlay.

---

## Deterministic Tests (Mandatory)

- No unseeded randomness.
- No "rerun until green".
- If flakiness exists, record tech debt with an ID and cause.

---

## Entry-point Map (Mandatory in Reports)

Every code prompt completion report must include:

    Entry points touched: path#function list

---

## Completion Report Required Fields

Every completion report must include:

- Commit hash + subject of the most recent commit
- git status --porcelain output (must be empty at the end)
- git diff --name-only output showing touched files
- Green Gate results (stack-appropriate build + tests)

Consumer repos may add stack-specific required fields (e.g., spec @human
lines, test catalog updates) in their overlay.

### Backend/Runtime Completion Reports — Additional Required Fields

**Applies when:** the PR contains any runtime files (controllers, services/helpers,
models/entities, repositories, migrations, middleware, routing, or API handlers).

Every such completion report must answer all three with YES or NO:

    Anything surprise you? YES/NO
    Anything deserves a second look before merge? YES/NO
    Is merge confidence below 95% anywhere in the changed runtime path? YES/NO

**If ANY answer is YES:** the PR is NOT merge-ready. STOP and flag the concern
before requesting review. See [protocol-v7.md § PR / Branch Hygiene Gate §D](protocol-v7.md#d-runtime-weighted-merge-review).

---

## S2C Closeout -- Artifact Verification

Every S2C completion report must include the verification table from:
[closeout-artifact-verification-template.md](../templates/closeout-artifact-verification-template.md)

---

## Friction Log — End-of-Session (v1.0 Pilot)

Before closing any session, check whether qualifying kit/process friction occurred (see [standards/friction-log-standard.md](../standards/friction-log-standard.md) for triggers and exclusions).

- If yes: append **one** MEDIUM/HIGH entry to `.kit-feedback/FRICTION-LOG.local.md` using the schema in the standard. Create the directory and file if they do not exist.
- If no qualifying friction occurred: write nothing. Silence is the expected default.
- Do **not** log normal coding retries, flaky tests, or repo-specific learning here.
