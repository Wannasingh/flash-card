-- Flyway V26: Clean Corrupted Image URLs and Deck Covers
-- This migration cleans up legacy image paths that don't match our storage structure.

-- 1. Clean up corrupted or absolute URLs in the users table
UPDATE flashcard.users 
SET image_url = NULL 
WHERE image_url IS NOT NULL 
AND (
    image_url LIKE 'http://%' 
    OR image_url LIKE 'https://%'
    OR image_url NOT LIKE 'flashcard.profile.picture/%'
);

-- 2. Clean up corrupted deck cover images that don't match our storage pattern
UPDATE flashcard.decks
SET cover_image_url = NULL
WHERE cover_image_url IS NOT NULL
AND (
    cover_image_url LIKE 'http://%'
    OR cover_image_url LIKE 'https://%'
    OR cover_image_url NOT LIKE 'flashcard_media/%'
);
