-- Flyway V6: Revert roles.id from bigint back to integer.
-- V5 incorrectly changed roles.id to bigint, but the Role JPA entity
-- uses Integer (not Long) for its id field, so Hibernate expects integer.

ALTER TABLE roles ALTER COLUMN id TYPE integer;
