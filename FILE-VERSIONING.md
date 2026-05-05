# File Versioning System — Vibe-Coding Protocol

> **File Version:** 2026-02-26

---

## Purpose

The vibe-coding protocol files are shared across multiple projects. This versioning system ensures:
1. Easy identification of when files were last modified
2. Detection of stale copies (especially in `<DOCS_ROOT>/forGPT/`)
3. Cross-project synchronization awareness

---

## Version Header Format

Every shared protocol file includes a visible version block at the top (after the title):

```markdown
> **File Version:** YYYY-MM-DD
```

**Fields:**
- **File Version:** Date of last meaningful change to THIS file (YYYY-MM-DD format)

**Bundle version:** The kit bundle version is tracked **only** in [`VIBE-CODING.VERSION.md`](VIBE-CODING.VERSION.md). Per-file `Bundle:` tags were removed in v7.2.2 to prevent version drift across files.

---

## Files That Require Version Headers

These shared/portable files must have version headers:

| File | Location |
|------|----------|
| `Start-Here-For-AI.md` | `<DOCS_ROOT>/` (consumer-provided; not stored in kit head) |
| `README.md` | `<DOCS_ROOT>/vibe-coding/` |
| `FILE-VERSIONING.md` | `<DOCS_ROOT>/vibe-coding/` |
| `protocol-v7.md` | `<DOCS_ROOT>/vibe-coding/protocol/` |
| `copilot-instructions-v7.md` | `<DOCS_ROOT>/vibe-coding/protocol/` |
| `working-agreement-v1.md` | `<DOCS_ROOT>/vibe-coding/protocol/` |
| `return-packet-gate.md` | `<DOCS_ROOT>/vibe-coding/protocol/` |
| `stay-on-track.md` | `<DOCS_ROOT>/vibe-coding/protocol/` |
| `required-artifacts.md` | `<DOCS_ROOT>/vibe-coding/protocol/` |
| `alignment-mode.md` | `<DOCS_ROOT>/vibe-coding/protocol/` |

**Note:** Project-specific files (VISION.md, EPICS.md, NEXT.md) use their own "Last Updated" field and are NOT part of this system.

---

## Update Rules (MANDATORY)

When modifying any versioned file, you MUST:

### 1. Update the File Version Date
Change the date in the version header to today's date:
```markdown
> **File Version:** 2026-02-09
```

### 2. Update forGPT Copy (if exists)
If the file has a copy in `<DOCS_ROOT>/forGPT/`, update that copy:
```powershell
Copy-Item "<DOCS_ROOT>/vibe-coding/protocol/protocol-v7.md" -Destination "<DOCS_ROOT>/forGPT/"
```

### 3. Update VERSION-MANIFEST.md
Update the manifest table in `<DOCS_ROOT>/forGPT/VERSION-MANIFEST.md`:
- Change the file's version date in the table
- Update the `Generated:` date at the top

### 4. Update VIBE-CODING.VERSION.md (for significant changes)
If the change affects workflow rules or gates, bump the bundle version in:
- `VIBE-CODING.VERSION.md` (the **sole** bundle version authority)

---

## Version Manifest (Cross-Agent Sync)

The file `<DOCS_ROOT>/forGPT/VERSION-MANIFEST.md` is the single source of truth for cross-agent version confirmation.

**Why a manifest?**
- ChatGPT and Copilot don't communicate directly — Stephen mediates
- The manifest lets ChatGPT report its versions without parsing every file
- Copilot can quickly compare manifest dates against canonical sources
- Main risk mitigated: forgetting to update GPT after updating protocol files

**ChatGPT prints at session start:**
```
📋 GPT Protocol Versions (from VERSION-MANIFEST.md):
- Manifest Generated: 2026-01-18
- protocol-v7.md: 2026-01-18
- working-agreement-v1.md: 2026-01-18

🤝 HANDSHAKE REQUEST: Please paste this to Copilot and ask:
"Confirm protocol versions match canonical sources"
```

**Copilot responds with handshake result:**
- `✅ VERSION HANDSHAKE: PASS` — ready for work
- `⚠️ VERSION HANDSHAKE: MISMATCH` — lists differences and action items

---

## Session-Start Handshake (MANDATORY)

**No work prompts are executed until the handshake passes.**

1. **GPT reports versions** (first response after file upload)
2. **Stephen pastes to Copilot** with "Confirm protocol versions match"
3. **Copilot checks canonical sources** and responds PASS or MISMATCH
4. **If MISMATCH:** Copilot updates forGPT, Stephen re-uploads, repeat handshake

See `<DOCS_ROOT>/forGPT/VERSION-MANIFEST.md` for the complete handshake protocol.

---

## Stale Copy Detection

A copy is **stale** if its File Version date is older than the canonical source.

**Detection command:**
```powershell
# Compare forGPT copy date vs canonical
Select-String -Path "<DOCS_ROOT>/forGPT/protocol-v7.md" -Pattern "File Version:" | Select-Object Line
Select-String -Path "<DOCS_ROOT>/vibe-coding/protocol/protocol-v7.md" -Pattern "File Version:" | Select-Object Line
```

**If stale:**
1. Copilot reports: "⚠️ forGPT/protocol-v7.md is stale (2026-01-15 vs canonical 2026-01-18)"
2. Copy updated file to forGPT: `Copy-Item "<DOCS_ROOT>/vibe-coding/protocol/protocol-v7.md" -Destination "<DOCS_ROOT>/forGPT/"`
3. Notify Stephen to re-upload to ChatGPT session

---

## Cross-Project Sync

When copying the vibe-coding bundle to another project:

1. Copy entire `<DOCS_ROOT>/vibe-coding/` folder
2. Copy `<DOCS_ROOT>/Start-Here-For-AI.md`
3. Verify all File Version dates match the source project
4. Update any project-specific sections (Green Gate commands, Hot Files list, etc.)

---

## Version History

| Date | Change |
|------|--------|
| 2026-02-09 | Removed per-file Bundle tags; VIBE-CODING.VERSION.md is sole version authority |
| 2026-01-18 | Initial versioning system created |
