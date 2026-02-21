package com.flashcard.backend.repository;

import com.flashcard.backend.entity.Card;
import com.flashcard.backend.entity.Deck;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CardRepository extends JpaRepository<Card, Long> {
    List<Card> findByDeck(Deck deck);
}
