-- Flyway V5: Fix remaining FK and PK integer columns across all entity tables.
-- Complements V3 (store_items.id) and V4 (user_inventory.id).
-- V4 was already applied so these additional columns are fixed here.

DO $$
BEGIN
    -- flashcard.user_inventory FK columns
    BEGIN ALTER TABLE flashcard.user_inventory ALTER COLUMN user_id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;
    BEGIN ALTER TABLE flashcard.user_inventory ALTER COLUMN item_id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;

    -- public schema: users
    BEGIN ALTER TABLE users ALTER COLUMN id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;

    -- public schema: roles
    BEGIN ALTER TABLE roles ALTER COLUMN id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;

    -- public schema: user_identities
    BEGIN ALTER TABLE user_identities ALTER COLUMN id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;
    BEGIN ALTER TABLE user_identities ALTER COLUMN user_id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;

    -- public schema: decks
    BEGIN ALTER TABLE decks ALTER COLUMN id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;
    BEGIN ALTER TABLE decks ALTER COLUMN owner_id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;

    -- public schema: cards
    BEGIN ALTER TABLE cards ALTER COLUMN id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;
    BEGIN ALTER TABLE cards ALTER COLUMN deck_id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;

    -- public schema: user_decks
    BEGIN ALTER TABLE user_decks ALTER COLUMN user_id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;
    BEGIN ALTER TABLE user_decks ALTER COLUMN deck_id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;

    -- public schema: study_rooms
    BEGIN ALTER TABLE study_rooms ALTER COLUMN id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;

    -- public schema: study_progress
    BEGIN ALTER TABLE study_progress ALTER COLUMN user_id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;
    BEGIN ALTER TABLE study_progress ALTER COLUMN card_id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;

    -- public schema: badges
    BEGIN ALTER TABLE badges ALTER COLUMN id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;

    -- public schema: user_badges
    BEGIN ALTER TABLE user_badges ALTER COLUMN id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;
    BEGIN ALTER TABLE user_badges ALTER COLUMN user_id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;
    BEGIN ALTER TABLE user_badges ALTER COLUMN badge_id TYPE bigint; EXCEPTION WHEN others THEN NULL; END;

END $$;
