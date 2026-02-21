INSERT INTO flashcard.roles (name) VALUES ('ROLE_USER') ON CONFLICT (name) DO NOTHING;
INSERT INTO flashcard.roles (name) VALUES ('ROLE_MODERATOR') ON CONFLICT (name) DO NOTHING;
INSERT INTO flashcard.roles (name) VALUES ('ROLE_ADMIN') ON CONFLICT (name) DO NOTHING;

INSERT INTO flashcard.badges (code, name, description, category) VALUES 
('FIRST_SWIPE', 'Pioneer', 'Complete your first flashcard review.', 'STUDY'),
('STREAK_7', 'Disciplined', 'Maintain a 7-day study streak.', 'STREAK'),
('DUEL_WINNER', 'Duelist', 'Win your first 1v1 study duel.', 'DUEL'),
('XP_1000', 'Enlightened', 'Reach 1,000 Total XP.', 'STUDY')
ON CONFLICT (code) DO NOTHING;

-- Seed Store Items
INSERT INTO flashcard.store_items (code, name, type, price, visual_config) VALUES 
('AURA_CYAN', 'Cyan Pulse', 'AURA', 500, '{"color": "#00FFFF", "type": "pulse"}'),
('AURA_NEON_PINK', 'Pink Glitch', 'AURA', 1200, '{"color": "#FF00FF", "type": "glitch"}'),
('SKIN_GOLD', 'Golden Era', 'SKIN', 2000, '{"color": "#FFD700", "theme": "gold"}')
ON CONFLICT (code) DO NOTHING;
