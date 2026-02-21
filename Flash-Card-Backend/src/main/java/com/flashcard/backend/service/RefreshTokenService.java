package com.flashcard.backend.service;

import com.flashcard.backend.entity.RefreshToken;
import com.flashcard.backend.repository.RefreshTokenRepository;
import com.flashcard.backend.user.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

@Service
@SuppressWarnings("null")
public class RefreshTokenService {

    @Value("${flashcard.app.refreshTokenExpiryDays:90}")
    private int refreshTokenExpiryDays;

    @Autowired
    private RefreshTokenRepository refreshTokenRepository;

    /**
     * Create a new refresh token for the given user.
     * Old tokens for the same user are deleted first (single-session per user).
     */
    @Transactional
    public RefreshToken createRefreshToken(User user) {
        // Delete any existing refresh tokens for this user (single active refresh token)
        refreshTokenRepository.deleteByUser(user);

        RefreshToken refreshToken = new RefreshToken(
                UUID.randomUUID().toString(),
                user,
                Instant.now().plus(refreshTokenExpiryDays, ChronoUnit.DAYS)
        );

        return refreshTokenRepository.save(refreshToken);
    }

    /**
     * Validate the token string. Returns the RefreshToken entity if valid.
     * Throws 401 if not found or expired.
     */
    @Transactional
    public RefreshToken validateRefreshToken(String tokenString) {
        RefreshToken token = refreshTokenRepository.findByToken(tokenString)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Refresh token not found. Please login again."));

        if (token.isExpired()) {
            refreshTokenRepository.delete(token);
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Refresh token expired. Please login again.");
        }

        return token;
    }

    /**
     * Rotate the refresh token: delete old one, issue a new one.
     * This prevents refresh token reuse attacks.
     */
    @Transactional
    public RefreshToken rotateRefreshToken(RefreshToken oldToken) {
        refreshTokenRepository.delete(oldToken);
        return createRefreshToken(oldToken.getUser());
    }

    /**
     * Revoke all tokens for a user (called on logout).
     */
    @Transactional
    public void revokeAllForUser(User user) {
        refreshTokenRepository.deleteByUser(user);
    }
}
