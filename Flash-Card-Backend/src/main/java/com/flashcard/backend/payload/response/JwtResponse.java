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

    public JwtResponse(String accessToken, Long id, String username, String email, String displayName, String imageUrl, List<String> roles) {
        this.token = accessToken;
        this.id = id;
        this.username = username;
        this.email = email;
        this.displayName = displayName;
        this.imageUrl = imageUrl;
        this.roles = roles;
    }
}
