package com.flashcard.backend.payload.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AppleOAuthRequest {
    @NotBlank
    private String identityToken;

    private String rawNonce;

    private String displayName;
}
