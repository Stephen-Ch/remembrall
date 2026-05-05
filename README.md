# Portable Vibe-Coding Kit

> **File Version:** 2026-02-26

The files in this directory

## Start Here

| New to vibe-coding? | Read this first |
|---------------------|-----------------|
| **User story** | [portability/user-story-stephen-vibe-coding.md](portability/user-story-stephen-vibe-coding.md) — What Stephen wants from this workflow |
| **Quick reference** | [protocol-lite.md](protocol-lite.md) — Core rules in ~150 lines |
| **Protocol index** | [PROTOCOL-INDEX.md](protocol/PROTOCOL-INDEX.md) — Navigate all protocol-v7 sections by task |
| **Prior Research rule** | [protocol-v7.md § Prior Research Lookup](protocol/protocol-v7.md#c-prior-research-lookup-mandatory) — Mandatory before any RESEARCH-ONLY output |

AI assistants should use canonical docs as authoritative sources; forGPT packets are consumer-facing handoff snapshots generated from the manifest.

## GPT Session Bootstrap

Upload this README + the files below to start a ChatGPT session. README is canonical.

<!-- GPTBOOTSTRAP:START -->
- [protocol-primer.md](protocol-primer.md) — ChatGPT role + dual-agent rules
- [protocol-lite.md](protocol-lite.md) — Core rules quick reference
- [templates/prompt-template.md](templates/prompt-template.md) — Copyable prompt skeleton
- [protocol/protocol-v7.md](protocol/protocol-v7.md) — Full protocol (reference)
- [DOCS-HEALTH-CONTRACT.md](DOCS-HEALTH-CONTRACT.md) — Doc health gates
<!-- GPTBOOTSTRAP:END -->

## Session Start Snippets

### GPT bootstrap (paste into ChatGPT)
<!-- STARTSESSION:GPT -->
You are the Planner/Prompt Writer for vibe-coding-kit (Stephen-Ch/vibe-coding-kit).
README.md is the canonical entry point - read it first.
Follow all gates in DOCS-HEALTH-CONTRACT.md.
Use templates/prompt-template.md for every prompt you write.
Every prompt MUST include a PROMPT-ID. Every output MUST include a Completion Report.
Do NOT create a kit-root /forGPT directory (it collides with consumer repos via subtree).
Scope: DOCS ONLY unless explicitly stated otherwise.
If confidence is below 95%, enter RESEARCH-ONLY mode - do not guess.
If anything is unclear, STOP and ask before proceeding.
<!-- ENDSESSION:GPT -->

### Copilot header (paste at top of every Copilot prompt)
<!-- STARTSESSION:COPILOT -->
Repo: vibe-coding-kit (Stephen-Ch/vibe-coding-kit)
Scope: DOCS ONLY (unless prompt says otherwise)
Canon docs: README.md (entry point), protocol/protocol-v7.md (full rules), protocol-lite.md (quick ref)
Gate command: .\tools\doc-audit.ps1 (must PASS before commit)
Output requirements: include PROMPT-ID + Completion Report in every response.
Hard rule: do NOT create a kit-root /forGPT directory.
Confidence below 95% = RESEARCH-ONLY mode. Do not guess.
<!-- ENDSESSION:COPILOT -->

## How to use this kit
1. **Start here:** Run through [session-start-checklist.md](session-start-checklist.md) before any work session.
2. **Quick reference:** Read [protocol-lite.md](protocol-lite.md) for core rules summary (~150 lines).
3. **If resuming:** Check [PAUSE.md](PAUSE.md) for session handoff state.
4. Read [protocol/protocol-v7.md](protocol/protocol-v7.md) for full authoritative rules (gates, sequencing, stop conditions).
5. Follow [protocol/copilot-instructions-v7.md](protocol/copilot-instructions-v7.md) while composing every completion report (coverage proof, proof-of-experience, entry-point maps, etc.).
6. Self-check against [protocol/stay-on-track.md](protocol/stay-on-track.md) whenever working on cross-cutting UX or coverage-sensitive tasks.
7. Reference [protocol/working-agreement-v1.md](protocol/working-agreement-v1.md) for operator vs AI responsibilities and commit standards.

Consumer update source branch note:
For subtree add/pull in consumer repos, use `release/consumer-payload` as the source ref. The `main` branch is kit source/control-plane and not the consumer payload source.

Rollout caution:
Using `release/consumer-payload` as the source ref does not by itself authorize immediate real consumer rollout.

Legacy duplicates under `docs/protocol` now contain redirect banners and exist only for backward compatibility with older prompts. Edit the vibe-coding copies instead.

## Directory map
- `protocol/` — Living workflow docs (protocol-v7, copilot instructions, stay-on-track, working agreement).
- `templates/` — Required completion-report blocks (test-touch, closeout artifact verification, evidence pack, manual test) plus the [Copilot overlay example](templates/copilot-instructions-overlay.example.md) for project-specific overrides.
- `standards/` — Canonical standards for research docs and stack profiles (portable across repos).
- `portability/` — Subtree integration playbook for adding/updating the bundle in other repos.
- `terminology/` — Project-wide dictionary plus a template for adding new product → storage mappings.
- `session-start-checklist.md` — Single-page pre-flight checklist for session startup.
- `protocol-lite.md` — Quick-reference entrypoint (~150 lines) linking to authoritative sections.
- `PAUSE.md` — Session handoff state for resumption.
- `OCTOPUS-INVARIANTS.md` — Hard invariants: overlays outside kit head, canonical paths.
- `DOCS-HEALTH-CONTRACT.md` — Hard-fail checks for doc health (overlay placement, control deck).

## Standards (Portable)

| Standard | Purpose |
|----------|---------|
| [standards/research-standard.md](standards/research-standard.md) | Canonical research doc format + indexing rules |
| [standards/stack-profile-standard.md](standards/stack-profile-standard.md) | How to declare repo technology stack for gates |

**Project-specific:** Each repo declares its own stack profile at `<DOCS_ROOT>/project/stack-profile.md`.

## Tools Quick Reference

| Tool | Purpose |
|------|---------|
| `tools/doc-audit.ps1` | Docs health gate (must PASS before commit) |
| `tools/session-start-kit.ps1` | Kit-root session-start for the vibe-coding-kit source repo. Use `pwsh -NoProfile -File tools/session-start-kit.ps1` or `.\tools\run-vibe.ps1 -Tool session-start-kit`. |
| `tools/session-start.ps1` | Session-start wrapper (subtree pull → version print → drift gate → staleness check → decision-queue check → tool/auth check → forGPT sync → audit) |
| `tools/tests/run-consumer-regression-tests.ps1` | Disposable consumer regression harness for packet/session-start regressions before kit updates ship |
| `tools/check-prior-research.ps1` | Prior research lookup (run BEFORE any RESEARCH-ONLY work) |
| `tools/verify-protocol-index.ps1` | Validate protocol index anchor links |
| `tools/check-protocol-v7-budget.ps1` | Protocol file size/heading budget check |
| `tools/sync-forgpt.ps1` | Sync forGPT packet for ChatGPT uploads |

Maintainer note:
For kit repo root audits, use `pwsh -NoProfile -File tools/session-start-kit.ps1` or `.\tools\run-vibe.ps1 -Tool session-start-kit`. `tools/session-start.ps1` is for consumer repos with a `docs/vibe-coding` subtree and should not be run from the kit repo root.

## Templates Quick Reference

| Template | Purpose |
|----------|---------|
| [EVIDENCE-PACK-TEMPLATE.md](templates/EVIDENCE-PACK-TEMPLATE.md) | Required when confidence is below threshold |
| [MANUAL-TEST-TEMPLATE.md](templates/MANUAL-TEST-TEMPLATE.md) | Formal acceptance/regression tests |
| [closeout-artifact-verification-template.md](templates/closeout-artifact-verification-template.md) | S2C merge verification |
| [test-touch-block-template.md](templates/test-touch-block-template.md) | When touching test files |
| [copilot-instructions-overlay.example.md](templates/copilot-instructions-overlay.example.md) | Project-specific Copilot overrides (copy to consumer repo) |
| [overlay-index.example.md](templates/overlay-index.example.md) | Consumer overlay manifest (lists all standard overlays) |
| [stack-profile-overlay.example.md](templates/stack-profile-overlay.example.md) | Install/build/test/start commands + tech constraints |
| [merge-commands-overlay.example.md](templates/merge-commands-overlay.example.md) | Build Gate + Test Gate commands for merge workflow |
| [hot-files-overlay.example.md](templates/hot-files-overlay.example.md) | Hot files/folders requiring analysis-first workflow |
| [repo-policy-overlay.example.md](templates/repo-policy-overlay.example.md) | Branch policy, PR rules, merge method, naming conventions |
| [x-branch-findings-template.md](templates/x-branch-findings-template.md) | Findings report for x-branch experiments (never-merge branches) |
| [gpt-role-template.md](templates/gpt-role-template.md) | Compressed GPT role + Octopus model for forGPT packets |

## Contribution rules
- Keep language portable; replace project-specific jargon with templates or clearly marked examples when possible.
- Note any project-specific adjustments (such as route coverage lists) inline so other repos can override them.
- When the kit evolves, update session entry points in consuming repos so new sessions land here first.

## Consumer Regression Harness
- Run `pwsh -NoProfile -ExecutionPolicy Bypass -File .\run-consumer-regression-tests.ps1` from the repo root before publishing kit updates that affect consumer startup, packet freshness, or DOCS_ROOT/path handling.
- The harness provisions disposable temp git repos with two consumer shapes: standard `docs/...` and nested `LessonWriter2.0/docs-engineering/...`.
- Current suite covers packet/session-start regressions A-E, including the one-file forGPT auto-commit StrictMode case.
- Exit-code contract under test: completed warning-only consumer audits must exit `0`; only BLOCKED, HARD STOP, or crash states may exit non-zero.
- Do not update a real consumer repo until the disposable fixture matching that repo shape passes in this harness.

Questions about historical behavior or superseded docs? Check `docs/archive` for prior reports, templates, and experiments.

## Return Packet Gate (Research Before Risky Work)

When entering Alignment Mode with hot-file or high-uncertainty triggers, run the Return Packet Gate first:

- **Protocol:** [protocol/return-packet-gate.md](protocol/return-packet-gate.md) — Defines triggers, acceptance criteria, and 4-party handoff
- **Template:** [templates/github-agent-return-packets-prompt-template.md](templates/github-agent-return-packets-prompt-template.md) — Ready-to-paste GitHub agent prompts

See [protocol/return-packet-gate.md](protocol/return-packet-gate.md) for example naming patterns.
