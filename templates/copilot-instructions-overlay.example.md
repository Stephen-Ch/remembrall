# Copilot Instructions Overlay -- EXAMPLE ONLY

> **EXAMPLE ONLY -- project-specific.**
> This file shows where a consumer repo would place project-specific
> Copilot constraints. Copy this to your consumer repo's docs folder
> and fill in your own values.
>
> See [copilot-instructions-v7.md](../protocol/copilot-instructions-v7.md)
> for the portable base rules, and
> [OCTOPUS-INVARIANTS.md](../OCTOPUS-INVARIANTS.md) for overlay placement.

---

## Project Context

    Stack: <e.g., ASP.NET MVC 5, .NET Framework 4.8, Razor views>
    Build: <e.g., MSBuild via Visual Studio>
    Tests: <e.g., xUnit, manual browser testing>
    Database: <e.g., SQL Server via Entity Framework>
    Key Projects: <list>

---

## Terminal Policy (Project-Specific)

    Prefer <build tool> for builds (e.g., msbuild, dotnet build, npm run build).
    No <package manager> changes without explicit approval.

---

## Hot Files (Project-Specific)

List files that require analysis-only-first or full-file-replacement.
See [Hot File Protocol](../protocol/protocol-v7.md#hot-file-protocol-general).

    - Controllers/TeachController.cs -- Lesson authoring workflow
    - Controllers/StudentController.cs -- Student lesson delivery
    - Models/LessonData.cs -- Core data model
    - Views/Shared/_Layout.cshtml -- Master layout
    - App_Start/RouteConfig.cs -- Routing configuration

---

## Green Gate (Project-Specific)

Define the exact build + test commands. Read from your stack-profile.
See [Green Gate](../protocol/protocol-v7.md#green-gate--stack-aware-rules).

Example for an ASP.NET project with no automated tests:

    Build: msbuild MyProject.csproj /p:Configuration=Release
    Tests: (manual browser testing; no automated suite)
    Manual: Confirm affected pages load without JS console errors
    Document: Note which pages/actions were manually tested

---

## Cross-cutting Coverage (Project-Specific)

Map your own routes/controllers for the coverage checklist.
See [Coverage Checklist](../protocol/protocol-v7.md#coverage-checklist-for-cross-cutting-work-mandatory).

    | Controller | Action | Status | Evidence |
    |------------|--------|--------|----------|
    | TeachController | Design | UPDATED / NO CHANGE REQUIRED | reason |
    | StudentController | Lesson | UPDATED / NO CHANGE REQUIRED | reason |

---

## S1A RED-LOCK (Project-Specific, if applicable)

Define allowed and disallowed file patterns for test-only prompts.

    Allowed: *.spec.ts, test-catalog.md, solution-report.md
    Disallowed: runtime code, config files, lockfiles

---

## Test Catalog Rules (Project-Specific, if applicable)

    Required reading before editing tests: <path to test catalog>
    Update rule: if you touch a spec file, update its catalog row.
    Completion report must include: "Tests touched:" + @human lines.

---

## Measure Production First (Project-Specific, if applicable)

    Production artifact: <e.g., src/assets/content/values.generated.json>
    Contract test rule: lock measured state before disabling UI.
    UI copy source: <e.g., single dictionary; labels are not storage shape evidence>

---

## Research-First Workflow (Project-Specific)

**Before any research task:**
1. Run `tools/check-prior-research.ps1 -Terms "<keywords>"` to search existing research.
2. If matches found, READ the referenced documents before starting new investigation.
3. If confidence is below 95%, enter RESEARCH-ONLY mode — do not guess.
4. Save every research output to `<DOCS_ROOT>/research/R-###-<Title>.md`.
5. Update `<DOCS_ROOT>/research/ResearchIndex.md` in the same commit.

**Do NOT skip the prior-research lookup.** Duplicate research wastes sessions.

---

## Framework-Specific Rules (if applicable)

Add stack-specific rules here (e.g., Angular zoneless, React hooks, etc.):

    Example (Angular):
    - App: zoneless only (provideZonelessChangeDetection())
    - Tests: zone.js/testing allowed in src/test.ts only
    - Root template: <router-outlet></router-outlet> only
