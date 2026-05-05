# Session Start Callout — Consumer Snippet

> Paste this block into your `Start-Here-For-AI.md` to hard-wire the automated session-start chain.

## RUN START OF SESSION DOCS AUDIT

**Automated path (preferred):**

    powershell -NoProfile -ExecutionPolicy Bypass -File <SUBTREE>/tools/run-vibe.ps1 -Tool session-start

Chains: kit update → forGPT sync → doc-audit -StartSession → session audit block. No manual steps needed.

**Manual fallback** (only if `run-vibe.ps1` is unavailable):

    powershell -NoProfile -ExecutionPolicy Bypass -File <DOCS_ROOT>/vibe-coding/tools/session-start.ps1
