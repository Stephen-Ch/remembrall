# Stack Profile Standard

> **Scope:** Portable across all repos using the vibe-coding bundle.  
> **Authority:** This defines how to declare a repo's technology stack for gate automation.

---

## Purpose

A **stack profile** is a repo-local declaration that tells the vibe-coding protocol:
1. What technology stacks are present
2. Which gates apply to which changes
3. How to run builds and tests

**Key principle:** Gates read the stack profile — no interpretation or guessing.

---

## Required Fields

Every `stack-profile.md` MUST include:

### 1. Primary Stack
```markdown
## Primary Stack

| Field | Value |
|-------|-------|
| **Framework** | (e.g., ASP.NET MVC 5, React 18, Node.js 20) |
| **Language** | (e.g., C# 7.3, TypeScript 5.x) |
| **Runtime** | (e.g., .NET Framework 4.8, Node.js 20.x) |
| **Build Tool** | (e.g., MSBuild, npm, webpack) |
| **Solution/Project** | (path to .sln, .csproj, or package.json) |
```

### 2. Secondary Stacks (if any)
List any additional stacks (e.g., Playwright test harness in a .NET repo):

```markdown
## Secondary Stacks

| Stack | Purpose | Location | Build Required |
|-------|---------|----------|----------------|
| Playwright | E2E tests | ./package.json | No (test harness only) |
```

### 3. Gate Configuration
Declare which gates apply:

```markdown
## Gate Configuration

### Runtime Code Changes (.cs, .cshtml, .vb, .js, .ts)
| Gate | Command | Required |
|------|---------|----------|
| .NET Build | `msbuild <project>.csproj /p:Configuration=Release` | YES |
| .NET Tests | (command or "N/A") | (YES/NO/N/A) |
| JS Build | (command or "N/A") | (YES/NO/N/A) |
| JS Tests | (command or "N/A") | (YES/NO/N/A) |

### Docs-Only Changes (.md files)
| Gate | Required |
|------|----------|
| Population Gate | YES |
| Build | NO |
```

### 4. Manual Test Expectations
```markdown
## Manual Test Expectations

| Change Type | Test Level |
|-------------|------------|
| UI/UX changes | Quick Smoke (3 bullets in PR) |
| Grading/scoring changes | Formal MT (full checklist) |
| Docs-only | None |
```

---

## Stack Profile Location

**Canonical path:** `docs/project/stack-profile.md` or `<DOCS_ROOT>/project/stack-profile.md`

The stack profile is **project-specific** and lives OUTSIDE the vibe-coding bundle. It is never overwritten by subtree updates.

---

## Examples

### Example 1: ASP.NET MVC with Playwright Harness

```markdown
## Primary Stack

| Field | Value |
|-------|-------|
| **Framework** | ASP.NET MVC 5 |
| **Language** | C# 7.3, VB.NET |
| **Runtime** | .NET Framework 4.8 |
| **Build Tool** | MSBuild |
| **Solution/Project** | AcmeApp.csproj |

## Secondary Stacks

| Stack | Purpose | Location | Build Required |
|-------|---------|----------|----------------|
| Playwright | E2E test harness | ./package.json | No |

## Gate Configuration

### Runtime Code Changes
| Gate | Command | Required |
|------|---------|----------|
| .NET Build | `msbuild AcmeApp.csproj /p:Configuration=Release` | YES |
| .NET Tests | N/A (no test framework configured) | N/A |
| JS Build | N/A (test harness only, no build script) | N/A |
| Playwright E2E | `npm run test:smoke` | Optional |
```

### Example 2: React Application

```markdown
## Primary Stack

| Field | Value |
|-------|-------|
| **Framework** | React 18 |
| **Language** | TypeScript 5.x |
| **Runtime** | Node.js 20.x |
| **Build Tool** | Vite |
| **Solution/Project** | ./package.json |

## Gate Configuration

### Runtime Code Changes
| Gate | Command | Required |
|------|---------|----------|
| JS Build | `npm run build` | YES |
| JS Tests | `npm run test` | YES |
| Lint | `npm run lint` | YES |
```

### Example 3: Monorepo (Multiple Apps)

```markdown
## Primary Stack

| Field | Value |
|-------|-------|
| **Framework** | Nx Monorepo |
| **Language** | TypeScript |
| **Runtime** | Node.js 20.x |
| **Build Tool** | Nx |

## Applications

| App | Stack | Location | Build Command |
|-----|-------|----------|---------------|
| api | NestJS | apps/api | `nx build api` |
| web | React | apps/web | `nx build web` |
| shared | TS lib | libs/shared | `nx build shared` |

## Gate Configuration

Changes to a specific app run that app's gates only:
- `apps/api/**` → `nx build api && nx test api`
- `apps/web/**` → `nx build web && nx test web`
```

---

## How Gates Read Stack Profile

Protocol rule: **Stack-aware gate decisions MUST come from stack-profile.md**

1. Read `stack-profile.md` to determine which gates apply
2. Match the changed files to the appropriate stack section
3. Run only the gates marked "Required: YES" for that stack
4. Document gate results in completion report

**No interpretation:** If stack-profile says "JS Build: N/A", do not run npm build even if package.json exists.

---

## Updating Stack Profile

When the repo's technology changes:
1. Update `stack-profile.md` with new framework/tooling
2. Update gate commands if build process changes
3. Note the change in commit message
4. Stack profile changes are docs-only (no build gate required)
