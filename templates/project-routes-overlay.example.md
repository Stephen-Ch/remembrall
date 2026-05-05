# Project Routes & Coverage — Consumer Overlay Template

> **EXAMPLE ONLY** — project-specific content belongs in consumer overlays,
> not in the vendor kit head. Copy this file to your consumer repo and edit there.

## Purpose

Declares the project's routes, components, hot files, and connection targets
so that coverage checklists, hot-file gates, and evidence packs reference
your real project rather than generic placeholders.

## Overlay Review Gate

Before accepting this overlay into the consumer repo:

- Best next step? (YES/NO)
- Confidence: <percentage>%

## Instructions

1. Copy into consumer repo at `<DOCS_ROOT>/overlays/project-routes.md`
2. Replace all placeholder values with your real project routes, components, and files
3. Do NOT edit this template inside the kit head — it will be overwritten on subtree pull
4. Protocol rules in protocol-v7.md and stay-on-track.md reference this overlay for coverage tables

---

## Route Coverage List

Declare every route in your app. The cross-cutting coverage checklist
(protocol-v7.md § Coverage Checklist) and stay-on-track.md reference this list.

| Route | Component | Notes |
|-------|-----------|-------|
| `/` | `IntroComponent` | Landing / entry point |
| `/select` | `SelectComponent` | Selection screen |
| `/q/:id` | `QuestionV2Component` | Include `q1/:id` + `q2/:id` legacy paths if they exist |
| `/review` | `ReviewComponent` | Review screen |
| `/result` | `ResultComponent` | Results screen |
| `/store` | `StoreComponent` | Store / data screen |

**Routing config file:** `src/app/app.routes.ts`

---

## Hot Files (Known Churn Magnets)

Declare files that require analysis-first or full-file replacement workflow
(see protocol-v7.md § Hot File Protocol).

| File | LOC | Why Hot |
|------|-----|---------|
| `question.component.ts` | ~350 | Core feature component, high churn |
| `session.store.ts` | ~400 | Central state management |
| `app.routes.ts` | ~80 | Routing coordinator |
| `content.service.ts` | ~250 | Content pipeline |
| `scripts/content-build.js` | ~200 | Build-time content generation |

**Always-hot technologies:** SignalR / Multiplayer files (if applicable)

---

## Connection Targets (Evidence Pack)

When creating Evidence Packs (protocol-v7.md § Evidence Pack Requirement),
use these connection names:

| Connection Name | Type | Purpose |
|-----------------|------|---------|
| `TeachModel` | Entity Framework | Primary data model |
| `TopLevelSqlConn` | Raw ADO.NET | Legacy SQL connection |

---

## Build Gate (Green Gate)

Project-specific gate commands (declare in `<DOCS_ROOT>/project/stack-profile.md`):

| Gate | Command | Required |
|------|---------|----------|
| .NET Build | `msbuild ExampleProject.csproj /p:Configuration=Release` | YES |
| .NET Tests | (none configured) | N/A |
| Playwright E2E | `npm run test:smoke` | Optional |

---

## How to Use

1. Place this file at `<DOCS_ROOT>/overlays/project-routes.md`
2. Register it in `<DOCS_ROOT>/overlays/OVERLAY-INDEX.md`
3. Kit vendor docs reference generic placeholders; your overlay provides the real values
4. This keeps the kit head Octopus-clean (zero repo-specific truths in vendor content)
