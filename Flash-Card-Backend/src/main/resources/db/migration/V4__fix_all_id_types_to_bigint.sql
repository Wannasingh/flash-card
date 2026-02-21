-- Flyway V4: Convert all id columns from serial (integer) to bigint
-- to match JPA entity Long type expected by Hibernate schema validation.
-- Uses DO block with exception handling to skip tables where column is already bigint.

DO $$
BEGIN
    -- flashcard schema tables
    BEGIN
        ALTER TABLE flashcard.user_inventory ALTER COLUMN id TYPE bigint;
    EXCEPTION WHEN others THEN NULL;
    END;

    -- public schema tables (no explicit schema in @Table = default search_path = public)
    BEGIN
        ALTER TABLE cards ALTER COLUMN id TYPE bigint;
    EXCEPTION WHEN others THEN NULL;
    END;

    BEGIN
        ALTER TABLE study_rooms ALTER COLUMN id TYPE bigint;
    EXCEPTION WHEN others THEN NULL;
    END;

    BEGIN
        ALTER TABLE decks ALTER COLUMN id TYPE bigint;
    EXCEPTION WHEN others THEN NULL;
    END;

    BEGIN
        ALTER TABLE badges ALTER COLUMN id TYPE bigint;
    EXCEPTION WHEN others THEN NULL;
    END;

    BEGIN
        ALTER TABLE user_badges ALTER COLUMN id TYPE bigint;
    EXCEPTION WHEN others THEN NULL;
    END;

    BEGIN
        ALTER TABLE users ALTER COLUMN id TYPE bigint;
    EXCEPTION WHEN others THEN NULL;
    END;

    BEGIN
        ALTER TABLE user_identities ALTER COLUMN id TYPE bigint;
    EXCEPTION WHEN others THEN NULL;
    END;

    BEGIN
        ALTER TABLE roles ALTER COLUMN id TYPE bigint;
    EXCEPTION WHEN others THEN NULL;
    END;
END $$;
