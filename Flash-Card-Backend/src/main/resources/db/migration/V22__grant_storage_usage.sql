-- V22: Grant storage schema usage to application user

GRANT USAGE ON SCHEMA storage TO flashcard_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA storage TO flashcard_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA storage TO flashcard_app;
