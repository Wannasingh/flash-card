-- =============================================================================
-- V2: Add refresh_tokens table
-- =============================================================================
-- Flyway runs this in its own transaction (DDL + DML safe).
-- The UNIQUE constraint on token creates an implicit B-tree index automatically.
-- =============================================================================

CREATE TABLE IF NOT EXISTS flashcard.refresh_tokens (
    id         BIGSERIAL PRIMARY KEY,
    token      VARCHAR(512)  NOT NULL UNIQUE,
    user_id    BIGINT        NOT NULL,
    expires_at TIMESTAMPTZ   NOT NULL,
    created_at TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_refresh_tokens_user
        FOREIGN KEY (user_id)
        REFERENCES flashcard.users (id)
        ON DELETE CASCADE
);
