package com.flashcard.backend.payload.request;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ProfileUpdateRequest {
    @Size(max = 50)
    private String displayName;

    @Size(max = 500)
    private String imageUrl;
}
