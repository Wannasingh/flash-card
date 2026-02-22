package com.flashcard.backend.payload.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class LeaderboardEntry {
    private Long userId;
    private String username;
    private String displayName;
    private String imageUrl;
    private Double xp;
    private Integer rank;
    private Integer streak;
    private String activeAuraCode;
}
