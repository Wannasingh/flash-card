-- V20: Add media support for Decks and Cards

-- Add media columns to Decks for Marketplace feed (TikTok style)
ALTER TABLE flashcard.decks ADD COLUMN IF NOT EXISTS cover_image_url TEXT;
ALTER TABLE flashcard.decks ADD COLUMN IF NOT EXISTS preview_video_url TEXT;

-- Ensure Cards have media columns (already in Entity, ensuring in DB)
ALTER TABLE flashcard.cards ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE flashcard.cards ADD COLUMN IF NOT EXISTS video_url TEXT;
