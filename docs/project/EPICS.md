# Remembrall — Epic Sequence

MVP only. Post-MVP epics do not begin until MVP is validated with real users.

---

## E0 — Architecture and Security Decisions
**Status:** COMPLETE  
**Goal:** All foundational decisions made, documented, and merged before any implementation code is written.

### E0 Hardening Checklist (gate for E1)
- [x] Auth architecture confirmed: Auth.js v5 + Prisma adapter + database sessions + magic link only
- [x] dbForUser wrapper spec written and CI lint gate defined (no-restricted-imports, blocks raw PrismaClient outside lib/db.ts)
- [x] ShareLink table schema finalized (dedicated table, UUID token, kind field, revokedAt/lastUsedAt)
- [x] Nested sharing rule defined + cycle prevention approach (depth-limited traversal, max 5 levels)
- [x] Reserved username/route list agreed (admin, api, dashboard, share, settings, www)
- [x] AI logging privacy rule documented (document content not stored; metadata only)
- [x] CI evidence standard defined (RLS matrix + kit Green Gate required for Copilot signoff)
- [x] Offline mode scoped into E1 (Service Worker + IndexedDB) — not deferred; moved to E1 scope

### Deliverables
- DECISIONS.md updated with all E0 answers
- ARCHITECTURE.md created with RLS pattern, data model, URL strategy
- Docs feature branch merged to main before E1 starts

### Branch type
x-branches for research · docs feature branch for harvested decisions (merges before E1)

---

## E1 — Core Private Remembrall Engine
**Status:** NOT STARTED (blocked on E0)  
**Goal:** Logged-in user can create, edit, and run a Remembrall. Data persists. Tenant isolation enforced.

### Includes
- User account creation
- Create / edit / delete Remembrall
- Add / edit / reorder Requirements
- Basic nesting (same-owner, share-visible, cycle-checked, depth-limited)
- Run checklist (check items off)
- Private visibility only
- ShareLink table in data model from day one
- dbForUser wrapper active, CI lint gate blocking raw Prisma imports
- Offline mode: Service Worker + IndexedDB so the app works without network access

### Definition of Done
- Logged-in user can create a Remembrall with requirements, nest one inside another, check items off
- All data isolated to their account
- All 6 RLS test matrix scenarios pass
- CI lint gate blocks raw Prisma imports
- Core checklist functionality works without network access (offline mode)

### Branch type: Feature branch

---

## E2 — Share and Publish
**Status:** NOT STARTED (blocked on E1)  
**Goal:** A Remembrall can be shared via a public URL or a private UUID link. Recipients can view and run it without logging in.

### Includes
- Public/private toggle
- Public slug URL (`/{username}/{slug}`)
- ShareLink token generation
- Read-only recipient view
- Cookie-persisted checkbox state
- Save to account / Register CTA
- Backend unpublish and token revocation
- Rate limiting
- Abuse reporting (mailto link)
- noindex headers on share URLs

### Definition of Done
- Logged-in user can publish a Remembrall and revoke it
- Unregistered recipient can view, check items, and be prompted to register
- State persists across reloads
- UUID links serve noindex headers

### Branch type: Feature branch

---

## E3 — AI Document Import
**Status:** NOT STARTED (can run parallel with E2 after E1 data model locked)  
**Goal:** User brings in an existing document and AI converts it into an editable Remembrall. Users create their own checklists; this feature imports ones that already exist elsewhere.

### Includes
- Upload, attach, or copy/paste a source document (PDF, Word, plain text)
- AI extracts and structures content as a Remembrall (title + requirements)
- Editable output before saving — user reviews and adjusts before anything is committed
- Prompt/version logging (metadata only)
- 20-case quality review using real import examples

### Definition of Done
- User can upload or paste a document and receive a structured Remembrall draft
- User can edit the draft before saving
- CI logs prompt metadata only; document content is not stored in logs
- 20 import examples reviewed and accepted by Product Owner

### Note
This feature is especially important for content creators and influencers who have existing process documents, guides, or checklists they want to bring into Remembrall. MVP must support this path.

### Branch type: Feature branch

---

## E4 — Launch Slice
**Status:** NOT STARTED (blocked on E2 + E3)  
**Goal:** Minimum viable public presence. Functional, not polished.

### Includes
- Mobile-responsive layout (responsive CSS on existing views — not a redesign)
- Empty-state onboarding prompt (not a multi-step flow)
- remembralls.net domain live
- Minimal landing page (what it is, how to start, two examples)
- Minimal analytics (page views and share events)

### Definition of Done
- App live at remembralls.net
- Works on mobile without horizontal scroll
- New user reaches first published Remembrall in under 5 minutes from landing page

### Branch type: Feature branch

---

## Post-MVP (do not build yet)
- Channels (organizational layer within accounts)
- Account branding (logo, colors, custom subdomain)
- Teams and roles (org membership, invitations, RBAC)
- Institutional accounts (municipalities, schools)
- HIPAA compliance path
- Shared link revocation UI, audit trail, admin tooling
- Multiple active share links per Remembrall
