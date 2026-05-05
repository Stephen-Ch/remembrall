# Terminology Dictionary — UI Copy Lock

**Purpose:** Lock UI terminology to prevent model drift (Core Rule #7).

**Rule:** UI labels are for **communication only**. Data structures remain unchanged.

## Terminology Mapping

| UI Term (Display) | Data Key (Storage) | Definition | Synonyms | Notes |
|:--|:--|:--|:--|:--|
| **Ideal** (singular) | `category` | Top-level philosophical value domain | Category, Dimension | User sees "Ideal", code uses `category` |
| **Ideals** (plural) | `categories` | Collection of philosophical value domains | Categories, Dimensions | User sees "Ideals", code uses `categories` |
| **Position** (singular) | `followUp` | Statement within an Ideal requiring stance | TLQ, Question, Follow-up | User sees "Position", code uses `followUp` |
| **Positions** (plural) | `followUps` | Collection of statements within an Ideal | TLQs, Questions, Follow-ups | User sees "Positions", code uses `followUps` |
| **Challenge** (singular) | `challenge` | Nested counter-argument to a Position | - | Currently 0 in production |
| **Challenges** (plural) | `challenges` | Collection of counter-arguments | - | Currently 0 in production |

## Behavioral Definitions

- **Ideal (category):** A philosophical value domain like Liberty, Equality, Fairness. Users select 1-7 Ideals to explore.
- **Position (followUp):** A specific moral statement under an Ideal. Users rate each Position on a 1-5 scale.
- **Challenge (challenge):** A nested counter-argument to a Position. Not currently implemented (0 in production).

## Data Shape Contract

**Production JSON structure (src/assets/content/values.generated.json):**
```json
{
  "categories": [
    {
      "id": "liberty",
      "name": "Liberty",
      "description": "...",
      "quote": "...",
      "followUps": [
        {
          "id": "liberty-q0",
          "text": "Position statement...",
          "challenges": []
        }
      ]
    }
  ]
}
```

**ID Patterns:**
- Ideal (category) IDs: lowercase name (e.g., `liberty`, `equality`)
- Position (followUp) IDs: `{categoryId}-q\d+` (e.g., `liberty-q0`, `equality-q1`)
- Challenge IDs (when implemented): `{positionId}-fu\d+` (e.g., `liberty-q0-fu0`)

## Implementation Location

**Source:** `<YourAppPath>/shared/terminology.ts`

**Consumed by:**
- `<YourAppPath>/features/review.component.ts` (review screen labels)
- `<YourAppPath>/features/admin/admin-content-explorer.component.ts` (admin UI labels)
- `<YourAppPath>/features/components.ts` (SelectComponent placeholder)

## Drift Prevention

❌ **NEVER:**
- Infer data keys from UI labels ("User sees 'Position' → must be stored as `position`")
- Change data structures when changing UI copy
- Use UI terminology in variable names or property keys

✅ **ALWAYS:**
- Consult `terminology.ts` for UI labels
- Keep data keys unchanged (category/followUp/challenge)
- Update tests to expect new UI labels ONLY (no structural changes)
