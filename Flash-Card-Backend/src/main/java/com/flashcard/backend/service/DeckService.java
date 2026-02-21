package com.flashcard.backend.service;

import com.flashcard.backend.entity.Deck;
import com.flashcard.backend.entity.UserDeck;
import com.flashcard.backend.entity.UserDeckId;
import com.flashcard.backend.exception.ResourceNotFoundException;
import com.flashcard.backend.payload.request.DeckRequest;
import com.flashcard.backend.payload.response.DeckResponse;
import com.flashcard.backend.repository.DeckRepository;
import com.flashcard.backend.repository.UserDeckRepository;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.user.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class DeckService {

    @Autowired
    private DeckRepository deckRepository;

    @Autowired
    private UserDeckRepository userDeckRepository;

    @Autowired
    private UserRepository userRepository;

    public DeckResponse createDeck(Long userId, DeckRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Deck deck = new Deck();
        deck.setCreator(user);
        deck.setTitle(request.getTitle());
        deck.setDescription(request.getDescription());
        deck.setTags(request.getTags());
        deck.setIsPublic(request.getIsPublic());
        deck.setPrice(request.getPrice());

        Deck savedDeck = deckRepository.save(deck);

        // Add to user's library automatically
        UserDeck userDeck = new UserDeck(userId, savedDeck.getId(), user, savedDeck, false, Instant.now());
        userDeckRepository.save(userDeck);

        return mapToResponse(savedDeck, userId);
    }

    public List<DeckResponse> getMyDecks(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        List<UserDeck> myDecks = userDeckRepository.findByUser(user);
        return myDecks.stream()
                .map(ud -> mapToResponse(ud.getDeck(), userId))
                .collect(Collectors.toList());
    }

    public List<DeckResponse> getMarketDecks(Long userId) {
        List<Deck> publicDecks = deckRepository.findByIsPublicTrue();
        return publicDecks.stream()
                .map(deck -> mapToResponse(deck, userId))
                .collect(Collectors.toList());
    }

    @Transactional
    public DeckResponse acquireDeck(Long userId, Long deckId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Deck deck = deckRepository.findById(deckId)
                .orElseThrow(() -> new ResourceNotFoundException("Deck not found"));

        if (!deck.getIsPublic() && !deck.getCreator().getId().equals(userId)) {
            throw new RuntimeException("This deck is private");
        }

        if (userDeckRepository.existsByUserAndDeckId(user, deckId)) {
            throw new RuntimeException("You already have this deck");
        }

        // Logic for marketplace economy (coins) would go here
        if (deck.getPrice() > 0) {
            if (user.getCoins() < deck.getPrice()) {
                throw new RuntimeException("Not enough coins");
            }
            user.setCoins(user.getCoins() - deck.getPrice());
            userRepository.save(user);
            
            // Optional: Give coins to creator
            User creator = deck.getCreator();
            if (!creator.getId().equals(userId)) {
                creator.setCoins(creator.getCoins() + deck.getPrice());
                userRepository.save(creator);
            }
        }

        UserDeck userDeck = new UserDeck(userId, deck.getId(), user, deck, false, Instant.now());
        userDeckRepository.save(userDeck);

        return mapToResponse(deck, userId);
    }

    public DeckResponse updateDeck(Long userId, Long deckId, DeckRequest request) {
        Deck deck = deckRepository.findById(deckId)
                .orElseThrow(() -> new ResourceNotFoundException("Deck not found"));

        if (!deck.getCreator().getId().equals(userId)) {
            throw new RuntimeException("Unauthorized to update this deck");
        }

        deck.setTitle(request.getTitle());
        deck.setDescription(request.getDescription());
        deck.setTags(request.getTags());
        deck.setIsPublic(request.getIsPublic());
        deck.setPrice(request.getPrice());

        Deck updatedDeck = deckRepository.save(deck);
        return mapToResponse(updatedDeck, userId);
    }

    public void deleteDeck(Long userId, Long deckId) {
        Deck deck = deckRepository.findById(deckId)
                .orElseThrow(() -> new ResourceNotFoundException("Deck not found"));

        if (!deck.getCreator().getId().equals(userId)) {
            throw new RuntimeException("Unauthorized to delete this deck");
        }

        deckRepository.delete(deck);
    }

    private DeckResponse mapToResponse(Deck deck, Long requesterId) {
        boolean isOwned = false;
        if (requesterId != null) {
            User requester = userRepository.findById(requesterId).orElse(null);
            if (requester != null) {
                isOwned = userDeckRepository.existsByUserAndDeckId(requester, deck.getId());
            }
        }

        return DeckResponse.builder()
                .id(deck.getId())
                .title(deck.getTitle())
                .description(deck.getDescription())
                .tags(deck.getTags())
                .isPublic(deck.getIsPublic())
                .price(deck.getPrice())
                .creatorName(deck.getCreator().getDisplayName() != null ? deck.getCreator().getDisplayName() : deck.getCreator().getUsername())
                .createdAt(deck.getCreatedAt())
                .updatedAt(deck.getUpdatedAt())
                .isOwned(isOwned)
                .build();
    }
}
