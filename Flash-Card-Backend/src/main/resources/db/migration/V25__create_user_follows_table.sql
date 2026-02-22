CREATE TABLE flashcard.user_follows (
    id BIGSERIAL PRIMARY KEY,
    follower_id BIGINT NOT NULL REFERENCES flashcard.users(id) ON DELETE CASCADE,
    following_id BIGINT NOT NULL REFERENCES flashcard.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(follower_id, following_id)
);

-- Grant permissions to flashcard_app
GRANT ALL PRIVILEGES ON TABLE flashcard.user_follows TO flashcard_app;
GRANT ALL PRIVILEGES ON SEQUENCE flashcard.user_follows_id_seq TO flashcard_app;
