package com.flashcard.backend.payload.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CardRequest {
    @NotBlank
    private String frontText;
    
    @NotBlank
    private String backText;
    
    private String imageUrl;
    private String videoUrl;
    private String arModelUrl;
    private String memeUrl;
    private String aiMnemonic;
}
