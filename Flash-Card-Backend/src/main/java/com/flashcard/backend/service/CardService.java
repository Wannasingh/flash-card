package com.flashcard.backend.service;

import com.flashcard.backend.entity.Card;
import com.flashcard.backend.entity.Deck;
import com.flashcard.backend.exception.ResourceNotFoundException;
import com.flashcard.backend.payload.request.CardRequest;
import com.flashcard.backend.payload.response.CardResponse;
import com.flashcard.backend.repository.CardRepository;
import com.flashcard.backend.repository.DeckRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class CardService {

    @Autowired
    private CardRepository cardRepository;

    @Autowired
    private DeckRepository deckRepository;

    public CardResponse createCard(Long userId, Long deckId, CardRequest request) {
        Deck deck = deckRepository.findById(deckId)
                .orElseThrow(() -> new ResourceNotFoundException("Deck not found"));

        if (!deck.getCreator().getId().equals(userId)) {
            throw new RuntimeException("Unauthorized to modify this deck");
        }

        Card card = new Card();
        card.setDeck(deck);
        card.setFrontText(request.getFrontText());
        card.setBackText(request.getBackText());
        card.setImageUrl(request.getImageUrl());
        card.setVideoUrl(request.getVideoUrl());
        card.setArModelUrl(request.getArModelUrl());
        card.setMemeUrl(request.getMemeUrl());
        card.setAiMnemonic(request.getAiMnemonic());

        Card savedCard = cardRepository.save(card);
        return mapToResponse(savedCard);
    }

    public List<CardResponse> getCardsByDeckId(Long deckId) {
        Deck deck = deckRepository.findById(deckId)
                .orElseThrow(() -> new ResourceNotFoundException("Deck not found"));
        
        List<Card> cards = cardRepository.findByDeck(deck);
        return cards.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public CardResponse updateCard(Long userId, Long cardId, CardRequest request) {
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new ResourceNotFoundException("Card not found"));

        if (!card.getDeck().getCreator().getId().equals(userId)) {
            throw new RuntimeException("Unauthorized to update this card");
        }

        card.setFrontText(request.getFrontText());
        card.setBackText(request.getBackText());
        card.setImageUrl(request.getImageUrl());
        card.setVideoUrl(request.getVideoUrl());
        card.setArModelUrl(request.getArModelUrl());
        card.setMemeUrl(request.getMemeUrl());
        card.setAiMnemonic(request.getAiMnemonic());

        Card updatedCard = cardRepository.save(card);
        return mapToResponse(updatedCard);
    }

    public void deleteCard(Long userId, Long cardId) {
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new ResourceNotFoundException("Card not found"));

        if (!card.getDeck().getCreator().getId().equals(userId)) {
            throw new RuntimeException("Unauthorized to delete this card");
        }

        cardRepository.delete(card);
    }

    private CardResponse mapToResponse(Card card) {
        return CardResponse.builder()
                .id(card.getId())
                .deckId(card.getDeck().getId())
                .frontText(card.getFrontText())
                .backText(card.getBackText())
                .imageUrl(card.getImageUrl())
                .videoUrl(card.getVideoUrl())
                .arModelUrl(card.getArModelUrl())
                .memeUrl(card.getMemeUrl())
                .aiMnemonic(card.getAiMnemonic())
                .createdAt(card.getCreatedAt())
                .updatedAt(card.getUpdatedAt())
                .build();
    }
}
