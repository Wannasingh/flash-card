-- V12: Grant permissions on Supabase storage schema to flashcard_app
-- This is necessary for the application to manage file uploads (profile images, etc.)

-- 1. Grant usage on the schema
GRANT USAGE ON SCHEMA storage TO flashcard_app;

-- 2. Grant access to all tables in storage schema (buckets, objects, migrations, etc.)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA storage TO flashcard_app;

-- 3. Grant access to all sequences (for ID generation)
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA storage TO flashcard_app;

-- 4. Ensure future tables in storage schema are also accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON TABLES TO flashcard_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON SEQUENCES TO flashcard_app;
