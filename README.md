# Remembrall

Expertise management platform. Users create structured, reusable, shareable checklists (Remembralls). AI generates a first draft from a plain-text description.

## Status

E0 — Architecture decisions in progress. No implementation code yet.

## Docs

- `docs/project/VISION.md` — product vision and market summary
- `docs/project/EPICS.md` — MVP epic sequence (E0–E4)
- `docs/project/NEXT.md` — current sprint / active work
- `docs/overlays/remembrall-decisions.md` — standing architectural decisions
- `docs/testing/test-catalog.md` — RLS test matrix and proof gates

## Development Protocol

Octopus model: Stephen (Product Owner) · Claude (Human/Driver) · Copilot (Executor)

- Feature branches: normal implementation work, intend to merge, go through proof gates
- x-branches (`x/<name>`): research/spike only, never merge, must produce a findings doc

See `docs/overlays/remembrall-decisions.md` for all standing decisions.

## Stack (pending E0 confirmation)

Next.js (current stable, App Router) · PostgreSQL + Prisma · Auth.js · Vercel
