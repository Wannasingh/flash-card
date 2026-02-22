-- V21: Setup Supabase Storage for Flashcards

-- Ensure we are in a context that can access storage
SET search_path = storage, public;

-- 1. Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('flashcard_media', 'flashcard_media', true) 
ON CONFLICT (id) DO NOTHING;

-- 2. Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload" ON storage.objects;
DROP POLICY IF EXISTS "Owner Update" ON storage.objects;
DROP POLICY IF EXISTS "Owner Delete" ON storage.objects;

-- 3. Create Policies

-- Allow everyone (including unauthenticated) to VIEW files in this bucket
CREATE POLICY "Public Access" ON storage.objects 
FOR SELECT 
USING ( bucket_id = 'flashcard_media' );

-- Allow authenticated users to UPLOAD files
CREATE POLICY "Authenticated Upload" ON storage.objects 
FOR INSERT 
WITH CHECK ( 
    bucket_id = 'flashcard_media' 
    AND auth.role() = 'authenticated' 
);

-- Allow users to UPDATE their own files
CREATE POLICY "Owner Update" ON storage.objects 
FOR UPDATE 
USING ( 
    bucket_id = 'flashcard_media' 
    AND auth.uid() = owner 
);

-- Allow users to DELETE their own files
CREATE POLICY "Owner Delete" ON storage.objects 
FOR DELETE 
USING ( 
    bucket_id = 'flashcard_media' 
    AND auth.uid() = owner 
);
