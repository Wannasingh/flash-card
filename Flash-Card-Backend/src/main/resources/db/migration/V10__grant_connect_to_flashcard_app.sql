-- Flyway V10: Grant CONNECT permission to flashcard_app
-- Necessary because create role doesn't always grant connect on existing databases.

GRANT CONNECT ON DATABASE postgres TO flashcard_app;
