-- Grant usage on schema
GRANT USAGE ON SCHEMA flashcard TO flashcard_app;

-- Grant all privileges on all tables in schema flashcard to flashcard_app
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA flashcard TO flashcard_app;

-- Grant all privileges on all sequences in schema flashcard to flashcard_app
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA flashcard TO flashcard_app;

-- Ensure future tables created by postgres user are accessible by flashcard_app
ALTER DEFAULT PRIVILEGES IN SCHEMA flashcard GRANT ALL ON TABLES TO flashcard_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA flashcard GRANT ALL ON SEQUENCES TO flashcard_app;
