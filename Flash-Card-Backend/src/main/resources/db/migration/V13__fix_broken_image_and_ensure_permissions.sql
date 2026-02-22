-- Fix broken profile image for user 4
UPDATE flashcard.users SET image_url = NULL WHERE id = 4;

-- Ensure permissions are granted (idempotent)
GRANT USAGE ON SCHEMA flashcard TO flashcard_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA flashcard TO flashcard_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA flashcard TO flashcard_app;

-- Ensure storage schema permissions
GRANT USAGE ON SCHEMA storage TO flashcard_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA storage TO flashcard_app;
