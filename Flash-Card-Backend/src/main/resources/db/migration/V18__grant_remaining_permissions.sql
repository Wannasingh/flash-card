-- V18__grant_remaining_permissions.sql
-- Grant permissions for all remaining tables and sequences to flashcard_app

-- Tables
GRANT ALL PRIVILEGES ON TABLE flashcard.user_decks TO flashcard_app;
GRANT ALL PRIVILEGES ON TABLE flashcard.study_progress TO flashcard_app;
GRANT ALL PRIVILEGES ON TABLE flashcard.study_rooms TO flashcard_app;
GRANT ALL PRIVILEGES ON TABLE flashcard.refresh_tokens TO flashcard_app;

-- Sequences (using dynamic SQL to catch all sequences or explicit naming if known)
GRANT ALL PRIVILEGES ON SEQUENCE flashcard.decks_id_seq TO flashcard_app;
GRANT ALL PRIVILEGES ON SEQUENCE flashcard.cards_id_seq TO flashcard_app;
GRANT ALL PRIVILEGES ON SEQUENCE flashcard.study_rooms_id_seq TO flashcard_app;
GRANT ALL PRIVILEGES ON SEQUENCE flashcard.refresh_tokens_id_seq TO flashcard_app;

-- Grant usage on schema again just to be safe
GRANT USAGE ON SCHEMA flashcard TO flashcard_app;
