-- Flyway V7: Explicitly move any tables from public to flashcard schema.
-- This ensures all tables reside in the correct schema as requested.

DO $$
DECLARE
    tbl_name TEXT;
    tables_to_move TEXT[] := ARRAY[
        'roles', 'users', 'user_roles', 'user_identities', 'decks', 'cards', 
        'study_progress', 'user_decks', 'study_rooms', 'badges', 'user_badges', 
        'store_items', 'user_inventory', 'refresh_tokens'
    ];
BEGIN
    FOREACH tbl_name IN ARRAY tables_to_move
    LOOP
        IF EXISTS (
            SELECT 1 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = tbl_name
        ) THEN
            EXECUTE 'ALTER TABLE public.' || quote_ident(tbl_name) || ' SET SCHEMA flashcard';
            RAISE NOTICE 'Moved table % from public to flashcard', tbl_name;
        END IF;
    END LOOP;
END $$;
