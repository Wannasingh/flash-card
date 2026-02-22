package com.flashcard.backend.controller;

import com.flashcard.backend.payload.request.CardRequest;
import com.flashcard.backend.payload.response.CardResponse;
import com.flashcard.backend.payload.response.MessageResponse;
import com.flashcard.backend.service.CardService;
import com.flashcard.backend.service.UserDetailsImpl;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api")
@Tag(name = "Card Management", description = "Card management APIs with multimedia support")
public class CardController {

    @Autowired
    private CardService cardService;

    @Operation(summary = "Create a new flashcard in a deck")
    @PostMapping("/decks/{deckId}/cards")
    public ResponseEntity<CardResponse> createCard(@PathVariable Long deckId,
                                                   @Valid @RequestBody CardRequest request,
                                                   @AuthenticationPrincipal UserDetailsImpl userDetails) {
        CardResponse response = cardService.createCard(userDetails.getId(), deckId, request);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Get all cards in a deck")
    @GetMapping("/decks/{deckId}/cards")
    public ResponseEntity<List<CardResponse>> getCardsByDeckId(@PathVariable Long deckId) {
        // Typically, you might want to check if the deck is public or owned by the user
        // but for flashcards, if they have the deckId, we can return the cards.
        List<CardResponse> cards = cardService.getCardsByDeckId(deckId);
        return ResponseEntity.ok(cards);
    }

    @Operation(summary = "Update a flashcard (Creator only)")
    @PutMapping("/cards/{cardId}")
    public ResponseEntity<CardResponse> updateCard(@PathVariable Long cardId,
                                                   @Valid @RequestBody CardRequest request,
                                                   @AuthenticationPrincipal UserDetailsImpl userDetails) {
        CardResponse response = cardService.updateCard(userDetails.getId(), cardId, request);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Delete a flashcard (Creator only)")
    @DeleteMapping("/cards/{cardId}")
    public ResponseEntity<MessageResponse> deleteCard(@PathVariable Long cardId,
                                                      @AuthenticationPrincipal UserDetailsImpl userDetails) {
        cardService.deleteCard(userDetails.getId(), cardId);
        return ResponseEntity.ok(new MessageResponse("Card deleted successfully"));
    }

    // AI Endpoint
    @Operation(summary = "Generate AI Mnemonic (Integrated Mock)")
    @PostMapping("/cards/ai-mnemonic")
    public ResponseEntity<?> generateAiMnemonic(@RequestBody CardRequest request,
                                               @RequestParam(required = false) Long cardId,
                                               @AuthenticationPrincipal UserDetailsImpl userDetails) {
        String frontText = request.getFrontText();
        String backText = request.getBackText();
        
        // Simulating AI Logic: "Brainy" mnemonic generation
        String mnemonic = "To remember '" + frontText + "' (which means " + backText + "), " +
                         "visualize a neon-lit " + frontText.toLowerCase() + " performing a glitch-hop dance!";
        
        if (cardId != null) {
            CardResponse response = cardService.updateMnemonic(userDetails.getId(), cardId, mnemonic);
            return ResponseEntity.ok(response);
        }
        
        return ResponseEntity.ok(new MessageResponse(mnemonic));
    }
}
