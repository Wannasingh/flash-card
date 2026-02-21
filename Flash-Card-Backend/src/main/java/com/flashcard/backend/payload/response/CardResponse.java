package com.flashcard.backend.payload.response;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;

@Data
@Builder
public class CardResponse {
    private Long id;
    private Long deckId;
    private String frontText;
    private String backText;
    private String imageUrl;
    private String videoUrl;
    private String arModelUrl;
    private String memeUrl;
    private String aiMnemonic;
    private Instant createdAt;
    private Instant updatedAt;
}
