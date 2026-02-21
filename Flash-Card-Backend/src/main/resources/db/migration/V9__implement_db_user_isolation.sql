-- Flyway V9: Database User Isolation
-- This script creates a dedicated role for the application and restricts its access.

DO $$
BEGIN
    -- 1. Create the application user if it doesn't exist
    -- Note: Using a default password, USER should change this later via SQL.
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'flashcard_app') THEN
        CREATE ROLE flashcard_app WITH LOGIN PASSWORD '${FLASHCARD_APP_PASSWORD}';
    END IF;
END $$;

-- 2. Grant permissions on the 'flashcard' schema
GRANT USAGE ON SCHEMA flashcard TO flashcard_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA flashcard TO flashcard_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA flashcard TO flashcard_app;

-- 3. Ensure future tables in 'flashcard' are also accessible to this user
ALTER DEFAULT PRIVILEGES IN SCHEMA flashcard GRANT ALL ON TABLES TO flashcard_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA flashcard GRANT ALL ON SEQUENCES TO flashcard_app;

-- 4. Grant restricted read access to Supabase schemas for metadata
GRANT USAGE ON SCHEMA auth TO flashcard_app;
GRANT SELECT ON ALL TABLES IN SCHEMA auth TO flashcard_app;
GRANT USAGE ON SCHEMA storage TO flashcard_app;
GRANT SELECT ON ALL TABLES IN SCHEMA storage TO flashcard_app;

-- 5. Explicitly deny access to public schema to ensure isolation
-- Note: In Postgres, all users usually have CONNECT and sometimes USAGE on PUBLIC by default.
REVOKE ALL ON SCHEMA public FROM flashcard_app;
