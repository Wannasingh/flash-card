package com.flashcard.backend.controller;

import com.flashcard.backend.entity.RefreshToken;
import com.flashcard.backend.payload.request.LoginRequest;
import com.flashcard.backend.payload.request.SignupRequest;
import com.flashcard.backend.payload.response.JwtResponse;
import com.flashcard.backend.payload.response.MessageResponse;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.security.jwt.JwtUtils;
import com.flashcard.backend.service.AuthService;
import com.flashcard.backend.service.RefreshTokenService;
import com.flashcard.backend.service.UserDetailsImpl;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpServletRequest;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    AuthService authService;

    @Autowired
    RefreshTokenService refreshTokenService;

    @Autowired
    JwtUtils jwtUtils;

    @Autowired
    UserRepository userRepository;

    @Autowired
    UserDetailsService userDetailsService;

    @PostMapping("/signin")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest, HttpServletRequest request) {
        return authService.authenticateUser(loginRequest, request);
    }

    @PostMapping("/signup")
    public ResponseEntity<?> registerUser(@Valid @RequestBody SignupRequest signupRequest) {
        return authService.registerUser(signupRequest);
    }

    /**
     * Silent token refresh — called by iOS when it receives a 401.
     * Validates the refresh token, rotates it (one-time use), and returns a new access token.
     */
    @PostMapping("/refresh")
    public ResponseEntity<?> refreshToken(@RequestBody Map<String, String> body) {
        String rawRefreshToken = body.get("refreshToken");
        if (rawRefreshToken == null || rawRefreshToken.isBlank()) {
            return ResponseEntity.badRequest().body(new MessageResponse("refreshToken is required"));
        }

        // Validate + rotate (delete old, create new)
        RefreshToken validated = refreshTokenService.validateRefreshToken(rawRefreshToken);
        RefreshToken newRefreshToken = refreshTokenService.rotateRefreshToken(validated);

        // Issue new access token
        UserDetailsImpl userDetails = (UserDetailsImpl) userDetailsService.loadUserByUsername(
                validated.getUser().getUsername());
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                userDetails, null, userDetails.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
        String newAccessToken = jwtUtils.generateJwtToken(auth);

        List<String> roles = userDetails.getAuthorities().stream()
                .map(a -> a.getAuthority())
                .collect(Collectors.toList());

        System.out.println("[API] 🔄 Token refreshed for user: " + userDetails.getUsername());

        return ResponseEntity.ok(new JwtResponse(
                newAccessToken, newRefreshToken.getToken(),
                userDetails.getId(), userDetails.getUsername(), userDetails.getEmail(),
                userDetails.getDisplayName(), userDetails.getImageUrl(),
                roles, 0L, 0L, null, null, null));
    }

    /**
     * Logout — revokes the refresh token server-side.
     */
    @PostMapping("/logout")
    public ResponseEntity<?> logout(@RequestBody Map<String, String> body) {
        String rawRefreshToken = body.get("refreshToken");
        if (rawRefreshToken != null && !rawRefreshToken.isBlank()) {
            try {
                RefreshToken rt = refreshTokenService.validateRefreshToken(rawRefreshToken);
                refreshTokenService.revokeAllForUser(rt.getUser());
            } catch (Exception ignored) { /* already expired or invalid — fine */ }
        }
        return ResponseEntity.ok(new MessageResponse("Logged out successfully"));
    }
}

