# Alignment Mode — Vibe-Coding Protocol

## Purpose
Alignment Mode is triggered when `<DOCS_ROOT>/project/NEXT.md` is missing, unclear, or outdated. This prevents coding work when the active story/next step is ambiguous.

## When to Enter Alignment Mode

STOP coding and enter Alignment Mode if:
- `<DOCS_ROOT>/project/NEXT.md` is missing
- ACTIVE STORY ID is unclear or conflicts with repo state
- NEXT STEP is ambiguous or too large (not a single tiny step)
- DoD is missing or unmeasurable

## Return Packet Gate Decision Point

**Before exiting Alignment Mode**, check if triggers require research first:

| Trigger | Action |
|---------|--------|
| Hot-file work (SignalR, GameRepository, Main.js, identity) | → Run Return Packet Gate |
| High uncertainty / recent regressions in this area | → Run Return Packet Gate |
| Cross-system work (backend + frontend + database) | → Run Return Packet Gate |
| Simple/familiar domain, low risk | → Proceed without return packets |

**If triggers present:** Run the Return Packet Gate first. See **[return-packet-gate.md](return-packet-gate.md)** for the 4-party handoff flow and prompt templates.

**If no triggers:** Proceed to 3-Party Approval Gate below.

## 3-Party Approval Gate (Canonical)

Before resuming coding work from Alignment Mode, all three parties must approve:

**A) Stephen Approval (product intent):**
- [ ] Vision approved (`<DOCS_ROOT>/project/VISION.md` exists or template completed; Non-Goals present)
- [ ] Active Epic + Active Story ID chosen
- [ ] `<DOCS_ROOT>/project/NEXT.md` has Active Story + Next Step + DoD + Scope boundaries

**B) ChatGPT Approval (prompt planning):**
- [ ] ChatGPT confirms NEXT STEP is tiny/testable + matches current repo state
- [ ] Prompt will cite `<DOCS_ROOT>/project/NEXT.md` (ACTIVE STORY + NEXT STEP)

**C) Copilot Approval (feasibility + safety):**
- [ ] Copilot confirms feasibility, hot-file risk understood, TDD path clear
- [ ] Copilot confirms repo safety assumptions (clean tree, branch state)

**Gate Rule:** If any checkbox is not checked → STOP coding and stay in Alignment Mode. Do NOT proceed with coding work until all three parties have approved.

## Questions to Ask Stephen (Operator)

Ask these questions to clarify the active story:

1. **What is the active story?** (Story ID + 1-sentence summary)
2. **What is the next step?** (Single tiny TDD step or docs-only change)
3. **What is the Definition of Done?** (What proof confirms this step is complete?)
4. **What are the scope guardrails?** (Which files/folders are in-scope vs out-of-scope?)
5. **What constraints apply?** (Time limits? Breaking changes allowed? UX consistency requirements?)

## Questions to Ask Copilot (Repo State)

Before coding, verify repo state with Copilot:

1. **What branch are we on?** (git branch --show-current)
2. **What are the last 3 commits?** (git log --oneline -3)
3. **Are there open PRs or feature branches?** (git branch -a)
4. **Are there failing tests?** (npm run test)
5. **Does the NEXT STEP conflict with recent changes?** (git log --oneline -10 --grep="<related keywords>")

## Populate Control Deck (Remediation for Population Gate FAIL)

**Threshold Remediation Checklist:**

If Population Gate FAIL due to word-count thresholds (see [required-artifacts.md](required-artifacts.md) for exact thresholds):

**<DOCS_ROOT>/project/VISION.md threshold failures:**
- **Purpose < 25 words** → Ask Stephen: "What problem does this project solve? Who benefits and how?" Expand answer to >= 25 words.
- **North Star < 25 words** → Ask Stephen: "What does success look like in 1-3 years?" Expand to >= 25 words.
- **User Promise < 25 words** → Ask Stephen: "What experience will users have?" Expand to >= 25 words.
- **Non-Goals < 10 words each** → Ask Stephen: "What are 2 explicit things we are NOT doing?" Each constraint >= 10 words.

**<DOCS_ROOT>/project/EPICS.md threshold failures:**
- **Epic description < 15 words** → Ask Stephen: "What is the goal of this epic? How will we know it's successful?" Expand to >= 15 words with goals + success criteria.

**<DOCS_ROOT>/project/NEXT.md threshold failures:**
- **NEXT STEP < 10 words** → Ask Stephen: "What is the next tiny TDD step or docs-only change?" Expand to >= 10 words.
- **DoD < 10 words** → Ask Stephen: "What proof confirms this step is complete?" Expand to >= 10 words with verifiable criteria.
- **Done When item < 6 words** → Ask Stephen: "How will we verify this item?" Expand each item to >= 6 words with YES/NO proof.
- **Last Updated date invalid** → Fix to YYYY-MM-DD format (e.g., 2026-01-04); rerun Doc Audit.

**Paraphrasing Rule:** Use Stephen's exact words when populating. Do NOT introduce placeholder tokens ("TBD", "TODO") from paraphrasing Stephen's speech.

**Placeholder Scan:** Before exiting remediation, run the canonical placeholder scan command from [required-artifacts.md](required-artifacts.md) "Control Deck Population Gate" section:

  grep -iE '(TBD|TODO|TEMPLATE|PLACEHOLDER|FILL IN|COMING SOON|XXX|FIXME|TO BE DETERMINED|<fill)' <DOCS_ROOT>/project/VISION.md <DOCS_ROOT>/project/EPICS.md <DOCS_ROOT>/project/NEXT.md

If grep finds markers, STOP and remediate before coding. If no match (grep exits 1), proceed to threshold verification.

**Verification:** After remediation, rerun Population Gate check. If PASS → exit Alignment Mode. If FAIL → identify remaining failures and iterate.

## Portability Note

If <DOCS_ROOT>/project/VISION.md, <DOCS_ROOT>/project/EPICS.md, or <DOCS_ROOT>/project/NEXT.md exist elsewhere in the repo (scattered or misplaced), use the Doc Discovery + Migration section below to locate and migrate into <DOCS_ROOT>/project/. Do not invent new content to pass gates; discover and migrate existing planning docs first.

## Exit Criteria

Alignment Mode completes when:
- `<DOCS_ROOT>/project/VISION.md` exists (or placeholders created using templates)
- `<DOCS_ROOT>/project/EPICS.md` exists (or placeholders created using templates)
- `<DOCS_ROOT>/project/NEXT.md` exists with clear ACTIVE STORY ID, NEXT STEP, DoD, scope guardrails, "done when"
- Repo state verified (clean tree, tests pass, no conflicts with <DOCS_ROOT>/project/NEXT.md)

After Alignment Mode, resume normal coding workflow starting with the NEXT STEP from `<DOCS_ROOT>/project/NEXT.md`.

## Doc Discovery + Migration (when Control Deck docs are missing)

### A) When to use (trigger)
- **Trigger:** Start-of-Session Doc Audit fails because `<DOCS_ROOT>/project/VISION.md` and/or `<DOCS_ROOT>/project/EPICS.md` and/or `<DOCS_ROOT>/project/NEXT.md` are missing OR present-but-placeholders (TBD/TODO/empty).
- **Rule:** STOP coding. Enter Alignment Mode.

### B) Discovery targets (where to look first)
Repo hotspots to check:
- `docs/`, `README.md`, `/planning`, `/project`, `/product`, `/_notes`, `/_archive`, `/docs/old`, `/docs/status`
- Any "control deck" or "vision" folders
- Previous handoffs in `<DOCS_ROOT>/status/` and any `handoff-*.md`

### C) Discovery methods (how to search)
Search for canonical headings/markers:
- "Active Story ID:"
- "NEXT STEP:"
- "Definition of Done"
- "VISION" + "Non-goals"
- "EPIC-" or "Epic ID"

Command set for Copilot:
- `grep -r "Active Story ID:" docs/` (search for story headers)
- `grep -r "VISION" docs/ | grep -i "non-goal"` (find vision docs)
- `rg "EPIC-\d+" docs/` (find epic references)
- `git log --all --oneline --grep="vision\|epic\|story" -20` (recent planning commits)
- `git log --all --name-only --diff-filter=M -- "docs/**/*.md" | head -30` (most recently edited docs)

### D) Migration rules (how to move content into <DOCS_ROOT>/project/)
- **Create missing docs using templates:** Use `<DOCS_ROOT>/project/*.template.md` (do NOT invent new formats).
- **If docs exist elsewhere:**
  - Copy the relevant content into the correct `<DOCS_ROOT>/project/*` file(s).
  - Add a 1-line provenance note at top: "Migrated from `<path>` on YYYY-MM-DD".
  - Do NOT delete or rewrite the source doc unless Stephen explicitly requests.
- **If multiple candidates found:**
  - Prefer the most recently updated (`git log`), and note alternatives in a short "Other sources found" bullet list at bottom of the migrated doc.

### E) "Minimum populated" validation checklist (pass/fail)
Define the minimum "not-placeholder" requirements for each file:
- **<DOCS_ROOT>/project/VISION.md:** purpose + user promise + non-goals (no TBD).
- **<DOCS_ROOT>/project/EPICS.md:** at least 1 epic with an ID + short description + status.
- **<DOCS_ROOT>/project/NEXT.md:** Active Story ID + NEXT STEP + DoD + scope guardrails + Done When checklist (no TBD).

**If any fail → stay in Alignment Mode.**

### F) 3-Party Approval Gate (explicit)
After migration, require explicit approval from:
1. Stephen (vision/stories correct)
2. ChatGPT (alignment + tiny-step plan)
3. Copilot (feasibility + repo safety)

**Only after all 3 approvals → READY.**

### G) Exit criteria (how to leave Alignment Mode)
- Required artifacts exist AND are minimally populated AND Active Story/NEXT STEP are unambiguous.

## Populate Control Deck (when files exist but FAIL Population Gate)

### When to use (trigger)
- **Trigger:** Start-of-Session Doc Audit passes existence check (<DOCS_ROOT>/project/VISION.md, <DOCS_ROOT>/project/EPICS.md, <DOCS_ROOT>/project/NEXT.md all exist) BUT Population Gate **FAIL** (placeholders detected or minimum content requirements not met).
- **Rule:** STOP coding. Enter Alignment Mode to remediate placeholders.

### How to detect placeholders quickly
Search Control Deck files for these exact strings (case-insensitive):
- "TBD"
- "TODO"
- "TEMPLATE"
- "<fill"
- "placeholder"
- "(coming soon)"
- "[to be determined]"

Commands:
- `grep -i "TBD\|TODO\|TEMPLATE\|placeholder" <DOCS_ROOT>/project/VISION.md <DOCS_ROOT>/project/EPICS.md <DOCS_ROOT>/project/NEXT.md`
- `rg -i "TBD|TODO|TEMPLATE|placeholder" <DOCS_ROOT>/project/`

### Questions to ask Stephen (minimum to populate)
1. **<DOCS_ROOT>/project/VISION.md placeholders:**
   - "What is the project's purpose in 1-2 sentences?" (why it exists, what problem it solves)
   - "What is the North Star vision for 1-3 years?"
   - "What user experience do we promise?"
   - "What are we explicitly NOT building?" (at least 2 non-goals)

2. **<DOCS_ROOT>/project/EPICS.md placeholders:**
   - "What are the 3 most important epics?" (IDs + status + 1-sentence description each)
   - "Which epics are PLANNED vs IN PROGRESS vs COMPLETE?"

3. **<DOCS_ROOT>/project/NEXT.md placeholders:**
   - "What is the active story ID?"
   - "What is the next tiny step?" (single TDD step or docs-only change)
   - "What is the Definition of Done?"
   - "What are the scope guardrails?" (in-scope vs out-of-scope files/folders)
   - "What are the exit criteria for this step?" (Done When checklist)

### How to rewrite to PASS (without inventing product claims)
1. **Capture Stephen's intent from answers above,** but avoid inserting placeholder tokens (TBD/TODO/etc.). If Stephen defers a decision, record a sentence like "Decision deferred until <condition/date>" without using placeholder words.
2. **Keep it short:** 1-3 sentences per section (not essays)
3. **Use templates as guides:** Reference `<DOCS_ROOT>/project/*.template.md` for structure only (do NOT copy placeholder text)
4. **Verify no placeholders remain:** Re-run grep/rg search after edits
5. **Update Last Updated date:** Set <DOCS_ROOT>/project/NEXT.md "Last Updated:" to today (YYYY-MM-DD)

### Exit criteria (Population Gate PASS)
- <DOCS_ROOT>/project/VISION.md: Purpose + North Star + User Promise + Non-Goals (all non-placeholder)
- <DOCS_ROOT>/project/EPICS.md: At least 1 epic with ID + status + description (all non-placeholder)
- <DOCS_ROOT>/project/NEXT.md: ACTIVE STORY ID + NEXT STEP + DoD + Scope + Done When (at least 3 items, NONE with placeholders) + Last Updated date (all non-placeholder)
- Grep search returns **zero** placeholder markers in VISION/EPICS/NEXT
- Population Gate verdict: **PASS**

---

## Integration with Protocol v7

Alignment Mode is referenced in protocol-v7.md Vision & User Story Gate:
- "If `<DOCS_ROOT>/project/NEXT.md` is missing/unclear/outdated OR Control Deck Population Gate FAIL → STOP coding and enter Alignment Mode."

See [protocol-v7.md](protocol-v7.md) for full Vision & User Story Gate rules.
