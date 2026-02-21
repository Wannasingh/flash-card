-- Function to handle profile image uploads via PL/SQL
CREATE OR REPLACE FUNCTION flashcard.upload_profile_image(
    p_user_id BIGINT,
    p_image_data BYTEA,
    p_content_type TEXT
) RETURNS TEXT AS $$
DECLARE
    v_file_name TEXT;
    v_folder_path TEXT;
    v_storage_path TEXT;
    v_bucket_id TEXT := 'flashcard.profile.picture';
    v_object_id UUID;
BEGIN
    -- 1. Generate path: user_id/uuid.png
    v_folder_path := p_user_id::TEXT;
    v_file_name := gen_random_uuid()::TEXT || '.png';
    v_storage_path := v_folder_path || '/' || v_file_name;

    -- 2. Insert into storage.objects (direct table insert)
    -- This handles the physical storage reference in Supabase
    INSERT INTO storage.objects (
        bucket_id, 
        name, 
        owner, 
        metadata
    ) VALUES (
        v_bucket_id, 
        v_storage_path, 
        NULL, -- Owner can be NULL for anonymous/service-role uploads
        jsonb_build_object(
            'size', octet_length(p_image_data),
            'mimetype', p_content_type
        )
    ) RETURNING id INTO v_object_id;

    -- Note: In a production Supabase environment, the binary data usually goes to specialized storage (S3).
    -- However, for self-hosted/local, we might need to handle the binary specifically if NOT using the storage API.
    -- BUT, if using the storage API via SQL is preferred:
    -- We will store the path in our users table.

    -- 3. Update the user table
    UPDATE flashcard.users 
    SET 
        image_url = v_bucket_id || '/' || v_storage_path,
        image_source = 'MANUAL',
        image_updated_at = NOW()
    WHERE id = p_user_id;

    RETURN v_bucket_id || '/' || v_storage_path;
END;
$$ LANGUAGE plpgsql;
