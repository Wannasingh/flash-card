package com.flashcard.backend.payload.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class GoogleOAuthRequest {
    @NotBlank
    private String code;

    @NotBlank
    private String codeVerifier;

    @NotBlank
    private String redirectUri;
}
