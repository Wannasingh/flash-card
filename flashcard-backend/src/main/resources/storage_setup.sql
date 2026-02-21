-- 1. Create the private bucket for profile pictures
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'flashcard.profile.picture', 
    'flashcard.profile.picture', 
    false, -- Private bucket
    10485760, -- 10MB limit
    '{"image/png", "image/jpeg", "image/webp"}'
)
ON CONFLICT (id) DO UPDATE SET 
    public = false,
    file_size_limit = 10485760,
    allowed_mime_types = '{"image/png", "image/jpeg", "image/webp"}';

-- 2. Storage Policies
-- Note: Since our Spring Boot backend uses the 'service_role' key, 
-- it bypasses these RLS policies. The security is enforced 
-- at the Backend level (UserController).

-- If you ever want to allow direct app access using Supabase Auth:
/*
-- Allow users to view their own profile picture folder
CREATE POLICY "Users can view their own profile folder"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'flashcard.profile.picture' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to upload to their own profile picture folder
CREATE POLICY "Users can upload to their own profile folder"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'flashcard.profile.picture' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);
*/
