# Canonical Commands

> **CRITICAL RULE:** Never omit `<DOCS_ROOT>/project/` or `<DOCS_ROOT>/testing/` in printed commands. Never rely on linkified filenames. Always use `git -C ...` to enforce repo-root execution.

## Reporting Standard — Narrative Dirs Only; Raw Evidence Is Authority

**A) Narrative**
- Narrative summaries MUST list ONLY directory buckets (example: docs/project: 2 files; app/src/...: 1 file).
- Narrative MUST NOT list filenames or full file paths.
- Narrative MUST NOT attempt to "fix" or "avoid" VSCode linkification.

**B) Authority**
- File locations and exact paths MUST be proven ONLY via raw command outputs:
  - `git -C $root diff --name-only`
  - `git -C $root ls-files <DOCS_ROOT>/project/VISION.md <DOCS_ROOT>/project/EPICS.md <DOCS_ROOT>/project/NEXT.md <DOCS_ROOT>/testing/test-catalog.md`
  - Population Gate grep command + result
  - doc-audit output (including any "Checked:" lines)
- If narrative conflicts with raw outputs, raw outputs win.

**C) Deprecation**
- Prior "canonical paths in narrative" requirement is deprecated due to tool linkification constraints.
- Commands MUST still use explicit canonical paths; only narrative summaries are restricted to directory buckets.

## Critical Command Rule — Explicit Canonical Paths
- Commands MUST use explicit canonical paths (no pathspec shortcuts such as `docs/project`).
- Population Gate MUST scan using explicit canonical paths.

## REPO ROOT ANCHOR (PowerShell)
```powershell
$root = git rev-parse --show-toplevel
Set-Location $root
git rev-parse --show-toplevel
git rev-parse --show-prefix
Get-Location
```

## CANONICAL PROOF COMMANDS

### A) Control Deck Existence Proof
```bash
git -C "$(git rev-parse --show-toplevel)" ls-files <DOCS_ROOT>/project/VISION.md <DOCS_ROOT>/project/EPICS.md <DOCS_ROOT>/project/NEXT.md
```

### B) Population Gate (Control Deck only)
```bash
git -C "$(git rev-parse --show-toplevel)" grep -n -i -E "(TBD|TODO|TEMPLATE|PLACEHOLDER|FILL IN|COMING SOON|XXX|FIXME|TO BE DETERMINED|<fill)" -- <DOCS_ROOT>/project/VISION.md <DOCS_ROOT>/project/EPICS.md <DOCS_ROOT>/project/NEXT.md
```

### C) Test Catalog Canonical Proof
```bash
git -C "$(git rev-parse --show-toplevel)" ls-files <DOCS_ROOT>/testing/test-catalog.md
```

### D) Mandatory Location Proof
```bash
git -C "$(git rev-parse --show-toplevel)" rev-parse --show-toplevel
git -C "$(git rev-parse --show-toplevel)" rev-parse --show-prefix
```

---

## Universal Command Runner (preferred)

`run-vibe.ps1` is the path-agnostic way to invoke any kit tool. Use it instead of hardcoding `<DOCS_ROOT>` paths.

- Works for `docs/`, `docs-engineering/`, and nested DOCS_ROOT layouts (e.g., `LessonWriter2.0/docs-engineering`)
- Avoids hardcoded paths
- Uses the repo's embedded vibe-coding subtree tools
- All named flags (`-WriteReport`, `-Mode`, `-StartSession`, etc.) bind correctly in PS 5.1

`<SUBTREE>` is your repo's vibe-coding subtree directory ending in `/vibe-coding` (e.g., found by searching for `VIBE-CODING.VERSION.md`).

**Discovery pattern (PowerShell):**
```powershell
$runner = Get-ChildItem -Path (git rev-parse --show-toplevel) -Recurse -Filter "run-vibe.ps1" | Where-Object { $_.FullName -match 'vibe-coding[\\/]tools[\\/]' } | Select-Object -First 1 -ExpandProperty FullName
```

**Canonical commands (path-independent):**

| Trigger | Command |
|---------|--------|
| RUN START OF SESSION DOCS AUDIT | `powershell -NoProfile -ExecutionPolicy Bypass -File <SUBTREE>/tools/run-vibe.ps1 -Tool session-start` |
| RUN END OF SESSION | `powershell -NoProfile -ExecutionPolicy Bypass -File <SUBTREE>/tools/run-vibe.ps1 -Tool end-session -WriteReport` |
| RUN SYNC forGPT | `powershell -NoProfile -ExecutionPolicy Bypass -File <SUBTREE>/tools/run-vibe.ps1 -Tool sync-forgpt` |
| RUN DOC AUDIT (Consumer) | `powershell -NoProfile -ExecutionPolicy Bypass -File <SUBTREE>/tools/run-vibe.ps1 -Tool doc-audit -Mode Consumer -StartSession` |
| RUN MID-SESSION RESET | No script — operator-driven protocol. See [protocol-v7.md § Mid-Session Reset](protocol-v7.md#mid-session-reset-operator-confusion-recovery) |

Add `-WhatIf` to preview without executing. Unlisted flags can be passed via `-ToolArgs @(...)`.

---

## SESSION START DOCS AUDIT (MANDATORY FIRST COMMAND)

When the user says **RUN START OF SESSION DOCS AUDIT**, Copilot runs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <SUBTREE>/tools/run-vibe.ps1 -Tool session-start
```

**What it does (chained, in order):**
1. **Audit current repo state** — inspects branch, tracked tree state, DOCS_ROOT wiring, kit version, packet artifacts, and session gates without modifying the repo.
2. **Advisory continuity proof check** — reads the repo-local clean-close proof when present and reports whether the previous session's clean close is valid, missing, stale, contradictory, or unverifiable.
3. **Kit version print + drift report** — reads `VIBE-CODING.VERSION.md`, reports version lag from current local refs when available, and surfaces Consumer-Kit Drift without auto-updating the subtree.
4. **Consumer doc-audit (hard fail)** — runs `doc-audit.ps1 -Mode Consumer` (with `-StartSession` if supported). If it fails, the session STOPS with a non-zero exit. Use `-SkipAudit` to bypass.
5. **Audit print + required actions** — outputs the session audit block and explicitly tells the operator what they need to do next when the repo is dirty, the kit is stale, the packet is stale/missing, or state is degraded/unverifiable. Clean-close proof state is advisory only and does not create a new hard stop.

**Optional flags:**
- `-SkipUpdate` — deprecated compatibility flag; session-start is audit-only by default and does not update the kit
- `-SkipAudit` — skip the Consumer doc-audit step (still prints kit version)
- `-Force` — deprecated compatibility flag; session-start is audit-only by default and does not mutate the repo
- `-WhatIf` — print-only mode: no doc-audit execution

**Important:** `RUN START OF SESSION DOCS AUDIT` no longer updates the kit or refreshes the packet automatically. If the audit reports stale kit or stale/missing packet state, you need to run the explicit repair or packet-sync action yourself before proceeding.

**Hard Stop rule:** If any other command is requested before the session audit has been run, reply:
> Hard Stop. Run **RUN START OF SESSION DOCS AUDIT** first.

### Fallback (if run-vibe unavailable)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <DOCS_ROOT>/vibe-coding/tools/session-start.ps1
```
Where `<DOCS_ROOT>` is `docs-engineering` or `docs` (whichever contains `vibe-coding/`).

---

## RUN KIT UPDATE (explicit consumer repair)

When the user says **RUN KIT UPDATE**, Copilot runs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <SUBTREE>/tools/run-vibe.ps1 -Tool kit-update
```

**What it does (chained, in order):**
1. **Preflight hard-stops** — verifies repo topology, blocks unresolved conflicts and in-progress git operations, classifies tracked dirt, and blocks unsafe forGPT edits before any mutation.
2. **Target verification** — verifies the target kit remote/ref, fetches that ref explicitly, reads the target kit version, and confirms required sentinel files exist before any subtree pull.
3. **Controlled subtree update** — runs `git subtree pull --prefix <DOCS_ROOT>/vibe-coding <remote> <ref> --squash` only after all preflight checks and verification pass.
4. **Post-update verification** — re-reads local kit version, re-checks sentinel parity, and confirms no unresolved conflicts remain.
5. **Boundary reminder** — prints the result and reminds the operator that packet sync was not run.

**Optional flags:**
- `-WhatIf` — verify the target and print the update plan without running the subtree pull
- `-ToolArgs @('-RemoteName','<remote>','-Ref','<ref>')` — override the auto-discovered kit remote/ref when needed

**Important:** `RUN KIT UPDATE` is the only Step 2 mutation path for embedded kit repair. It does not run packet sync, does not auto-stash broad dirty state, and does not bypass blocker gates.

### Fallback (if run-vibe unavailable)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <DOCS_ROOT>/vibe-coding/tools/kit-update.ps1
```

---

## RUN END OF SESSION (full closeout gate)

When the user says **RUN END OF SESSION**, Copilot runs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <SUBTREE>/tools/run-vibe.ps1 -Tool end-session
```

**What it does:**
1. **Fetch origin** — updates remote refs so branch checks are accurate.
2. **Evidence collection** — surfaces tracked changes, untracked items, non-merged branches, Remote Reality, Workspace Reality, and the combined clean-field verdict.
3. **Strict close result** — prints `CLEAN FIELD READY: YES` only when the full contract qualifies; any `CLEAN FIELD READY: NO` result exits nonzero.
4. **Clean-close proof maintenance** — writes the repo-local clean-close proof only after a real clean close, and removes any prior proof on a non-clean close.
5. **Optional report** — writes the same end-session report when `-WriteReport` is used.

**Optional flags:**
- `-WriteReport` — write a markdown status report under `<DOCS_ROOT>/status/`
- `-SkipFetch` — skip `git fetch origin` (use stale remote refs)
- `-WhatIf` — print-only mode: no fetch, no report written

**No deletes; no cleanup automation.**

### Fallback (if run-vibe unavailable)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <DOCS_ROOT>/vibe-coding/tools/end-session.ps1
```
Where `<DOCS_ROOT>` is `docs-engineering` or `docs` (whichever contains `vibe-coding/`).
