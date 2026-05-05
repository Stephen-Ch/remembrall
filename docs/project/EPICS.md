# Remembrall — Epic Sequence

MVP only. Post-MVP epics do not begin until MVP is validated with real users.

---

## E0 — Architecture and Security Decisions
**Status:** IN PROGRESS  
**Goal:** All foundational decisions made, documented, and merged before any implementation code is written.

### E0 Hardening Checklist (gate for E1)
- [ ] Auth architecture confirmed: Auth.js + Prisma + dbForUser wrapper (Option A)
- [ ] dbForUser wrapper spec written and CI lint gate defined
- [ ] ShareLink table schema finalized
- [ ] Nested sharing rule defined + cycle prevention approach
- [ ] Reserved username/route list agreed
- [ ] AI logging privacy rule documented
- [ ] CI evidence standard for Copilot signoff defined
- [ ] Offline mode explicitly deferred (confirmed closed)

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

### Definition of Done
- Logged-in user can create a Remembrall with requirements, nest one inside another, check items off
- All data isolated to their account
- All 6 RLS test matrix scenarios pass
- CI lint gate blocks raw Prisma imports

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

## E3 — AI Draft Generation
**Status:** NOT STARTED (can run parallel with E2 after E1 data model locked)  
**Goal:** User types a plain-text description and gets an editable Remembrall draft.

### Includes
- Text input → structured Remembrall (title + requirements)
- Editable output before saving
- Prompt/version logging (metadata only — no raw user input)
- 20-case quality review using synthetic test cases

### Definition of Done
- User types a task description, receives a draft, can edit and save it
- CI logs prompt metadata only
- 20 synthetic test cases reviewed and accepted by Product Owner

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
- Document conversion (PDF/Word to Remembrall via AI)
- Institutional accounts (municipalities, schools)
- HIPAA compliance path
- Shared link revocation UI, audit trail, admin tooling
- Offline mode (Service Worker + IndexedDB)
- Multiple active share links per Remembrall
