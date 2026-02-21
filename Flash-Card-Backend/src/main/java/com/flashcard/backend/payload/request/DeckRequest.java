package com.flashcard.backend.payload.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;

@Data
public class DeckRequest {
    @NotBlank
    private String title;
    private String description;
    private List<String> tags;
    private Boolean isPublic = false;
    private Integer price = 0;
}
