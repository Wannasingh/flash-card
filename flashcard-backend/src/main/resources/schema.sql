CREATE SCHEMA IF NOT EXISTS flashcard;

CREATE TABLE IF NOT EXISTS flashcard.roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(20) UNIQUE
);

CREATE TABLE IF NOT EXISTS flashcard.users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(120),
    display_name VARCHAR(255),
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ
);

ALTER TABLE IF EXISTS flashcard.users ALTER COLUMN password DROP NOT NULL;
ALTER TABLE IF EXISTS flashcard.users ADD COLUMN IF NOT EXISTS display_name VARCHAR(255);
ALTER TABLE IF EXISTS flashcard.users ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE IF EXISTS flashcard.users ADD COLUMN IF NOT EXISTS image_source VARCHAR(20);
ALTER TABLE IF EXISTS flashcard.users ADD COLUMN IF NOT EXISTS image_updated_at TIMESTAMPTZ;
ALTER TABLE IF EXISTS flashcard.users ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE IF EXISTS flashcard.users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS flashcard.user_roles (
    user_id BIGINT NOT NULL,
    role_id INTEGER NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES flashcard.users (id) ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES flashcard.roles (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS flashcard.user_identities (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    provider VARCHAR(20) NOT NULL,
    provider_user_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_user_identities_user FOREIGN KEY (user_id) REFERENCES flashcard.users (id) ON DELETE CASCADE,
    CONSTRAINT uq_user_identities_provider_user UNIQUE (provider, provider_user_id),
    CONSTRAINT uq_user_identities_user_provider UNIQUE (user_id, provider)
);
