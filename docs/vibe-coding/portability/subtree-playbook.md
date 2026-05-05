# Subtree Integration Playbook

> **Scope:** How to add or update the vibe-coding bundle across repos.  
> **Key Rule:** Project-specific docs live OUTSIDE the subtree and are NEVER overwritten.

> **Shell Note:** Examples use bash syntax. On Windows PowerShell, git commands work identically; use `Get-ChildItem` instead of `ls`.

---

## 1-Minute Cheat Sheet

```bash
# ADD to new repo (one-time):
git subtree add --prefix=<DOCS_ROOT>/vibe-coding \
  https://github.com/ExampleOrg/vibe-coding-bundle.git main --squash

# UPDATE existing repo (safe pull):
git subtree pull --prefix=<DOCS_ROOT>/vibe-coding \
  https://github.com/ExampleOrg/vibe-coding-bundle.git main --squash

# VERIFY after update:
ls <DOCS_ROOT>/vibe-coding/standards/  # Should have research-standard.md
ls <DOCS_ROOT>/project/stack-profile.md  # Should NOT be touched
```

**Golden rule:** Subtree touches ONLY `<DOCS_ROOT>/vibe-coding/`. Project docs in `<DOCS_ROOT>/project/` and `<DOCS_ROOT>/research/` are YOURS.

---

## What Is and Isn't Part of the Bundle

### IN the Bundle (managed by subtree)

| Path | Contents |
|------|----------|
| `vibe-coding/protocol/` | Protocol docs (protocol-v7.md, etc.) |
| `vibe-coding/templates/` | Evidence pack, manual test, closeout templates |
| `vibe-coding/standards/` | Research standard, stack-profile standard |
| `vibe-coding/portability/` | This playbook |
| `vibe-coding/terminology/` | Dictionary template |
| `vibe-coding/README.md` | Bundle entry point |

### OUTSIDE the Bundle (project-specific, never overwritten)

| Path | Contents |
|------|----------|
| `<DOCS_ROOT>/project/` | VISION.md, EPICS.md, NEXT.md, stack-profile.md |
| `<DOCS_ROOT>/research/` | R-### docs, ResearchIndex.md |
| `<DOCS_ROOT>/status/` | Branch status, return packets |
| `<DOCS_ROOT>/forGPT/` | Generated packet for ChatGPT sessions (see below) |

> **forGPT Packet:** The `forGPT/` folder is a **generated mirror** of session-critical docs, NOT manually maintained stubs. Run `sync-forgpt.ps1` to refresh from canonical sources. See `Start-Here-For-AI.md § forGPT Packet: Generated, Safe, Portable` for lockdown guarantees and verification steps.
>
> **Owner-only exclusion:** `VIBE-KIT-SNAPSHOT.md` is owner/local-kit only and MUST NOT be distributed to or embedded in consumer repos or consumer forGPT packets.
>
> **DOCS_ROOT Detection:** If both `<DOCS_ROOT>/` and `docs/` exist, `<DOCS_ROOT>/` takes precedence (deterministic, no ambiguity).

---

## Docs Root Variants

Different repos use different docs folder names. The vibe-coding bundle supports both:

| Docs Root | Example Repos | Notes |
|-----------|---------------|-------|
| `<DOCS_ROOT>/` | AcmeApp, enterprise projects | Recommended for repos with separate runtime `docs/` folder |
| `docs/` | Most open-source, smaller projects | Simpler; use when no conflict with runtime docs |

### Critical Safety Rule

**Subtree sync MUST NEVER overwrite project-specific content:**

- `project/` — VISION.md, EPICS.md, NEXT.md, stack-profile.md belong to the project
- `research/` — R-### docs, ResearchIndex.md are project research artifacts
- `status/` — Branch status, return packets are project-specific
- `forGPT/` — Generated from manifest; regenerate with `sync-forgpt.ps1`

**If a repo already has these folders with content, leave them as-is.** The subtree only touches `<DOCS_ROOT>/vibe-coding/`.

Reformat to research standard (R-### naming, required sections) is allowed, but ONLY via explicit follow-up prompt with project owner approval—never automatically during subtree add/pull.

---

## Workflow 1: Add Vibe-Coding to a New Repo

### Prerequisites
- [ ] Clean working tree (`git status` shows nothing staged/modified)
- [ ] On a dedicated branch for the integration
- [ ] Know your target prefix (recommend: `<DOCS_ROOT>/vibe-coding`)

### Step 1: Create Target Folders

```bash
# Create project-specific folders (these stay yours)
mkdir -p <DOCS_ROOT>/project
mkdir -p <DOCS_ROOT>/research
mkdir -p <DOCS_ROOT>/status
```

### Step 2: Add the Subtree

```bash
# Set upstream URL (replace with your bundle repo)
UPSTREAM_URL="https://github.com/ExampleOrg/vibe-coding-bundle.git"

# Add subtree with squash (cleaner history)
git subtree add --prefix=<DOCS_ROOT>/vibe-coding $UPSTREAM_URL main --squash
```

### Step 3: Create Project-Specific Docs

Copy templates and fill in project-specific content:

```bash
# Create stack profile from standard
cp <DOCS_ROOT>/vibe-coding/standards/stack-profile-standard.md \
   <DOCS_ROOT>/project/stack-profile.md
# Edit stack-profile.md with your project's actual stack

# Create Control Deck docs
touch <DOCS_ROOT>/project/VISION.md
touch <DOCS_ROOT>/project/EPICS.md
touch <DOCS_ROOT>/project/NEXT.md
touch <DOCS_ROOT>/research/ResearchIndex.md
```

### Step 4: Verify Integration

```bash
# Confirm bundle structure
ls <DOCS_ROOT>/vibe-coding/protocol/
# Should show: protocol-v7.md, copilot-instructions-v7.md, etc.

ls <DOCS_ROOT>/vibe-coding/standards/
# Should show: research-standard.md, stack-profile-standard.md

# Confirm project docs are separate
ls <DOCS_ROOT>/project/
# Should show your project-specific files
```

### Step 5: Commit

```bash
git add .
git commit -m "docs: integrate vibe-coding bundle via subtree"
```

---

## Workflow 2: Update Vibe-Coding Without Overwriting Project Docs

### The Safe Update Rule

**Subtree pull only touches the subtree prefix.** Files outside `<DOCS_ROOT>/vibe-coding/` are never modified by the pull.

### Prerequisites
- [ ] Clean working tree
- [ ] On a dedicated update branch
- [ ] Know what changed upstream (check bundle repo commits)

### Step 1: Pull Updates

```bash
UPSTREAM_URL="https://github.com/ExampleOrg/vibe-coding-bundle.git"

git subtree pull --prefix=<DOCS_ROOT>/vibe-coding $UPSTREAM_URL main --squash
```

### Step 2: Review Changes

```bash
# See what changed
git diff HEAD~1 --stat

# Verify project docs untouched
git diff HEAD~1 -- <DOCS_ROOT>/project/
# Should show nothing

git diff HEAD~1 -- <DOCS_ROOT>/research/
# Should show nothing
```

### Step 3: Handle Conflicts (if any)

**Conflict strategy:**
- Inside `vibe-coding/` → Prefer upstream (bundle is authoritative)
- Outside `vibe-coding/` → Should never happen; if it does, STOP and investigate

```bash
# If conflicts in bundle files, accept upstream:
git checkout --theirs <DOCS_ROOT>/vibe-coding/path/to/file.md
git add <DOCS_ROOT>/vibe-coding/path/to/file.md

# Never accept "theirs" for project docs — they shouldn't conflict
```

### Step 4: Verify & Commit

```bash
# Verify bundle has new content
cat <DOCS_ROOT>/vibe-coding/standards/research-standard.md | head -20

# Verify project docs unchanged
git diff HEAD~1 -- <DOCS_ROOT>/project/stack-profile.md
# Should be empty

git commit -m "docs: update vibe-coding bundle from upstream"
```

---

## Overlay Pattern: Project Extensions

Sometimes you need project-specific extensions to bundle docs.

**Rule:** Extensions live OUTSIDE the bundle and LINK to bundle docs.

> **Invariant:** Repo-specific overlays (OVERLAY-INDEX.md, `<repo-name>.md`)
> MUST live at `<DOCS_ROOT>/overlays/`, NEVER inside `<DOCS_ROOT>/vibe-coding/`.
> See [OCTOPUS-INVARIANTS.md](../OCTOPUS-INVARIANTS.md) (authoritative).

### Example: Project-Specific Checklist

Don't edit `vibe-coding/session-start-checklist.md`. Instead:

```markdown
# <DOCS_ROOT>/project/session-checklist-local.md

> **Base checklist:** [session-start-checklist.md](../session-start-checklist.md)

## Additional Local Checks

- [ ] Verify <YourConnectionName>.config points to correct DB
- [ ] Check IIS Express is running on expected port
```

### Example: Project-Specific Gate Rules

Don't edit `vibe-coding/protocol/protocol-v7.md`. Instead:

```markdown
# <DOCS_ROOT>/project/gate-overrides.md

> **Base gates:** See stack-profile.md

## Project-Specific Gate Notes

- Playwright E2E requires VPN connection to reach DEV server
- MSBuild requires VS 2022 Developer Command Prompt
```

---

## Troubleshooting

### "Subtree merge commits make history messy"

Use `--squash` flag to collapse subtree commits into single merge commits.

### "I accidentally edited a file in the subtree"

Your edits will be lost on next subtree pull. Move project-specific content to `<DOCS_ROOT>/project/` instead.

### "Conflict in project docs during subtree pull"

This shouldn't happen. If it does:
1. STOP — something is misconfigured
2. Check if project docs accidentally got added to the bundle repo
3. Ensure `--prefix` matches exactly

### "Bundle has breaking changes"

1. Read the bundle CHANGELOG before pulling
2. Pull to a test branch first
3. Verify your `stack-profile.md` and templates still work
4. Update project docs if bundle requires new fields

---

## Interim Workflow: Before Bundle Repo Exists

> **Status:** As of 2026-02-06, the bundle currently lives inside `<YourProject>/<DOCS_ROOT>/vibe-coding/`. A dedicated `vibe-coding-bundle.git` repo does not yet exist.

If you need to integrate vibe-coding into another repo **before** the dedicated bundle repo is created, use `git subtree split`:

### Step 1: Create a Split Branch (in source repo)

```bash
# In the repo that has vibe-coding (e.g., <YourProject>)
cd /path/to/your-project-repo

# Extract vibe-coding into a standalone branch
git subtree split --prefix=<YourProject>/<DOCS_ROOT>/vibe-coding -b vibe-coding-bundle-temp
```

This creates a branch where `vibe-coding/` contents are at the root—exactly what a dedicated bundle repo would look like.

### Step 2: Add as Remote + Subtree (in target repo)

```bash
# In the target repo
cd /path/to/target-repo
git checkout -b integrate-vibe-coding

# Add source repo as temporary remote
git remote add source-temp /path/to/example-project-repo

# Fetch the split branch
git fetch source-temp vibe-coding-bundle-temp

# Add subtree
git subtree add --prefix=<DOCS_ROOT>/vibe-coding source-temp/vibe-coding-bundle-temp --squash
```

### Step 3: Clean Up

```bash
# Remove temporary remote from target repo
git remote remove source-temp

# Delete split branch from source repo
cd /path/to/example-project-repo
git branch -D vibe-coding-bundle-temp
```

### When Bundle Repo Is Created

Once `https://github.com/ExampleOrg/vibe-coding-bundle.git` exists:

1. Update your remote: `git remote set-url vibe-coding-upstream <new-url>`
2. Future pulls use standard workflow (see above)
3. No need to redo the subtree—just change the remote

---

## forGPT Packet Setup (Generated)

> **Purpose:** forGPT is a "single starting place" — one folder to upload to GPT with all session-critical docs.

### Key Principles

1. **Real content, not stubs.** Files are generated by copying from canonical sources via a manifest-driven sync script.
2. **Core vs Extra tiers.** Manifest entries have a `tier` field: "core" (session-start essentials) or "extra" (supporting context).
3. **Project-specific docs are YOURS.** The sync only writes to `<DOCS_ROOT>/forGPT/`. It never touches `project/`, `research/`, or `status/`.

### DOCS_ROOT Portability

The sync script auto-detects DOCS_ROOT:
- If `<DOCS_ROOT>/` exists → DOCS_ROOT = `docs-engineering`
- Else if `docs/` exists → DOCS_ROOT = `docs`
- Else STOP (blocker)

**All repos use the same script; only the manifest source paths differ.**

### Core vs Extra Files

| Tier | Description | Typical Count |
|------|-------------|---------------|
| **CORE** | Session-start essentials: minimum set to begin productive work | 13 |
| **EXTRA** | Supporting docs: useful but not required for startup | 0+ |

**CORE set (13 files, typical):**
- Start-Here-For-AI.md (entry point)
- VISION.md, EPICS.md, NEXT.md (Control Deck)
- protocol-v7.md, working-agreement-v1.md, copilot-instructions-v7.md (workflow rules)
- prompt-lifecycle.md, session-start-checklist.md, PAUSE.md (session management)
- ResearchIndex.md, branches.md (context)
- vibe-coding.README.md (bundle entry point)

### Setup Steps

#### 1. Create the forGPT folder and manifest

```bash
mkdir -p <DOCS_ROOT>/forGPT
```

Copy the template manifest from the bundle:

```bash
cp <DOCS_ROOT>/vibe-coding/tools/forgpt.manifest.template.json \
   <DOCS_ROOT>/forGPT/forgpt.manifest.json
```

Or create one manually (see example below).

#### 2. Edit the manifest for your repo

The manifest maps canonical sources to forGPT destinations with tier designation:

```json
{
  "$schema": "forgpt-manifest-v1",
  "description": "forGPT packet for <your-project>",
  "portability": {
    "docsRootDetection": "auto",
    "supportedRoots": ["docs-engineering", "docs"]
  },
  "tiers": {
    "core": "Session-start essentials",
    "extra": "Supporting docs"
  },
  "files": [
    { "src": "<DOCS_ROOT>/project/VISION.md", "dest": "VISION.md", "tier": "core" },
    { "src": "<DOCS_ROOT>/project/EPICS.md", "dest": "EPICS.md", "tier": "core" },
    { "src": "<DOCS_ROOT>/project/NEXT.md", "dest": "NEXT.md", "tier": "core" },
    { "src": "<DOCS_ROOT>/vibe-coding/protocol/protocol-v7.md", "dest": "protocol-v7.md", "tier": "core" }
  ]
}
```

**Note:** Replace `<DOCS_ROOT>` with actual path (e.g., `docs-engineering`).

#### 3. Run the sync script

```powershell
# From anywhere in the repo:
.\<DOCS_ROOT>\vibe-coding\tools\sync-forgpt.ps1

# Script STOPS on dirty git tree by default. Use -Force to override:
.\<DOCS_ROOT>\vibe-coding\tools\sync-forgpt.ps1 -Force

# Preview without making changes:
.\<DOCS_ROOT>\vibe-coding\tools\sync-forgpt.ps1 -WhatIf
```

#### 4. Verify VERSION-MANIFEST.md

After sync, check `<DOCS_ROOT>/forGPT/VERSION-MANIFEST.md`:
- **Generated timestamp** — should be today
- **Git commit** — should match your HEAD
- **CORE files** — should be 13 (or your expected count)
- **TOTAL files** — CORE + EXTRA
- **SHA256 hashes** — prove content integrity

### Safety Guarantees

The sync script:
- ✅ Only writes to `<DOCS_ROOT>/forGPT/`
- ✅ Only copies files listed in the manifest
- ✅ Never deletes `forgpt.manifest.json`
- ✅ **STOPs on dirty git tree** (unless `-Force`)
- ✅ STOPs if any source file is missing
- ✅ Validates destination paths stay inside forGPT

### What Goes in the Manifest (by tier)

**CORE (session-critical, always include):**
- Start-Here-For-AI.md
- VISION.md, EPICS.md, NEXT.md
- protocol-v7.md, working-agreement-v1.md, copilot-instructions-v7.md
- session-start-checklist.md, PAUSE.md, prompt-lifecycle.md
- ResearchIndex.md, branches.md, vibe-coding.README.md

**EXTRA (supporting, optional):**
- FILE-VERSIONING.md (if versioning is complex)
- Protocol-primer.md (if quick-start needed)

**Do NOT include (too large/volatile):**
- Full research docs (R-###-*.md)
- Handoff packets (load on demand)
- KB documents (reference via index)

### GPT-ROLE.md — Standard Delivery Model

`GPT-ROLE.md` defines the Project GPT's role, boundaries, and compressed Octopus mental model. It is **consumer-owned**, not generated by the kit.

**Kit provides:** Template at `vibe-coding/templates/gpt-role-template.md`.

**Consumer delivers:**

1. Copy the kit template to a consumer-owned location:
   ```
   <DOCS_ROOT>/project/GPT-ROLE.md
   ```
2. Optionally append project-specific role notes or context.
3. Add a manifest entry to `<DOCS_ROOT>/forGPT/forgpt.manifest.json`:
   ```json
   { "src": "project/GPT-ROLE.md", "dest": "GPT-ROLE.md", "tier": "core" }
   ```
4. Run session-start — `sync-forgpt.ps1` picks it up automatically.

**Ownership rules:**
- The consumer owns the copy and may customize it.
- The kit does not generate, inject, or overwrite `GPT-ROLE.md`.
- `sync-forgpt.ps1` delivers it via the manifest like any other file.
- This follows the same ownership model as overlays.

---

## Research Reformat Policy

> **Rule:** You may reformat existing research docs to match [research-standard.md](../standards/research-standard.md), but ONLY by explicit selection.

### Allowed

- Add standard header to an existing R-### doc
- Fix markdown formatting (tables, code blocks)
- Update ResearchIndex.md to reflect changes

### NOT Allowed

- Sweeping rewrites of all research docs without explicit prompt
- Changing research conclusions or evidence
- Moving/renaming research docs without indexing update

### Safe Backfill Flow

1. List docs needing headers: `Get-ChildItem <DOCS_ROOT>/research/R-*.md`
2. For each doc (explicitly selected):
   - Add header block at top
   - Do NOT change content below header
3. Update ResearchIndex.md in same commit

---

## Recommended Folder Structure

> **Note:** Some repos use `docs/` instead of `<DOCS_ROOT>/`. The structure is the same; only the root name differs.

```
<DOCS_ROOT>/                # docs-engineering OR docs
├── vibe-coding/            # ← SUBTREE (bundle-managed)
│   ├── protocol/
│   ├── templates/
│   ├── standards/
│   ├── portability/
│   ├── tools/              # sync-forgpt.ps1, doc-audit.ps1
│   └── README.md
├── project/                # ← PROJECT-SPECIFIC (yours)
│   ├── VISION.md
│   ├── EPICS.md
│   ├── NEXT.md
│   ├── stack-profile.md
│   └── tech-debt-and-future-work.md
├── research/               # ← PROJECT-SPECIFIC (yours)
│   ├── ResearchIndex.md
│   └── R-###-*.md
├── status/                 # ← PROJECT-SPECIFIC (yours)
│   └── branches.md
├── forGPT/                 # ← GENERATED (via sync-forgpt.ps1)
│   ├── forgpt.manifest.json
│   ├── VERSION-MANIFEST.md
│   └── *.md (copied from canonical sources)
└── Start-Here-For-AI.md    # ← Entry point
```
