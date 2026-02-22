-- V17__grant_decks_permission_fix_force.sql
GRANT ALL PRIVILEGES ON TABLE flashcard.decks TO flashcard_app;
GRANT ALL PRIVILEGES ON TABLE flashcard.cards TO flashcard_app;
GRANT ALL PRIVILEGES ON SEQUENCE flashcard.decks_id_seq TO flashcard_app;
GRANT ALL PRIVILEGES ON SEQUENCE flashcard.cards_id_seq TO flashcard_app;

ALTER TABLE flashcard.decks OWNER TO flashcard_app;
ALTER TABLE flashcard.cards OWNER TO flashcard_app;
