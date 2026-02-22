
-- Grant permissions specifically for study_progress table
GRANT ALL PRIVILEGES ON TABLE flashcard.study_progress TO flashcard_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA flashcard TO flashcard_app;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA flashcard TO flashcard_app;
