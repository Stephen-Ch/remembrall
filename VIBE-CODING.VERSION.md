# Vibe-Coding Kit Version

**Version:** v7.5.15
**Effective Date:** 2026-05-05

## Purpose
Defines required artifacts + gates used by Doc Audit. This file is the **single source of truth** for the kit bundle version. Per-file `Bundle:` headers were removed in v7.2.2 to prevent version drift -- see changelog below.

## What Changed in v7.5.0
## What Changed in v7.5.1
- Extracted Evidence Pack Template example block from protocol-v7.md into standards/evidence-pack-template.md (Candidate 2 Stage 1); preserved normative Evidence Pack requirement sections.
- Note: This commit included both Evidence Pack Template extraction (Candidate 2 Stage 1) and previously unstaged protocol additions (Vibe Skills and Research Readiness Sweep). No behavioral changes were introduced beyond those already validated.

## What Changed in v7.5.15
- Fixed function-ordering bug in `tools/kit-update.ps1`: `Invoke-SnapshotIsolationEnforcement` was defined after the main `try/catch/finally` block but called within it, causing a false HARD STOP and exit 1 on all NOOP and post-update paths in PowerShell `-File` mode. Moved function definition before the `try` block. No behavior change beyond making the existing fix reachable.
- This version bump breaks the v7.5.14 consumer NOOP bootstrap deadlock: consumers on v7.5.14 now detect a version difference and pull the repaired script via normal `kit-update.ps1`.

## What Changed in v7.5.14
- New consumer start/sync now bootstraps the legacy `/forGPT` packet directory when no packet path exists and no `.vibekit/config.yml` packet path is configured.
- `session-start` remains non-mutating; packet bootstrap occurs only in the start/sync write path.
- Existing legacy `/forGPT` consumers remain fully compatible, and `/packet-for-external-ai` remains optional.
- Extended consumer regression harness coverage through Cases A-J, including new standard and LessonWriter-shaped installs with no packet directory.

## What Changed in v7.5.13
- Added a backward-compatible Packet for External AI path resolver (`tools/packet-path-resolver.ps1`) and adopted the first safe alias slice on main.
- Legacy `/forGPT` remains fully supported for existing consumers (standard `docs/` and LessonWriter-shaped `docs-engineering/` layouts).
- Added support for future `/packet-for-external-ai` via optional `.vibekit/config.yml` path configuration, without requiring existing consumers to migrate.
- Added non-blocking warning behavior when config specifies a missing packet path: emit note, then fall back using compatibility order.
- Extended consumer regression harness coverage through Cases A-G to prove legacy compatibility, LessonWriter compatibility, future-path config support, one-ahead stability, and missing-config-path fallback behavior.

## What Changed in v7.5.12
- Fixed warning-only consumer audit runs returning exit code 1: session-start now exits 0 after a completed non-blocking audit, while explicit HARD STOP / BLOCKED / crash paths remain non-zero. Updated the consumer regression harness to verify exit codes as part of acceptance.

## What Changed in v7.5.11
- Hotfixed v7.5.10 StrictMode crash in one-ahead PacketStatus logic: pipeline results from `git diff-tree` and `Where-Object` are now wrapped in `@()` before calling `.Count`, preventing a fatal error when exactly one forGPT file is changed (the LessonWriter single-file auto-commit case). Regression coverage added for the one-file scalar case (Case E).

## What Changed in v7.5.10
- Fixed PacketStatus false STALE after run-vibe -Tool start forGPT auto-commit: session-start now treats a forGPT-only one-ahead commit (manifest == HEAD~1, HEAD only forGPT files, clean tree) as CURRENT.

## What Changed in v7.5.9
- Fixed run-vibe -Tool start Step 3b so non-fatal Git CRLF warnings during forGPT auto-commit do not abort the startup flow.

## What Changed in v7.5.8
- Fixed run-vibe -Tool start forGPT auto-commit path handling for nested DOCS_ROOT layouts.

## What Changed in v7.5.7
- Updated run-vibe -Tool start to auto-commit generated forGPT packet changes after sync, preventing dirty-tree startup loops while preserving canonical-file safety.

## What Changed in v7.5.6
- Added "tentacles on" as canonical startup command alias for unified start flow.

## What Changed in v7.5.5
- Added small startup/closure guardrails: session-start Suggested Repair Order output (G-01), generated-vs-canonical examples in Step Closure Gate (G-03), and stronger repair re-run requirement in Startup Repair Sequence (G-04).

## What Changed in v7.5.4
- Added Startup Repair Sequence rule so session-start WARN/BLOCKED output becomes one ordered repair path instead of an operator choice prompt.

## What Changed in v7.5.3
- Refined NEXT.md staleness rules: time-based expiry now WARN-only; BLOCK reserved for actual repo/NEXT mismatch to reduce unnecessary maintenance work.

## What Changed in v7.5.2
- Added Step Closure Gate to working agreement to prevent overlapping steps and dirty-state collisions without adding operator burden.

## What Changed in v7.5.0
- Fixed check-prior-research.ps1 parser error (line 115) so prior research lookup works again. Replaced problematic backtick-quote escaping with explicit string concatenation.

## What Changed in v7.4.9
- Reduced duplication in working-agreement and research-standard by replacing repeated rule text with concise summaries and canonical protocol references.
## What Changed in v7.4.8
- **Restricted VIBE-KIT-SNAPSHOT.md to owner-only use; excluded from consumer distribution and added guardrails.** Removed tracked snapshot artifact from the kit tree, added explicit sync/kit-update/session-start/end-session isolation checks for consumer paths, blocked manifest inclusion, and added cleanup/warn behavior when owner-only snapshot artifacts are detected in consumer repositories.

## What Changed in v7.4.7
- **Refined VIBE-KIT-SNAPSHOT.md to lean summary mode (reduced size, removed embedded protocol content, improved AI load efficiency).** Updated tools/vibe-kit-snapshot.ps1 to emit a strict summary-only structure, enforce per-section compression limits, and add WARN heuristics for oversized files and protocol-copy patterns.

## What Changed in v7.4.6
- **Added auto-generated VIBE-KIT-SNAPSHOT.md for convenient AI context loading and drift detection.** Added tools/vibe-kit-snapshot.ps1 to generate and validate docs/forGPT/VIBE-KIT-SNAPSHOT.md from canonical sources. Wired automatic refresh into sync-forgpt, kit-update, session-start (when packet stale), and end-session (when kit docs changed). Added WARN-based drift checks for missing snapshot, version mismatch, and hand-edited/stale signature or commit mismatch.

## What Changed in v7.4.5
- **Added Research Readiness Sweep as a triggered micro-routine with strict anti-sprawl constraints.** Added a small planning-adjacent section in protocol/protocol-v7.md with explicit trigger-only scope, hard output caps, canonical report format, low-operator-burden role alignment, and no-new-system reuse of existing research/confidence rules. Added one short conditional reminder line in session-start-checklist.md.

## What Changed in v7.4.4
- **Added minimal Vibe Skills layer (vibe-plan, vibe-hunt, vibe-check).** Added one canonical shorthand section in protocol/protocol-v7.md with explicit 1:1 mappings to existing rules, required inputs/outputs, and a short "Why Vibe Skills exist" intent block. Added a lightweight optional reminder to session-start-checklist.md and one plain-English shorthand note to protocol/working-agreement-v1.md. No new enforcement logic, thresholds, scripts, or parallel process.

## What Changed in v7.4.3
- **Triggered Prior Parked-Work Lookup Gate (docs/protocol only).** Added a lightweight, triggered (not universal) gate to `protocol/protocol-v7.md` requiring prior-work lookup before drafting implementation/setup prompts in likely-reuse areas (for example Playwright/auth/test harness/screenshots/report UI/branch cleanup/x-branch/paused-resumed lanes). Canonical output requires four lines: parked branches, prior reports, open PRs, and reuse path. Added short reminder in `session-start-checklist.md` and plain-English cross-reference in `protocol/working-agreement-v1.md`.

## What Changed in v7.4.2
- **Docs-only stale/dirty triage clarification + worktree-aging coverage.** Added a compact `Stale/Dirty Triage Path` subsection to `protocol/protocol-v7.md` to present existing preserve/classify/cleanup order in operator sequence without changing policy. Added conservative worktree-aging defaults to `Staleness Expiry Gate` (classification guidance only, no new enforcement or deletion behavior). Added one discoverability cross-reference in `session-start-checklist.md`.

## What Changed in v7.4.1
- **Step 3 release bump for strict end-session closeout.** Consumer repos can now detect the already-published Step 3 change through normal version checks: `tools/end-session.ps1` returns nonzero for any `CLEAN FIELD READY: NO` result. This release commit changes only the version source of truth and does not modify runtime behavior.

## What Changed in v7.4.0
- **X-Branch Contract (v1).** Added `protocol/x-branch-contract.md`: defines experimental, never-merge branches (`x/` prefix) with one-session timebox, mandatory findings artifact, exit states (reject / adopt conceptually), INSTRUMENTATION mode threshold table, and branch-hygiene treatment. Added `templates/x-branch-findings-template.md` for structured experiment reports. Updated `tools/end-session.ps1` to report x-branches separately from normal non-merged branches (with age and color-coded staleness). Cross-references added to PROTOCOL-INDEX.md, README.md, user-story branch naming, and repo-policy overlay template.

## What Changed in v7.3.7
- **GPT-side project-identity gate.** Added a "Project-Identity Check" section to `templates/gpt-role-template.md`: GPT must verify incoming requests match the current project context and STOP on material mismatch. `session-start.ps1` now emits a `> **Project:** <repo-name>` line in PROJECT-STATE-SUMMARY to give GPT an explicit identity anchor.

## What Changed in v7.3.6
- **Project-identity gate.** Added a mandatory STOP condition to `protocol/hard-rules.md`: Copilot must verify the prompt targets the current repo/workspace before proceeding, and STOP on material mismatch. Reinforcing line added to `protocol/prompt-lifecycle.md` § Before Starting Work. No new files.

## What Changed in v7.3.5
- **GPT-ROLE template: Completion Evidence note.** Added a small "Completion Evidence" section to `templates/gpt-role-template.md` advising GPT to request verifiable evidence proportional to risk (test output, file checks, diffs, screenshots) rather than narrative-only completion claims. No new files, no protocol changes, no ceremony.

## What Changed in v7.3.4
- **PROJECT-STATE-SUMMARY observability hardening:** session-start.ps1 now verifies file existence after write (FAILED(write) on disk failure), logs explicit SKIP reason when forGPT directory is absent, and escalates FAILED status to a visible warning in the session audit block. No new gates or checklist burden.
- **GPT-ROLE.md standard delivery model:** Added consumer-owned manifest delivery guidance to `portability/subtree-playbook.md`. Kit provides template at `templates/gpt-role-template.md`; consumers copy to `project/GPT-ROLE.md`, add a manifest entry, and sync-forgpt delivers it. Follows the same ownership model as overlays.

## What Changed in v7.3.3
- **Friction Log v1.0 pilot:** New portable standard (`standards/friction-log-standard.md`) defining repo-root local friction logging for kit/process friction. Storage: `.kit-feedback/FRICTION-LOG.local.md` (local, untracked). Scope: MEDIUM/HIGH kit friction only, one entry max per session. Copilot end-of-session instruction added to `copilot-instructions-v7.md`. Reminder item added to `session-start-checklist.md` end-of-session section. No tool changes, no shared-directory logging, no scheduled synthesis. Repo-specific learning deferred to separate v1.1 track.

## What Changed in v7.3.2
- **NEXT.md freshness discipline:** session-start-checklist.md gains mandatory "NEXT.md Freshness" pre-flight item (review Immediate Next Steps for staleness before proceeding). End-of-session: conditional NEXT.md update added to protocol-v7.md § End-of-Session Full Contract (operator obligation 10) and session-start-checklist.md § End of Session. Mid-session: trigger-based (not routine) review note added to protocol-v7.md § Staleness Classification. No new files or scripts.

## What Changed in v7.3.1
- **Mid-Session Reset protocol:** Added operator confusion recovery procedure to protocol-v7.md (§ Focus Control). Trigger: `RUN MID-SESSION RESET`. Steps: stop edits → reality snapshot → classify confusion → research-only fallback if <95% → state next safe step. No scripts or templates — operator-driven protocol only.
- protocol-lite.md: Added quick-reference entry with trigger phrase and link.
- protocol/canonical-commands.md: Added `RUN MID-SESSION RESET` to the canonical command table.

## What Changed in v7.3.0
- **Visibility Contract v1:** New portable standard (`standards/visibility-contract-standard.md`) defining required/recommended/optional fields for consumer-repo project-state links (PR dashboard, branch ledger, next-step, pause/resume). Consumer-fill overlay template added (`templates/visibility-contract-overlay.example.md`). Session-start now surfaces visibility links when populated; suppresses noisy output when unpopulated. No hardcoded repo-specific values in the kit.
- templates/overlay-index.example.md: Added visibility-contract row to the standard overlay manifest.
- templates/start-here-template.md: Added visibility-contract row to Key Local Docs table.
- **End-of-session hardening (stale-item detection):** protocol-v7.md gains WIP Storage Preference (branches preferred over stash), Cleanup Closure Rule, Staleness Expiry rows for git stash entries and local branches with no upstream, and exit-nonzero-on-WR-BLOCKED tool enforcement bullet.
- tools/end-session.ps1: Added stash age audit (>3d stale / >14d expired) and branch age audit (>14d stale / >30d expired, no upstream). Hardened exit condition to exit 1 on Workspace Reality BLOCKED (not just tracked changes). Updated WIP storage message to prefer branches.
- session-start-checklist.md: Updated end-of-session guidance to prefer branches over stash for WIP storage.

## What Changed in v7.2.43
- **5-gate session-boundary hardening wave:** Added Workspace Reality Gate (end-session), Consumer-Kit Drift Gate (session-start), Staleness Expiry Gate (session-start), Decision-Queue Gate (session-start), and Tool/Auth Fragility Gate (session-start + end-session) to protocol-v7.md with full PASS/WARN/BLOCKED verdict models.
- tools/session-start.ps1: Implements Consumer-Kit Drift, Staleness Expiry, Decision-Queue, and Tool/Auth Fragility gates; all verdicts surfaced in the session audit block.
- tools/end-session.ps1: Implements Workspace Reality Gate and Tool/Auth Fragility Gate; Workspace Reality participates in CLEAN FIELD READY formula; ToolAuth displayed as meta-gate in footer.
- session-start-checklist.md: Added individual gate items for all 5 gates; updated RUN START chain description to include Staleness Expiry, Decision-Queue, Tool/Auth.
- PAUSE.md: Added Decision Queue table template for handoff-state decision tracking.
- protocol-lite.md: Added links for all 5 gates in Session Startup section.
- README.md: Updated tools table to describe all gates.
- Condensed-view patch audit: repaired protocol-lite drift (duplicate links, stale descriptions).

## What Changed in v7.2.42
- tools/session-start.ps1: non-subtree dirty files are now auto-stashed before kit subtree update and restored afterward, resolving the session-start deadlock where control-deck repairs blocked subtree pull. Dirty kit-subtree files still hard-stop.
- tools/run-vibe.ps1: updated -Force parameter help to reflect auto-stash behavior.
- protocol/canonical-commands.md: clarified session-start step 1 and -Force flag semantics.

## What Changed in v7.2.41
- Added Remote Reality Gate MVP: PASS/WARN/BLOCKED status model, active runtime branch definition, and branch classification labels (ACTIVE/PARKED/PR OPEN/MERGED/OBSOLETE) added to protocol-v7.md.
- session-start-checklist.md: added stale control-deck detection gate — mismatch between NEXT.md/branches.md and GitHub reality must be repaired or documented as debt before proceeding.
- PAUSE.md: banned unverified closure language ("ready to pause", "good shape", "clean enough") without remote-reality evidence; added required evidence checklist for session close.
- tools/end-session.ps1: extended to run git fetch --all --prune, print ahead/behind vs origin/develop, and surface open PR list via gh CLI (degrades to WARN/BLOCKED if gh unavailable).

## What Changed in v7.2.40
- Added critical-transition-checklist.md: compact, transition-triggered checklist for high-cost omission prevention (session start, subtree updates, broad staging, handoffs).
- Light references added in session-start-checklist.md Quick Links and QUICKSTART.md further reading.
- Not a per-prompt gate; does not add ceremony to normal implementation flow.

## What Changed in v7.2.39
- Added Staleness Classification table + forGPT Freshness Rule to protocol-v7.md (distinguishes expected mid-session drift from actionable problems and real breakage).
- Clarified PAUSE.md authority scope: end-of-session only; blank during active work is normal.
- Simplified session-start-checklist.md: reduced pre-flight to 3 blocking items; moved branch hygiene and research indexing to end-of-session concerns.
- Adjusted Quick Links table: NEXT.md marked as live work-state authority; PAUSE.md marked as end-of-session only.

## What Changed in v7.2.38
- Clarified session audit block terminology: replaced ambiguous "5-line gate/audit" references with "session audit block" across docs and script comment.
- Added non-blocking warning in session-start when ResearchIndex.md is newer than NEXT.md (surfaces control-deck drift early).

## What Changed in v7.2.37
- Added session-start Kit mode (run-vibe tool: session-start-kit) to run kit gates in the kit repo.

## What Changed in v7.2.36
- Added GitHub Actions CI to run kit gates on push/PR (doc-audit, verify-protocol-index, budget).

## What Changed in v7.2.35
- Scrubbed remaining project-specific leak tokens from secondary files (protocol-lite, required-artifacts, verification-mode, terminology-dictionary, stack-profile-standard, EVIDENCE-PACK-TEMPLATE, github-agent-return-packets-prompt-template, terminology-template, subtree-playbook); replaced with generic placeholders (`<YourProject>`, `<YourAppPath>`, `AcmeApp`, etc.).

## What Changed in v7.2.34
- Scrubbed project-specific examples (routes, component names, csproj, connection names) from vendor docs (stay-on-track.md, protocol-v7.md); replaced with generic placeholders; relocated specifics to templates/project-routes-overlay.example.md.

## What Changed in v7.2.33
- Add hard-rules quick reference (<2KB) with links; protocol-v7 remains authoritative.

## What Changed in v7.2.32
- Deduped STOP/PIVOT Rule (PIVOT REPORT + Contradiction STOP formats single-sourced in protocol-v7.md § Resilience Rules; copilot-instructions-v7.md now cross-links).

## What Changed in v7.2.31
- Deduped External Research Escalation (single-sourced in working-agreement-v1.md; copilot-instructions-v7.md now cross-links).

## What Changed in v7.2.30
- Removed consumer-facing kit-internal planning path literals from all shipped markdown to prevent persistent consumer doc-audit warnings (WARN rule remains: consumers should not reference kit-internal planning docs).

## What Changed in v7.2.29
- Redundancy reduction pilot: single-sourced Timeboxing + Pivot Rule in protocol-v7.md; replaced duplicated block in working-agreement-v1.md with cross-link.

## What Changed in v7.2.28
- Added templates/research-request-template.md — structured GPT↔Copilot research handoff format with mandatory fields, evidence pack section, and confidence gate alignment.

## What Changed in v7.2.27
- Added QUICKSTART.md — consumer-facing "add vibe-coding to your repo in ~5 minutes" guide with install, verify, update, and troubleshooting sections.

## What Changed in v7.2.26
- Added Comprehension Self-Check (3-question gate) as required step after Proof-of-Read in protocol-v7.md; cross-linked in copilot-instructions-v7.md.

## What Changed in v7.2.25
- session-start.ps1: added kit-version lag WARN — compares local vs remote kit version, emits WARN on mismatch or unavailability (never fails).

## What Changed in v7.2.24
- Added internal planning directory for kit maintainers: ROADMAP, SESSION-HANDOFF, GPT/Copilot session-start primers.
- doc-audit.ps1: added consumer-mode WARN when consumer docs reference kit-internal planning files.

## What Changed in v7.2.23
- Add External Research Escalation rule (Copilot → GPT Web/Deep Research) to prevent guessing when web access is required; propagated to working-agreement-v1.md, copilot-instructions-v7.md, and protocol-v7.md cross-link.

## What Changed in v7.2.22
- Removed remaining HIGH/MED/LOW confidence language from working-agreement-v1.md, protocol-v7.md (Enforcement), and stay-on-track.md; replaced with percentage thresholds (≥95% / ≥99%).
- Removed hard-coded Start-Here-For-AI.md filename links in required-artifacts.md; replaced with consumer-agnostic plain-text references.

## What Changed in v7.2.21
- Session-start chain wired into copilot-instructions-v7.md as mandatory first command.
- Standard Start-Here callout snippet added (templates/start-here-session-start-callout.example.md).
- Cross-link added in protocol-v7.md for consumer Start-Here docs.

## What Changed in v7.2.20
- Primary Priorities (Non-Negotiable) + Response Pattern added to working-agreement-v1.md; governs prompt-only + TDD + cognitive style for all GPT interactions.
- Cross-links added in protocol-v7.md and copilot-instructions-v7.md.

## What Changed in v7.2.19
- Confidence line canonicalized to `Confidence: <percentage>%` across Prompt Review Gate, templates, and overlays; old HIGH/MEDIUM/LOW and (0-100) forms deprecated.

## What Changed in v7.2.18
- Docs: canonical commands now prefer run-vibe universal runner (path-agnostic).

## What Changed in v7.2.17
- run-vibe.ps1 forwards named flags correctly in PS 5.1 (hashtable splatting); previous string-array splatting treated switches as positional args

## What Changed in v7.2.16
- run-vibe.ps1 now declares explicit wrapper parameters for common tool flags (e.g., -WriteReport, -Mode, -StartSession) so PS 5.1 binding succeeds; -ToolArgs kept as escape hatch

## What Changed in v7.2.15
- Added run-vibe.ps1 universal runner; canonical commands no longer hardcode DOCS_ROOT
- Discovery pattern in canonical-commands.md lets Copilot find the runner automatically

## What Changed in v7.2.14
- Added end-session.ps1 repo hygiene command (tracked changes hard-stop, orphan branch report, optional status report); documented in canonical-commands and session-start-checklist

## What Changed in v7.2.13
- sync-forgpt.ps1 derives DOCS_ROOT script-relatively (supports nested docs roots); same `$PSScriptRoot`-based pattern as session-start and doc-audit, with legacy `Find-ProjectRoot`/`Find-DocsRoot` walk as fallback

## What Changed in v7.2.12
- DOCS_ROOT detection is now script-relative (supports nested docs roots without junctions); both session-start.ps1 and doc-audit.ps1 derive DOCS_ROOT from `$PSScriptRoot/../../` when the kit head leaf is `vibe-coding`, with legacy repo-root detection as fallback

## What Changed in v7.2.11
- session-start.ps1: Added `Invoke-GitSafe` helper — runs git with stderr tolerance so progress output does not become a terminating error under `$ErrorActionPreference = "Stop"`
- Replaced bare `git fetch`, `git subtree pull`, and `git remote add` calls with `Invoke-GitSafe`; real failures still throw (checked via `$LASTEXITCODE`)

## What Changed in v7.2.10
- check-protocol-v7-budget.ps1 resolves protocol path relative to kit head (`$PSScriptRoot` parent) instead of repo root; fixes consumer Budget Check

## What Changed in v7.2.9
- verify-protocol-index.ps1 resolves paths relative to kit head (`$PSScriptRoot` parent) instead of repo root; fixes Protocol Index Check when run from consumer subtree

## What Changed in v7.2.8
- session-start.ps1 prints kit version (`KitVersion: vX.Y.Z (Effective YYYY-MM-DD)`) after subtree pull
- session-start.ps1 runs Consumer doc-audit (hard fail) after forGPT sync, with safe `-StartSession` parameter detection
- Added `-SkipAudit` flag to bypass Consumer audit while still printing kit version
- `-WhatIf` now prints `[WhatIf] Would run: Consumer doc-audit …` line (including whether `-StartSession` would be used)
- Updated canonical-commands.md and session-start-checklist.md to document the new steps

## What Changed in v7.2.7
- Added consumer overlay example templates (overlay-index / stack-profile / merge-commands / hot-files / repo-policy)
- Return Packet Gate now references consumer `<DOCS_ROOT>/overlays/hot-files.md` instead of hardcoded project-specific file names; project-specific example return packets replaced with generic naming patterns
- Merge prompt template now references consumer `<DOCS_ROOT>/overlays/merge-commands.md` instead of hardcoded `npm run` commands
- README.md and MIGRATION-INSTRUCTIONS.md updated to surface overlay templates and mapping

## What Changed in v7.2.6
- Clarified return packet policy: GitHub.com Agent may create return packets in `<DOCS_ROOT>/status/` (the only allowed research artifact creation by that agent)
- Fixed Start-Here-For-AI.md location policy: consumer file at `<DOCS_ROOT>/Start-Here-For-AI.md`, not inside kit head
- Updated MIGRATION-INSTRUCTIONS.md: customization via overlays instead of direct edits to copilot-instructions-v7.md
- Clarified confidence scale: Prompt Review Gate HIGH aligns to ≥95%/≥99% Tiered Confidence thresholds

## What Changed in v7.2.5
- **PS 5.1 compatibility fix:** Replaced 3-arg `Join-Path` calls in sync-forgpt.ps1 with nested 2-arg `Join-Path` (PS 5.1 only supports 2 positional args; 3-arg form requires PS 7+ `-AdditionalChildPath`)
- Minimum PowerShell target: 5.1 (ships with Windows by default)

## What Changed in v7.2.4
- Added North Star source-of-truth rule under Focus Control
- Added Goal Anchor Fields block + placement guidance in required-artifacts
- Wired North Star unknown STOP rule into working agreement

## What Changed in v7.2.3
- Added Focus Control to protocol-v7 (Goal Anchor, Drift Triggers, Reset Ritual, Parking Lot rule)
- Wired drift reset enforcement into working-agreement-v1
- Added Goal Anchor to session-start-checklist

## What Changed in v7.2.2
- **Version centralization:** Removed per-file `Bundle: vX.Y.Z` headers from all markdown files. VIBE-CODING.VERSION.md is now the sole version authority. Per-file `File Version:` (date) headers are retained.
- Synced version to v7.2.2 (matching README.md and protocol-lite.md, the highest released version on main)
- Replaced all hardcoded `docs-engineering/` paths with portable `<DOCS_ROOT>/` variable (233 replacements across 23 files)

## What Changed in v7.1.5
- Added `tools/session-start.ps1` wrapper: chains kit subtree update → forGPT sync → 5-line Doc Audit
- Wired canonical-commands.md, protocol-v7.md, protocol-primer.md, session-start-checklist.md to reference the wrapper
- "RUN START OF SESSION DOCS AUDIT" now invokes the wrapper when present

## What Changed in v7.1.4
- Updated Green Gate build command to skip parseTaggerNET3.0 dependencies (`/p:BuildProjectReferences=false`)
- Added file versioning system with session-start handshake for cross-agent sync
- Created docs/forGPT folder for ChatGPT Planner uploads

## What Changed in v7.1.3
- Added redirect banners to all legacy docs/protocol/ files
- Clarified canonical source location (<DOCS_ROOT>/vibe-coding/protocol/)
- Committed outstanding protocol changes from v7.1.2

## What Changed in v7.1.2
- Reporting: narrative directory buckets only; raw evidence outputs are authoritative (handles VSCode linkification constraint).

## What Changed in v7.1.1
- Added portable doc-audit tool + CI workflow (low-noise v1: Control Deck placeholder scan only; NEXT required only on non-docs PRs)

## What Changed in v7.1.0
- Added required-artifacts.md defining mandatory project docs (VISION/EPICS/NEXT)
- Added 3-Party Approval Gate (Stephen + ChatGPT + Copilot) to alignment-mode.md
- Added <DOCS_ROOT>/project/NEXT.md Lightweight Rule (~30 line limit, update triggers, paperwork signal) to NEXT.template.md
- Wired Start-of-Session Doc Audit to read VIBE-CODING.VERSION.md + required-artifacts.md before coding
- Created Control Deck templates (VISION.template.md, EPICS.template.md, NEXT.template.md)

## Version History
- v7.4.3 (2026-04-25): Added triggered Prior Parked-Work Lookup Gate to protocol with checklist/working-agreement reminders to prevent duplicate recreation of parked prior work
- v7.4.1 (2026-04-21): Release bump for already-published Step 3 strict end-session closeout so consumer version checks can detect and sync it
- v7.2.6 (2026-02-26): Return packet policy + Start-Here location + migration overlay guidance + confidence clarification
- v7.2.5 (2026-02-26): PS 5.1 compatibility fix for sync-forgpt.ps1 (3-arg Join-Path → nested 2-arg)
- v7.2.4 (2026-02-24): North Star source rule + Goal Anchor Fields
- v7.2.3 (2026-02-24): Focus Control rules + working agreement + session-start checklist
- v7.2.2 (2026-02-09): Version centralization — removed per-file Bundle tags; VIBE-CODING.VERSION.md is sole version authority
- v7.1.5 (2026-02-07): Session-start wrapper (auto kit update + forGPT sync + doc audit)
- v7.1.4 (2026-01-18): Green Gate build fix + file versioning + forGPT folder
- v7.1.3 (2026-01-16): Legacy file redirect banners + canonical source clarification
- v7.1.2 (2026-01-07): Reporting directory buckets (narrative only)
- v7.1.1 (2026-01-05): Portable doc-audit tool + CI workflow
- v7.1.0 (2026-01-04): Required artifacts + 3-Party Approval Gate + <DOCS_ROOT>/project/NEXT.md Lightweight Rule
- v7.0.0 (2026-01-03): Protocol v7 with Vision & User Story Gate, Alignment Mode, Verification Mode

---

Last updated: 2026-04-25
