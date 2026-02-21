-- Flyway V8: Create Supabase Storage Buckets
-- This migration ensures that the necessary storage buckets exist for the application.

DO $$
BEGIN
    -- 1. Create the 'flashcards' bucket if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'flashcards') THEN
        INSERT INTO storage.buckets (id, name, public, avif_autodetection, file_size_limit, allowed_mime_types)
        VALUES (
            'flashcards', 
            'flashcards', 
            true, 
            false, 
            NULL, 
            NULL
        );
    END IF;

    -- 2. Create 'user_assets' bucket for profile images etc.
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'user_assets') THEN
        INSERT INTO storage.buckets (id, name, public, avif_autodetection, file_size_limit, allowed_mime_types)
        VALUES (
            'user_assets', 
            'user_assets', 
            true, 
            false, 
            NULL, 
            NULL
        );
    END IF;

END $$;

-- Optional: Add RLS policies for storage objects if needed.
-- By default, if the bucket is 'public', anyone can read.
-- For fine-grained control, policies should be added to storage.objects.
