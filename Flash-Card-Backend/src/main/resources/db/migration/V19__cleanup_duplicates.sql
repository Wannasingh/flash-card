-- V19: Cleanup duplicates to allow clean seeding

-- Delete related user_decks first
DELETE FROM flashcard.user_decks 
WHERE deck_id IN (SELECT id FROM flashcard.decks WHERE title = 'Cyberpunk Slang 2077');

-- Delete related cards
DELETE FROM flashcard.cards 
WHERE deck_id IN (SELECT id FROM flashcard.decks WHERE title = 'Cyberpunk Slang 2077');

-- Delete the decks themselves
DELETE FROM flashcard.decks 
WHERE title = 'Cyberpunk Slang 2077';
