package com.flashcard.backend.payload.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class BrainDumpRequest {
    @NotBlank(message = "Text content is required for Brain Dump")
    private String text;
}
