package com.flashcard.backend.entity;

import com.flashcard.backend.user.User;
import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.Instant;

@Entity
@Table(name = "user_decks", schema = "flashcard")
@IdClass(UserDeckId.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserDeck {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Id
    @Column(name = "deck_id")
    private Long deckId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "deck_id", insertable = false, updatable = false)
    private Deck deck;

    @Column(name = "is_favorite", nullable = false)
    private Boolean isFavorite = false;

    @Column(name = "acquired_at", updatable = false)
    private Instant acquiredAt = Instant.now();
}
