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

-- ==========================================
-- GEN-Z FLASHCARD SCHEMA
-- ==========================================

-- 1. Extend Users (Gamification)
ALTER TABLE IF EXISTS flashcard.users ADD COLUMN IF NOT EXISTS coins INT DEFAULT 0;
ALTER TABLE IF EXISTS flashcard.users ADD COLUMN IF NOT EXISTS streak_days INT DEFAULT 0;
ALTER TABLE IF EXISTS flashcard.users ADD COLUMN IF NOT EXISTS last_study_date DATE;

-- 2. Decks (ชุดคำศัพท์ สนับสนุน Marketplace)
CREATE TABLE IF NOT EXISTS flashcard.decks (
    id BIGSERIAL PRIMARY KEY,
    creator_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    tags VARCHAR(255)[],
    is_public BOOLEAN DEFAULT false,
    price INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_decks_creator FOREIGN KEY (creator_id) REFERENCES flashcard.users (id) ON DELETE CASCADE
);

-- 3. Cards (การ์ดโฉมใหม่ รองรับ Multimedia / AI)
CREATE TABLE IF NOT EXISTS flashcard.cards (
    id BIGSERIAL PRIMARY KEY,
    deck_id BIGINT NOT NULL,
    front_text TEXT NOT NULL,
    back_text TEXT NOT NULL,
    image_url TEXT,
    video_url TEXT,
    ar_model_url TEXT,
    meme_url TEXT,
    ai_mnemonic TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_cards_deck FOREIGN KEY (deck_id) REFERENCES flashcard.decks (id) ON DELETE CASCADE
);

-- 4. Study Progress (Spaced Repetition System - SRS)
CREATE TABLE IF NOT EXISTS flashcard.study_progress (
    user_id BIGINT NOT NULL,
    card_id BIGINT NOT NULL,
    easiness_factor REAL DEFAULT 2.5,
    interval_days INT DEFAULT 0,
    repetitions INT DEFAULT 0,
    next_review_at TIMESTAMPTZ,
    last_reviewed_at TIMESTAMPTZ,
    PRIMARY KEY (user_id, card_id),
    CONSTRAINT fk_study_progress_user FOREIGN KEY (user_id) REFERENCES flashcard.users (id) ON DELETE CASCADE,
    CONSTRAINT fk_study_progress_card FOREIGN KEY (card_id) REFERENCES flashcard.cards (id) ON DELETE CASCADE
);

-- 5. User Decks (ห้องสมุดเก็บ Deck ที่กด Fav ไว้ หรือซื้อมา)
CREATE TABLE IF NOT EXISTS flashcard.user_decks (
    user_id BIGINT NOT NULL,
    deck_id BIGINT NOT NULL,
    is_favorite BOOLEAN DEFAULT false,
    acquired_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, deck_id),
    CONSTRAINT fk_user_decks_user FOREIGN KEY (user_id) REFERENCES flashcard.users (id) ON DELETE CASCADE,
    CONSTRAINT fk_user_decks_deck FOREIGN KEY (deck_id) REFERENCES flashcard.decks (id) ON DELETE CASCADE
);

-- 6. Study Rooms (สำหรับโหมดเล่นพร้อมกัน Battle/Co-op)
CREATE TABLE IF NOT EXISTS flashcard.study_rooms (
    id BIGSERIAL PRIMARY KEY,
    room_code VARCHAR(10) UNIQUE NOT NULL,
    host_id BIGINT NOT NULL,
    deck_id BIGINT NOT NULL,
    status VARCHAR(20) DEFAULT 'WAITING',
    mode VARCHAR(20) DEFAULT 'COOP',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_study_rooms_host FOREIGN KEY (host_id) REFERENCES flashcard.users (id) ON DELETE CASCADE,
    CONSTRAINT fk_study_rooms_deck FOREIGN KEY (deck_id) REFERENCES flashcard.decks (id) ON DELETE CASCADE
);
