package com.flashcard.backend.repository;

import com.flashcard.backend.entity.Deck;
import com.flashcard.backend.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

import java.util.Optional;

@Repository
public interface DeckRepository extends JpaRepository<Deck, Long> {
    List<Deck> findByIsPublicTrue();
    List<Deck> findByCreatorAndIsPublicTrue(User creator);
    List<Deck> findByCreator(User creator);
    Optional<Deck> findByTitle(String title);
}
