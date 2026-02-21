package com.flashcard.backend.payload.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BrainDumpCardDto {
    private String frontText;
    private String backText;
    private String aiMnemonic;
}
