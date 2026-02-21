package com.flashcard.backend.repository;

import com.flashcard.backend.entity.UserDeck;
import com.flashcard.backend.entity.UserDeckId;
import com.flashcard.backend.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserDeckRepository extends JpaRepository<UserDeck, UserDeckId> {
    List<UserDeck> findByUser(User user);
    boolean existsByUserAndDeckId(User user, Long deckId);
}
