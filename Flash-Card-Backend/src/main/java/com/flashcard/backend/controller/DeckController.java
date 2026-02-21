package com.flashcard.backend.controller;

import com.flashcard.backend.payload.request.DeckRequest;
import com.flashcard.backend.payload.response.DeckResponse;
import com.flashcard.backend.payload.response.MessageResponse;
import com.flashcard.backend.service.DeckService;
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
@RequestMapping("/api/decks")
@Tag(name = "Deck Management", description = "Marketplace and private deck management APIs")
public class DeckController {

    @Autowired
    private DeckService deckService;

    @Operation(summary = "Create a new flashcard deck")
    @PostMapping
    public ResponseEntity<DeckResponse> createDeck(@Valid @RequestBody DeckRequest request,
                                                  @AuthenticationPrincipal UserDetailsImpl userDetails) {
        DeckResponse response = deckService.createDeck(userDetails.getId(), request);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Get user's personal flashcard decks")
    @GetMapping("/my")
    public ResponseEntity<List<DeckResponse>> getMyDecks(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        List<DeckResponse> decks = deckService.getMyDecks(userDetails.getId());
        return ResponseEntity.ok(decks);
    }

    @Operation(summary = "Get all public/marketplace decks")
    @GetMapping("/market")
    public ResponseEntity<List<DeckResponse>> getMarketDecks(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        List<DeckResponse> decks = deckService.getMarketDecks(userDetails.getId());
        return ResponseEntity.ok(decks);
    }

    @Operation(summary = "Acquire (Buy/Add) a public deck to user's library")
    @PostMapping("/{deckId}/acquire")
    public ResponseEntity<DeckResponse> acquireDeck(@PathVariable Long deckId,
                                                   @AuthenticationPrincipal UserDetailsImpl userDetails) {
        DeckResponse response = deckService.acquireDeck(userDetails.getId(), deckId);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Update deck details (Creator only)")
    @PutMapping("/{deckId}")
    public ResponseEntity<DeckResponse> updateDeck(@PathVariable Long deckId,
                                                  @Valid @RequestBody DeckRequest request,
                                                  @AuthenticationPrincipal UserDetailsImpl userDetails) {
        DeckResponse response = deckService.updateDeck(userDetails.getId(), deckId, request);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Delete a deck (Creator only)")
    @DeleteMapping("/{deckId}")
    public ResponseEntity<MessageResponse> deleteDeck(@PathVariable Long deckId,
                                                     @AuthenticationPrincipal UserDetailsImpl userDetails) {
        deckService.deleteDeck(userDetails.getId(), deckId);
        return ResponseEntity.ok(new MessageResponse("Deck deleted successfully"));
    }
}
