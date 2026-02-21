package com.flashcard.backend.payload.response;

import lombok.Data;

import java.util.List;

@Data
public class JwtResponse {
    private String token;
    private String type = "Bearer";
    private Long id;
    private String username;
    private String email;
    private String displayName;
    private String imageUrl;
    private List<String> roles;
    private Long totalXP = 0L;
    private Long weeklyXP = 0L;
    private List<com.flashcard.backend.user.Badge> badges;
    private String activeAuraCode;
    private String activeSkinCode;

    public JwtResponse(String accessToken, Long id, String username, String email, String displayName, String imageUrl, List<String> roles, Long totalXP, Long weeklyXP) {
        this(accessToken, id, username, email, displayName, imageUrl, roles, totalXP, weeklyXP, null, null, null);
    }

    public JwtResponse(String accessToken, Long id, String username, String email, String displayName, String imageUrl, List<String> roles, Long totalXP, Long weeklyXP, List<com.flashcard.backend.user.Badge> badges) {
        this(accessToken, id, username, email, displayName, imageUrl, roles, totalXP, weeklyXP, badges, null, null);
    }

    public JwtResponse(String accessToken, Long id, String username, String email, String displayName, String imageUrl, List<String> roles, Long totalXP, Long weeklyXP, List<com.flashcard.backend.user.Badge> badges, String activeAuraCode, String activeSkinCode) {
        this.token = accessToken;
        this.id = id;
        this.username = username;
        this.email = email;
        this.displayName = displayName;
        this.imageUrl = imageUrl;
        this.roles = roles;
        this.totalXP = totalXP;
        this.weeklyXP = weeklyXP;
        this.badges = badges;
        this.activeAuraCode = activeAuraCode;
        this.activeSkinCode = activeSkinCode;
    }

    public JwtResponse(String accessToken, Long id, String username, String email, String displayName, String imageUrl, List<String> roles) {
        this(accessToken, id, username, email, displayName, imageUrl, roles, 0L, 0L, null, null, null);
    }
}
