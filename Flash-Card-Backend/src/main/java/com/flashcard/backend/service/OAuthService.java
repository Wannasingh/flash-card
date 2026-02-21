package com.flashcard.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.flashcard.backend.repository.RoleRepository;
import com.flashcard.backend.repository.UserIdentityRepository;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.security.jwt.JwtUtils;
import com.flashcard.backend.security.oauth.JwksJwtVerifier;
import com.flashcard.backend.user.Role;
import com.flashcard.backend.user.User;
import com.flashcard.backend.user.UserIdentity;
import com.nimbusds.jose.JOSEException;
import com.nimbusds.jwt.JWTClaimsSet;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.text.ParseException;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@SuppressWarnings("null")
public class OAuthService {

    private static final String APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys";
    private static final String GOOGLE_JWKS_URL = "https://www.googleapis.com/oauth2/v3/certs";
    private static final String GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";

    private static final Pattern USERNAME_ALLOWED = Pattern.compile("[^a-z0-9]");

    private final HttpClient httpClient = HttpClient.newHttpClient();
    private final JwksJwtVerifier jwksJwtVerifier = new JwksJwtVerifier();

    @Value("${flashcard.oauth.apple.clientId:}")
    private String appleClientId;

    @Value("${flashcard.oauth.google.clientId:}")
    private String googleClientId;

    @Autowired
    UserRepository userRepository;

    @Autowired
    UserIdentityRepository userIdentityRepository;

    @Autowired
    RoleRepository roleRepository;

    @Autowired
    JwtUtils jwtUtils;

    @Autowired
    SupabaseStorageService storageService;

    @Autowired
    ObjectMapper objectMapper;

    @Transactional
    public com.flashcard.backend.payload.response.JwtResponse loginWithApple(String identityToken, String rawNonce, String displayName, HttpServletRequest request)
            throws ParseException, IOException, InterruptedException, JOSEException {

        if (appleClientId == null || appleClientId.isBlank()) {
            throw new IllegalStateException("Apple OAuth is not configured");
        }

        JWTClaimsSet claims = jwksJwtVerifier.verify(
                identityToken,
                APPLE_JWKS_URL,
                List.of("https://appleid.apple.com"),
                appleClientId
        );

        String providerUserId = claims.getSubject();
        String email = claims.getStringClaim("email");
        Boolean emailVerified = claims.getBooleanClaim("email_verified");
        String tokenNonce = claims.getStringClaim("nonce");

        if (rawNonce != null && !rawNonce.isBlank()) {
            String expectedNonce = sha256Base64Url(rawNonce);
            String expectedNonceHex = sha256Hex(rawNonce);
            if (tokenNonce == null || (!tokenNonce.equals(expectedNonce) && !tokenNonce.equals(expectedNonceHex))) {
                throw new IllegalStateException("Invalid nonce");
            }
        }

        if (email != null) {
            email = email.trim().toLowerCase();
        }

        String dn = displayName == null ? null : displayName.trim();
        if (dn != null && dn.isBlank()) {
            dn = null;
        }
        return loginOrCreate("APPLE", providerUserId, email, emailVerified != null && emailVerified, dn, null, request);
    }

    @Transactional
    public com.flashcard.backend.payload.response.JwtResponse loginWithGoogleCode(String code, String codeVerifier, String redirectUri, HttpServletRequest httpRequest)
            throws IOException, InterruptedException, ParseException, JOSEException {

        if (googleClientId == null || googleClientId.isBlank()) {
            throw new IllegalStateException("Google OAuth is not configured");
        }

        String body = "code=" + urlEncode(code) +
                "&client_id=" + urlEncode(googleClientId) +
                "&redirect_uri=" + urlEncode(redirectUri) +
                "&grant_type=authorization_code" +
                "&code_verifier=" + urlEncode(codeVerifier);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(GOOGLE_TOKEN_URL))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            System.err.println("Google token exchange failed. Status: " + response.statusCode());
            System.err.println("Body: " + response.body());
            throw new IllegalStateException("Google token exchange failed: " + response.body());
        }

        JsonNode json = objectMapper.readTree(response.body());
        String idToken = json.path("id_token").asText(null);
        if (idToken == null) {
            throw new IllegalStateException("Missing id_token");
        }

        JWTClaimsSet claims = jwksJwtVerifier.verify(
                idToken,
                GOOGLE_JWKS_URL,
                List.of("accounts.google.com", "https://accounts.google.com"),
                googleClientId
        );

        String providerUserId = claims.getSubject();
        String email = claims.getStringClaim("email");
        Boolean emailVerified = claims.getBooleanClaim("email_verified");
        String name = claims.getStringClaim("name");
        String picture = claims.getStringClaim("picture");

        if (email != null) {
            email = email.trim().toLowerCase();
        }

        return loginOrCreate("GOOGLE", providerUserId, email, emailVerified != null && emailVerified, name, picture, httpRequest);
    }

    private com.flashcard.backend.payload.response.JwtResponse loginOrCreate(
            String provider,
            String providerUserId,
            String email,
            boolean emailVerified,
            String displayName,
            String imageUrl,
            HttpServletRequest request
    ) {
        if (providerUserId == null || providerUserId.isBlank()) {
            throw new IllegalStateException("Missing provider user id");
        }

        Optional<UserIdentity> identityOpt = userIdentityRepository.findByProviderAndProviderUserId(provider, providerUserId);
        User user;
        if (identityOpt.isPresent()) {
            user = identityOpt.get().getUser();
            user.setLastLoginAt(Instant.now());
            
            boolean changed = false;
            if (displayName != null && !java.util.Objects.equals(user.getDisplayName(), displayName)) {
                user.setDisplayName(displayName);
                changed = true;
            }
            
            // Only update image if it's not manually set, or if it's currently null
            boolean isManual = "MANUAL".equals(user.getImageSource());
            if (imageUrl != null && !isManual && !java.util.Objects.equals(user.getImageUrl(), imageUrl)) {
                user.setImageUrl(imageUrl);
                user.setImageSource("OAUTH");
                user.setImageUpdatedAt(Instant.now());
                changed = true;
            }
            
            if (changed) {
                userRepository.save(user);
            }
            return issueJwt(user, request);
        }

        if (email == null || email.isBlank() || !emailVerified) {
            throw new IllegalStateException("Email is required for first login");
        }

        user = userRepository.findByEmail(email).orElseGet(() -> {
            String username = generateUsername(email);
            User u = User.oauthUser(username, email, displayName, imageUrl);
            Role userRole = roleRepository.findByName("ROLE_USER")
                    .orElseThrow(() -> new RuntimeException("Error: Role is not found."));
            u.getRoles().add(userRole);
            return userRepository.save(u);
        });

        if (user.getLastLoginAt() == null) {
            user.setLastLoginAt(Instant.now());
        } else {
            user.setLastLoginAt(Instant.now());
        }
        if (displayName != null && (user.getDisplayName() == null || user.getDisplayName().isBlank())) {
            user.setDisplayName(displayName);
        }
        if (imageUrl != null && (user.getImageUrl() == null || user.getImageUrl().isBlank())) {
            user.setImageUrl(imageUrl);
        }
        userRepository.save(user);

        UserIdentity identity = UserIdentity.of(user, provider, providerUserId);
        if (identity == null) {
            throw new RuntimeException("Could not create UserIdentity");
        }
        userIdentityRepository.save(identity);

        return issueJwt(user, request);
    }

    private com.flashcard.backend.payload.response.JwtResponse issueJwt(User user, HttpServletRequest request) {
        UserDetailsImpl userDetails = UserDetailsImpl.build(user);
        Authentication authentication = new UsernamePasswordAuthenticationToken(
                userDetails,
                null,
                userDetails.getAuthorities()
        );
        String jwt = jwtUtils.generateJwtToken(authentication);
        List<String> roles = userDetails.getAuthorities().stream().map(a -> a.getAuthority()).collect(Collectors.toList());
        
        // Use backend-proxied URL for Supabase images (bypasses iOS ATS)
        String imageUrl = userDetails.getImageUrl();
        if (imageUrl != null && !imageUrl.isEmpty() && !imageUrl.startsWith("http")) {
            // Supabase storage path → proxy through backend
            if (request != null) {
                String baseUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort();
                imageUrl = baseUrl + "/api/user/profile/" + user.getId() + "/image";
            } else {
                imageUrl = "/api/user/profile/" + user.getId() + "/image";
            }
        }

        return new com.flashcard.backend.payload.response.JwtResponse(
                jwt, 
                userDetails.getId(), 
                userDetails.getUsername(), 
                userDetails.getEmail(), 
                userDetails.getDisplayName(), 
                imageUrl, 
                roles
        );
    }

    private String generateUsername(String email) {
        String local = email.split("@")[0].toLowerCase();
        local = USERNAME_ALLOWED.matcher(local).replaceAll("");
        if (local.length() < 3) {
            local = "user";
        }
        local = local.length() > 16 ? local.substring(0, 16) : local;

        SecureRandom random = new SecureRandom();
        for (int i = 0; i < 20; i++) {
            String candidate = local + randomSuffix(random, 20 - local.length());
            if (candidate.length() > 20) {
                candidate = candidate.substring(0, 20);
            }
            if (!userRepository.existsByUsername(candidate)) {
                return candidate;
            }
        }
        throw new IllegalStateException("Failed to generate username");
    }

    private String randomSuffix(SecureRandom random, int maxLen) {
        int len = Math.min(4, Math.max(1, maxLen));
        String chars = "0123456789abcdefghijklmnopqrstuvwxyz";
        StringBuilder sb = new StringBuilder(len);
        for (int i = 0; i < len; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        return sb.toString();
    }

    private String sha256Base64Url(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(hashed);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available");
        }
    }

    private String sha256Hex(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(hashed.length * 2);
            for (byte b : hashed) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available");
        }
    }

    private String urlEncode(String v) {
        return URLEncoder.encode(v, StandardCharsets.UTF_8);
    }
}
