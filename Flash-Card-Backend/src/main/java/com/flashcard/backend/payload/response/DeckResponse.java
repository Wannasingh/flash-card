package com.flashcard.backend.payload.response;

import com.fasterxml.jackson.annotation.JsonProperty;
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
    private String coverImageUrl;
    private String previewVideoUrl;
    
    // Custom hex color (can be generated or stored)
    private String customColorHex;
    
    @JsonProperty("priceCoins")
    private Integer price;
    
    private Boolean isPublic;
    
    private Long creatorId;
    private String creatorName;
    
    private Integer cardCount;
    
    @JsonProperty("owned")
    private Boolean isOwned;

    private List<String> tags;
    private Instant createdAt;
    private Instant updatedAt;
}
