-- Run this ONCE in the Supabase SQL editor before first deploy.
-- Use the remembrall_app password you set in .env.local DATABASE_URL.
--
-- This creates a non-owner, non-superuser Postgres role for the app.
-- Prisma connects as this role so RLS policies are enforced on every query.
-- Never use the postgres superuser for application queries.

CREATE ROLE remembrall_app WITH LOGIN PASSWORD '<set-in-supabase-dashboard>';

GRANT USAGE ON SCHEMA public TO remembrall_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO remembrall_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO remembrall_app;

-- Grant the same permissions to future tables automatically
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO remembrall_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO remembrall_app;
