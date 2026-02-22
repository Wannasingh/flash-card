-- Flyway V24: Clean Corrupted Image URLs
-- Fixes an issue where iOS clients sent back the proxied profile image URL, overwriting the supabase storage path.

UPDATE flashcard.users 
SET image_url = NULL 
WHERE image_url LIKE 'http://%';
