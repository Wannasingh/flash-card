package com.flashcard.backend.payload.response;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.List;

@Data
@Builder
public class DeckResponse {
    private Long id;
    private String title;
    private String description;
    private List<String> tags;
    private Boolean isPublic;
    private Integer price;
    private String creatorName;
    private Instant createdAt;
    private Instant updatedAt;
    // Specific to the user fetching this request
    private Boolean isOwned;
}
