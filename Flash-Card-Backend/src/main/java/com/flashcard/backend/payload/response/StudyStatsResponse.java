package com.flashcard.backend.payload.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class StudyStatsResponse {
    private Integer coins;
    private Integer streakDays;
    private Long totalCardsStudied;
    private Long cardsDueToday;
}
