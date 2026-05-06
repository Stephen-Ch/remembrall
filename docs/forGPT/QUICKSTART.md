# Quickstart — Add vibe-coding to your repo in ~5 minutes

> **Kit repo:** `https://github.com/Stephen-Ch/vibe-coding-kit.git`

---

## 1. Preconditions

- **Git** installed (2.x+).
- **PowerShell** available (Windows built-in; macOS/Linux: `pwsh`).
- You can create a branch or PR in your target repo.

---

## 2. Install (one-time subtree add)

Pick a `<DOCS_ROOT>` — typically `docs` or `docs-engineering` — and run:

```powershell
git subtree add --prefix=<DOCS_ROOT>/vibe-coding `
  https://github.com/Stephen-Ch/vibe-coding-kit.git release/consumer-payload --squash
```

This creates `<DOCS_ROOT>/vibe-coding/` containing the full kit: protocol docs, templates, standards, and tooling. Everything outside that directory is yours and will never be overwritten by kit updates.

---

## 3. Verify

### Run session-start

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File <DOCS_ROOT>/vibe-coding/tools/run-vibe.ps1 -Tool session-start
```

**Success** = it prints `KitVersion: v…` and exits without fatal errors.

### Run doc-audit

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File <DOCS_ROOT>/vibe-coding/tools/run-vibe.ps1 -Tool doc-audit -Mode Consumer -StartSession
```

**Require PASS** — fix any failures before continuing.

---

## 4. First-day workflow

| Step | Command / action |
|------|-----------------|
| **Start of session** | Say **RUN START OF SESSION DOCS AUDIT** — your AI agent runs session-start (step 3 above). |
| **Work** | One prompt at a time; follow the protocol gates. For the minimum mandatory rules, see [hard-rules.md](protocol/hard-rules.md). |
| **End of session** | Say **RUN END OF SESSION** — runs `run-vibe.ps1 -Tool end-session -WriteReport` to verify repo hygiene. |

---

## 5. Updating the kit

When a new kit version is available, pull it:

```powershell
git subtree pull --prefix=<DOCS_ROOT>/vibe-coding `
  https://github.com/Stephen-Ch/vibe-coding-kit.git release/consumer-payload --squash
```

After updating:

1. Rerun **session-start** and **doc-audit** (step 3) to confirm everything is clean.
2. If you skip updating manually, session-start's **kit-version lag WARN** will alert you when your local kit version falls behind the remote. That's your signal to pull.

### Legacy consumer first-step warning

If this is an **existing** consumer repo that has not yet been migrated to the payload update path, do **not** start with old `tentacles on`.

Perform a one-time manual subtree migration first:

```powershell
git subtree pull --prefix=<DOCS_ROOT>/vibe-coding `
  https://github.com/Stephen-Ch/vibe-coding-kit.git release/consumer-payload --squash
```

Then verify local `tools/kit-update.ps1` defaults to `release/consumer-payload`, and only after that return to normal `tentacles on` startup.

For the full pilot checklist (standard + LessonWriter-shaped paths, stop conditions, rollback notes), see [MIGRATION-INSTRUCTIONS.md](MIGRATION-INSTRUCTIONS.md) section **Legacy Consumer One-Time Migration Pilot**.

> `release/consumer-payload` is the filtered consumer distribution branch. `main` remains the kit source/control-plane branch and is not the consumer update source.
>
> This quickstart update-path change does not by itself authorize immediate rollout to real consumers.

---

## 6. Troubleshooting

- **The kit's internal planning directory is not for consumers.** Do not reference it in your docs — `doc-audit` will warn. See the kit repo's own README for details.
- **Subtree merge conflicts on update?** Resolve normally (`git mergetool` or manual edit), then commit. The subtree prefix must stay at `<DOCS_ROOT>/vibe-coding`.
- **session-start can't find DOCS_ROOT?** Ensure your subtree lives at `<DOCS_ROOT>/vibe-coding/` where `<DOCS_ROOT>` is `docs`, `docs-engineering`, or the repo root.

---

## Further reading

- [README.md](README.md) — kit entry point
- [protocol/protocol-v7.md](protocol/protocol-v7.md) — full protocol rules
- [protocol-lite.md](protocol-lite.md) — quick reference
- [templates/prompt-template.md](templates/prompt-template.md) — prompt template
- [DOCS-HEALTH-CONTRACT.md](DOCS-HEALTH-CONTRACT.md) — documentation health contract
- [critical-transition-checklist.md](critical-transition-checklist.md) — preflight for critical transitions (not a per-prompt gate)
