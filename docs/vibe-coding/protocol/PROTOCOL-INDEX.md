# Protocol Index — Quick Navigator

> **Navigation-only.** No rules defined here. All links target
> [protocol-v7.md](protocol-v7.md). Canonical rules live in protocol-v7.md.

---

## Before You Start (Session Setup)

- **Hard rules (mandatory gates only)** → [hard-rules.md](hard-rules.md) *(separate file, not a protocol-v7 anchor)*
- Core rules and non-negotiables → [Core Rules](protocol-v7.md#core-rules-non-negotiable)
- Focus Control (Goal Anchor, Drift Triggers, Reset Ritual) → [Focus Control](protocol-v7.md#focus-control)
- North Star source of truth → [North Star Source of Truth](protocol-v7.md#north-star-source-of-truth)
- Prompt classes and request types → [Prompt Classes](protocol-v7.md#prompt-classes-request-types)
- Required reading by prompt type → [Required Reading Sets](protocol-v7.md#required-reading-sets-by-prompt-type)
- Prompt structure template → [Prompt Structure](protocol-v7.md#prompt-structure)
- Response structure requirements → [Response Structure](protocol-v7.md#response-structure)
- Session sequencing (hard stop) → [Session Sequencing Rule](protocol-v7.md#session-sequencing-rule-hard-stop)

## Research & Evidence (RESEARCH-ONLY, Evidence Packs)

- Confidence thresholds (95%/99%) → [Tiered Confidence Gate](protocol-v7.md#no-guessing--tiered-confidence-gate-mandatory)
- Preflight evidence requirements → [Preflight Evidence Gate](protocol-v7.md#preflight-evidence-gate-no-guessing)
- RESEARCH-ONLY scope and rules → [RESEARCH-ONLY Command Lock](protocol-v7.md#research-only-command-lock-mandatory)
- INSTRUMENTATION (CODE-OK) scope → [INSTRUMENTATION Scope](protocol-v7.md#instrumentation-code-ok-scope-mandatory)
- Evidence Pack format and template → [Evidence Pack Requirement](protocol-v7.md#evidence-pack-requirement-mandatory)
- Research indexing obligation → [Research Saved + Indexed](protocol-v7.md#research-saved--indexed-mandatory)

## Build & Test Gates (Green Gate, Manual Test)

- Stack-aware build gate → [Green Gate](protocol-v7.md#green-gate--stack-aware-rules)
- Manual test artifact format → [Manual Test Checklist](protocol-v7.md#manual-test-checklist-artifact-mandatory)
- Interface forecast before wiring → [Interface Forecast Micro-Gate](protocol-v7.md#interface-forecast-micro-gate-mandatory-before-first-wiring-step)

## Code Quality & Scope

- Lint-suppress before lint-fix default → [Lint-Suppress Rule](protocol-v7.md#lint-suppress-before-lint-fix-mandatory-default)
- Hook dependency change gate → [Hook Dependency Gate](protocol-v7.md#hook-dependency-change-gate-reactts-projects-only)
- Cleanup scope for hygiene stories → [Cleanup Scope Rule](protocol-v7.md#cleanup-scope-rule-mandatory-for-lintformattinghygiene-stories)
- Hot file protocol → [Hot File Protocol](protocol-v7.md#hot-file-protocol-general)
- Copy and semantics for UX changes → [Copy & Semantics Gate](protocol-v7.md#copy--semantics-gate-mandatory-for-uxcopynarration-changes)
- Coverage checklist for cross-cutting → [Coverage Checklist](protocol-v7.md#coverage-checklist-for-cross-cutting-work-mandatory)
- UX proof for visible changes → [UX Proof Requirement](protocol-v7.md#ux-proof-requirement-for-user-visible-changes-mandatory)
- Bundle warnings policy → [Bundle Warnings](protocol-v7.md#bundle-warnings-policy-standard)

## PR & Merge Hygiene

- PR/branch hygiene requirements → [PR / Branch Hygiene Gate](protocol-v7.md#pr--branch-hygiene-gate-mandatory)
- X-branch contract (experimental, never-merge branches) → [X-Branch Contract](x-branch-contract.md)
- Docs PR consolidation → [Docs PR Consolidation Rule](protocol-v7.md#docs-pr-consolidation-rule)
- Pre-S2C sync check → [Pre-S2C Sync Check](protocol-v7.md#pre-s2c-sync-check-mandatory)
- S2C / merge checklist → [S2C / Merge Checklist](protocol-v7.md#s2c--merge-checklist)
- GREEN means merge now → [GREEN Means Merge Now](protocol-v7.md#green-means-merge-now-mandatory)
- Test-touch rule for prompts → [Test-Touch Rule](protocol-v7.md#prompt-authoring--test-touch-rule)

## Resilience & Error Handling

- Two-tier command lock → [Command Lock](protocol-v7.md#a-two-tier-command-lock)
- Search tool fallbacks → [Search Fallbacks](protocol-v7.md#b-search-tool-fallbacks)
- Recoverable error policy → [Error Policy](protocol-v7.md#c-recoverable-error-policy)
- Shell discipline → [Shell Discipline](protocol-v7.md#shell-discipline-mandatory)

## Pause, Block & Help

- When to stop and ask for help → [Churn Circuit Breaker](protocol-v7.md#help-triggers--churn-circuit-breaker-solution-agnostic)
- Blocked goal procedure → [Blocked Goal Procedure](protocol-v7.md#blocked-goal-procedure-mandatory)
- Waiting-for-approver workflow → [Approver Workflow](protocol-v7.md#waiting-for-approver-workflow-mandatory)

## Session Boundaries & Workspace Gates

- Remote Reality Gate → [Remote Reality Gate](protocol-v7.md#remote-reality-gate-mandatory-at-session-boundaries)
- Workspace Reality Gate (session close) → [Workspace Reality Gate](protocol-v7.md#workspace-reality-gate-mandatory-at-session-close)
- End-of-session full contract → [End-of-Session Full Contract](protocol-v7.md#end-of-session-full-contract-canonical-meaning-of-run-end-of-session)
- Temporary consumer learning loop → [Consumer Session Post-Mortem (Temporary)](consumer-session-postmortem-temporary.md)
- Consumer post-mortem template → [Consumer Session Post-Mortem Template](../templates/consumer-session-postmortem-template.md)
- Consumer-Kit Drift Gate (session start, consumer repos) → [Consumer-Kit Drift Gate](protocol-v7.md#consumer-kit-drift-gate-mandatory-at-session-start-in-consumer-repos)
- Staleness Expiry Gate (handoff freshness) → [Staleness Expiry Gate](protocol-v7.md#staleness-expiry-gate-mandatory-at-session-boundaries)
- Decision-Queue Gate (decision-item structure and lifecycle) → [Decision-Queue Gate](protocol-v7.md#decision-queue-gate-mandatory-at-session-boundaries)
- Tool/Auth Fragility Gate (verification toolchain health) → [Tool/Auth Fragility Gate](protocol-v7.md#toolauth-fragility-gate-mandatory-at-session-boundaries)

## Deployment & Environment

- Remote target preflight → [Remote Target Preflight](protocol-v7.md#remote-target-preflight-mandatory-for-devstageprod-automation)
- Environmental debug timebox → [Debug Timebox](protocol-v7.md#environmental-debug-timebox-mandatory)
- CI gate order policy → [CI Gate Order](protocol-v7.md#ci-gate-order-policy-mandatory)

## Context & Prompts

- Lean prompts and context budgeting → [Lean Prompts](protocol-v7.md#lean-prompts-and-context-budgeting-mandatory)
- Vision & user story gate → [Vision Gate](protocol-v7.md#vision--user-story-gate-mandatory-for-work-prompts)
- Enforcement policy → [Enforcement](protocol-v7.md#enforcement)

## Copilot Instructions

- Copilot execution rules (portable) → [copilot-instructions-v7.md](copilot-instructions-v7.md)
- Project-specific overlay example → [copilot-instructions-overlay.example.md](../templates/copilot-instructions-overlay.example.md)

---

> This file is navigation only. Do not add rule text.
> If a link breaks, the heading in protocol-v7.md was renamed — fix the anchor here.
