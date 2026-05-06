-- RLS policies for Remembrall.
-- Run AFTER the Prisma initial migration has created the tables.
-- Can also be run via: npx prisma migrate dev (when credentials are in .env.local)

-- ── Remembrall ────────────────────────────────────────────────────────────────

ALTER TABLE "Remembrall" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Remembrall" FORCE ROW LEVEL SECURITY;

CREATE POLICY "remembrall_owner_select" ON "Remembrall"
  FOR SELECT USING (
    "ownerId" = current_setting('app.current_user_id', TRUE)
  );

CREATE POLICY "remembrall_owner_write" ON "Remembrall"
  FOR ALL USING (
    "ownerId" = current_setting('app.current_user_id', TRUE)
  );

-- ── Requirement ───────────────────────────────────────────────────────────────

ALTER TABLE "Requirement" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Requirement" FORCE ROW LEVEL SECURITY;

CREATE POLICY "requirement_owner_select" ON "Requirement"
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM "Remembrall" r
      WHERE r.id = "Requirement"."remembrallId"
        AND r."ownerId" = current_setting('app.current_user_id', TRUE)
    )
  );

CREATE POLICY "requirement_owner_write" ON "Requirement"
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM "Remembrall" r
      WHERE r.id = "Requirement"."remembrallId"
        AND r."ownerId" = current_setting('app.current_user_id', TRUE)
    )
  );

-- ── ShareLink ─────────────────────────────────────────────────────────────────

ALTER TABLE "ShareLink" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ShareLink" FORCE ROW LEVEL SECURITY;

CREATE POLICY "sharelink_owner_select" ON "ShareLink"
  FOR SELECT USING (
    "createdById" = current_setting('app.current_user_id', TRUE)
  );

CREATE POLICY "sharelink_owner_write" ON "ShareLink"
  FOR ALL USING (
    "createdById" = current_setting('app.current_user_id', TRUE)
  );
