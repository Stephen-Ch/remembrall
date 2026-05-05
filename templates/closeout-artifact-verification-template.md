# Closeout Artifact Verification Template

## PROMPT REVIEW GATE + COMMAND LOCK (MANDATORY FIRST OUTPUT)
Every closeout report must begin with these four lines before any commands, edits, or verification steps:
What: <1-line plan>
Best next step? YES/NO
Confidence: <percentage>%
Command Lock satisfied? YES/NO (STOP immediately if NO)
Do not run git/npm/verification commands until the four-line gate is printed and passes.

Every S2C (merge/closeout) completion report MUST include this table:

## Artifact Verification

| Artifact | Expected Location | Verified On Main | Key String/Check |
|----------|-------------------|------------------|------------------|
| (file 1) | path/to/file.ts   | ✅ / ❌          | "key string"     |
| (file 2) | path/to/file.md   | ✅ / ❌          | "key string"     |

## Verification Steps

1. After merge, run: `git -C "$(git rev-parse --show-toplevel)" ls-files | Select-String "<filename>"`
2. Open file and confirm key content exists
3. Run Green Gate: `npm run test` + `npm run build` (from root or app directory as needed)
4. PASS only if narrative uses directory buckets (no filenames) AND raw evidence outputs are included verbatim.

## If Verification Fails

- Do NOT mark S2C complete
- Report missing artifacts
- Propose recovery steps

## Report Required Fields (Must Appear in Completion Report)
- Commit hash + subject for the merge prompt
- `git status --porcelain` output showing the tree is clean
- `git diff --name-only` output listing touched files
- Results of `npm run test` and `npm run build`
- If specs were touched: paste each spec’s `@human` line and confirm the catalog entry was updated

---
## Closeout Checklist Gate (MANDATORY before marking story COMPLETE)

**Purpose:** Ensure clean handoffs and safe rollback capability.

Every story closeout MUST verify these items (copy this checklist into your completion report):

### Control Deck Alignment
- [ ] **NEXT.md updated** — Active story moved to PARKED/COMPLETE, next step cleared or updated
- [ ] **EPICS.md checked** — Epic description still matches shipped functionality (update if drifted)
- [ ] **VISION.md verified** — No new placeholders introduced

### Rollback Safety
- [ ] **Rollback steps documented** — List commits to revert OR files to remove for surgical rollback
- [ ] **Rollback tested mentally** — Confirm reverting listed commits would cleanly undo the feature

### Evidence Trail
- [ ] **Test evidence recorded** — Final test count (X SUCCESS, Y FAILED) in story doc or completion report
- [ ] **Green Gate passed** — `npm run test` + `npm run build` both passed
- [ ] **Decision log entry** — Key decisions documented with rationale

### Completion Quality
- [ ] **Wired vs foundation-only noted** — If feature is partially wired, document what works vs what's scaffolding
- [ ] **Deferred items listed** — Any STRETCH steps not completed are explicitly listed for future work
- [ ] **Flake suspect reported** — Include "Flake suspect? YES/NO" in footer

### Population Gate (final scan)
- [ ] **No new placeholders** — Scan Control Deck files for TBD/TODO/TEMPLATE/PLACEHOLDER markers

**Closeout Checklist Location:** Include completed checklist in story doc's "Closeout" section or completion report.

---