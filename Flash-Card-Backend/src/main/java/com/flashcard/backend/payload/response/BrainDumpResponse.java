package com.flashcard.backend.payload.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BrainDumpResponse {
    private List<BrainDumpCardDto> cards;
}
