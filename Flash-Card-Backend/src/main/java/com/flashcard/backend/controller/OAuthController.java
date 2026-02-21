package com.flashcard.backend.controller;

import com.flashcard.backend.payload.request.AppleOAuthRequest;
import com.flashcard.backend.payload.request.GoogleOAuthRequest;
import com.flashcard.backend.service.OAuthService;
import com.flashcard.backend.payload.response.JwtResponse;
import com.flashcard.backend.security.jwt.JwtUtils;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/auth/oauth")
@SuppressWarnings("null")
public class OAuthController {

    @Autowired
    OAuthService oauthService;

    @Autowired
    JwtUtils jwtUtils;

    @PostMapping("/apple")
    public ResponseEntity<?> apple(@Valid @RequestBody AppleOAuthRequest request, HttpServletRequest httpRequest) throws Exception {
        JwtResponse response = oauthService.loginWithApple(request.getIdentityToken(), request.getRawNonce(), request.getDisplayName(), httpRequest);
        ResponseCookie cookie = jwtUtils.generateJwtCookie(response.getToken());
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, cookie.toString())
                .body(response);
    }

    @PostMapping("/google")
    public ResponseEntity<?> google(@Valid @RequestBody GoogleOAuthRequest request, HttpServletRequest httpRequest) throws Exception {
        JwtResponse response = oauthService.loginWithGoogleCode(request.getCode(), request.getCodeVerifier(), request.getRedirectUri(), httpRequest);
        ResponseCookie cookie = jwtUtils.generateJwtCookie(response.getToken());
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, cookie.toString())
                .body(response);
    }
}
