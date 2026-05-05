# Hard Rules — Mandatory Gates

> Curated extraction of minimum mandatory gates.
> **[protocol-v7.md](protocol-v7.md) is authoritative; wins on conflict.**

## Prompt Execution Sequence

1. **PROMPT-ID** — first line
2. **Prompt Review Gate** — What / Best next step? / Confidence / Work state
3. **Command Lock** — no commands before gate
4. **Proof-of-Read** — file + quote + "Applying: <rule>"
5. **Comprehension Self-Check** — what changes / out of scope / next command
6. **Work** — execute tasks
7. **Green Gate** — build + tests before commit
8. **Summary** — what changed, files touched

→ [Core Rules](protocol-v7.md#core-rules-non-negotiable)

## STOP Conditions

- Confidence below threshold → STOP
- Best next step? NO → STOP
- Non-zero exit → smallest fix
- Evidence contradicts prompt → [STOP/PIVOT](protocol-v7.md#d-stop--pivot-rule-when-evidence-contradicts-prompt)
- Drift trigger → Reset Ritual → [Focus Control](protocol-v7.md#focus-control)
- **Project-identity mismatch → STOP** — Before acting on a prompt, verify it targets the current repo/workspace. If the prompt names another project, references paths/docs/branches/story IDs that belong elsewhere, or is otherwise inconsistent with the current workspace identity, STOP and report the mismatch. Do not proceed until resolved.

## Confidence Thresholds

- Docs/research: ≥95% — Runtime/code: ≥99% — Below: STOP → RESEARCH-ONLY

→ [Tiered Confidence Gate](protocol-v7.md#no-guessing--tiered-confidence-gate-mandatory)

## RESEARCH-ONLY Mode

- **Allowed:** read_file, grep_search, list_dir, git log/diff/status
- **Forbidden:** editing code, PRs with code changes, state-modifying builds
- **Exit:** Evidence Pack + confidence ≥95%

→ [RESEARCH-ONLY Command Lock](protocol-v7.md#research-only-command-lock-mandatory)

## Report Formatting

- One continuous markdown document, PROMPT-ID through summary
- ZERO fenced code blocks (4-space indentation instead)
- **Scope:** This rule applies to completion reports. When producing a prompt for Stephen to copy, follow the [Prompt Output Contract](working-agreement-v1.md#prompt-output-contract-mandatory-formatting) instead.

→ [Response Structure](protocol-v7.md#response-structure)

## Cross-References

[protocol-v7.md](protocol-v7.md) · [PROTOCOL-INDEX.md](PROTOCOL-INDEX.md) · [copilot-instructions-v7.md](copilot-instructions-v7.md) · [protocol-lite.md](../protocol-lite.md)
