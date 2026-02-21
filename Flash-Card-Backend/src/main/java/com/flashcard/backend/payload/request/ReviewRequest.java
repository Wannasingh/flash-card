package com.flashcard.backend.payload.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ReviewRequest {
    @NotNull
    @Min(0)
    @Max(5)
    private Integer quality; // Quality of recall (0-5) based on SuperMemo-2
}
