# Test-Touch Block Template

## PROMPT REVIEW GATE + COMMAND LOCK (MANDATORY FIRST OUTPUT)
Before issuing any command, edit, search, or tool call, output these four lines in order:
What: <1-line plan>
Best next step? YES/NO
Confidence: <percentage>%
Command Lock satisfied? YES/NO (STOP immediately if NO)
Only continue with the rest of the response if all four lines are printed and the answers are YES / ≥95% (or ≥99% for runtime) / YES.

Include this block in any prompt that may modify `*.spec.ts` files:

---

## Test-Touch Block

**Required reading before editing tests:**
- `<DOCS_ROOT>/testing/test-catalog.md` (Must check canonical existence via `git -C <root> ls-files <DOCS_ROOT>/testing/test-catalog.md`)
- In reports: narrative lists directory buckets only; prove catalog location via raw `git -C $root ls-files <DOCS_ROOT>/testing/test-catalog.md` output.

**After editing any spec file:**
1. Update the corresponding row in `<DOCS_ROOT>/testing/test-catalog.md`
2. If spec lacks the Spec Header Standard, add it
3. Include in completion report:
   - "Tests touched:" list each spec + paste its `@human` line

**Deterministic test rule:**
- No unseeded randomness
- No "rerun until green"
- If flakiness exists, record TECH DEBT with ID and cause

## Contract Test Pattern (Prevents Flip-Flopping)

**When required:**
- Any time behavior/UI is changed because "production has 0 items" or "shape differs"
- Before removing features due to current production state

**Checklist:**
1. Identify production artifact (file path or API endpoint)
2. Record property chains + counts + 1 example item (as comments in test)
3. Add contract assertion that fails if production shape/count changes
4. Add comment: "If this fails, restore <feature> or re-evaluate production shape."

**Test file naming:**
- Pattern: `*.contract.spec.ts` or `*production-content-contract.spec.ts`

## Shape-Proof Test Requirement (Measure Production First)

**Required for content-dependent tests:**
- Import/use REAL generated production JSON (no invented IDs/fixtures)
- Record exact property chain being relied on (as comments)
- Include at least one shape-proof assertion (keys exist, array lengths, ID patterns)

**Example property chain comment:**

    // Production artifact: src/assets/content/values.generated.json
    // Property chain: categories[].followUps[]
    // Position IDs: {categoryId}-q\d+ (e.g., liberty-q0)
    // Challenge IDs: {positionId}-fu\d+ (e.g., liberty-q0-fu0)

## Report Required Fields (Mirror Copilot Instructions)
- Commit hash + subject for the work you just landed
- `git status --porcelain` output proving the tree is clean
- `git diff --name-only` output listing touched files
- Results of `npm run test` and `npm run build`
- For every touched spec: paste its `@human` line and confirm the catalog row was updated in the same prompt

---
