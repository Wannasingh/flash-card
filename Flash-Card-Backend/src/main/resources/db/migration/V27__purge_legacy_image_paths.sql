-- Migration to purge all legacy image paths for users.
-- This forces a fresh start using the new Java storage system and UUID folders.
-- This will cause all users to temporarily show a placeholder until they upload a new image.

UPDATE flashcard.users 
SET image_url = NULL,
    image_source = NULL,
    image_updated_at = NULL;

-- Also clean up any malformed deck cover URLs that didn't match the flashcard_media prefix
UPDATE flashcard.decks
SET cover_image_url = NULL
WHERE cover_image_url IS NOT NULL
AND cover_image_url NOT LIKE 'flashcard_media/%';
