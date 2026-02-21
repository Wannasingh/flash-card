-- Flyway V3: Change store_items.id from serial (integer) to bigint
-- to match the JPA entity's Long type expected by Hibernate validation.
ALTER TABLE flashcard.store_items ALTER COLUMN id TYPE bigint;
