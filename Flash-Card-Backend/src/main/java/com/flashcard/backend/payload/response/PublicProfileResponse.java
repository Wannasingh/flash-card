package com.flashcard.backend.payload.response;

import com.flashcard.backend.user.Badge;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class PublicProfileResponse {
    private Long id;
    private String username;
    private String displayName;
    private String imageUrl;
    private Long totalXP;
    private Long weeklyXP;
    private Integer streakDays;
    private List<Badge> badges;
    private String activeAuraCode;
    private String activeSkinCode;
}
