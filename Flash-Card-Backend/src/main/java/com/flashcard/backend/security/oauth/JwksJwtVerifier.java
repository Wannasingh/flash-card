package com.flashcard.backend.security.oauth;

import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.RSASSAVerifier;
import com.nimbusds.jose.jwk.JWK;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.text.ParseException;
import java.time.Instant;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;

public class JwksJwtVerifier {

    private final HttpClient httpClient = HttpClient.newHttpClient();

    private final ConcurrentHashMap<String, CachedJwks> jwksCache = new ConcurrentHashMap<>();

    public JWTClaimsSet verify(String jwt, String jwksUrl, List<String> expectedIssuers, String expectedAudience)
            throws ParseException, IOException, InterruptedException, JOSEException {

        SignedJWT signedJWT = SignedJWT.parse(jwt);
        JWSHeader header = signedJWT.getHeader();
        if (!JWSAlgorithm.RS256.equals(header.getAlgorithm())) {
            throw new IllegalStateException("Unsupported JWT alg");
        }

        JWKSet jwkSet = getJwks(jwksUrl);
        JWK jwk = jwkSet.getKeyByKeyId(header.getKeyID());
        if (jwk == null) {
            jwkSet = refreshJwks(jwksUrl);
            jwk = jwkSet.getKeyByKeyId(header.getKeyID());
        }
        if (jwk == null) {
            throw new IllegalStateException("JWK not found");
        }

        RSAKey rsaKey = jwk.toRSAKey();
        if (!signedJWT.verify(new RSASSAVerifier(rsaKey))) {
            throw new IllegalStateException("Invalid JWT signature");
        }

        JWTClaimsSet claims = signedJWT.getJWTClaimsSet();
        validateClaims(claims, expectedIssuers, expectedAudience);
        return claims;
    }

    private void validateClaims(JWTClaimsSet claims, List<String> expectedIssuers, String expectedAudience) {
        String iss = claims.getIssuer();
        if (iss == null || expectedIssuers.stream().noneMatch(e -> Objects.equals(e, iss))) {
            throw new IllegalStateException("Invalid issuer");
        }

        List<String> aud = claims.getAudience();
        if (aud == null || aud.stream().noneMatch(a -> Objects.equals(a, expectedAudience))) {
            throw new IllegalStateException("Invalid audience");
        }

        Date exp = claims.getExpirationTime();
        if (exp == null || exp.toInstant().isBefore(Instant.now())) {
            throw new IllegalStateException("Token expired");
        }
    }

    private JWKSet getJwks(String jwksUrl) throws IOException, InterruptedException, ParseException {
        CachedJwks cached = jwksCache.get(jwksUrl);
        if (cached != null && cached.expiresAtEpochMs > System.currentTimeMillis()) {
            return cached.jwkSet;
        }
        return refreshJwks(jwksUrl);
    }

    private JWKSet refreshJwks(String jwksUrl) throws IOException, InterruptedException, ParseException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(jwksUrl))
                .GET()
                .build();
        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IllegalStateException("Failed to fetch JWKS");
        }

        JWKSet jwkSet = JWKSet.parse(response.body());

        long ttlMs = parseCacheTtlMs(response.headers().map());
        long expiresAt = System.currentTimeMillis() + ttlMs;
        jwksCache.put(jwksUrl, new CachedJwks(jwkSet, expiresAt));
        return jwkSet;
    }

    private long parseCacheTtlMs(Map<String, List<String>> headers) {
        List<String> cacheControl = headers.get("cache-control");
        if (cacheControl == null) {
            cacheControl = headers.get("Cache-Control");
        }
        if (cacheControl != null) {
            for (String v : cacheControl) {
                String[] parts = v.split(",");
                for (String part : parts) {
                    String p = part.trim().toLowerCase();
                    if (p.startsWith("max-age=")) {
                        String s = p.substring("max-age=".length());
                        try {
                            long seconds = Long.parseLong(s);
                            return Math.max(60_000, seconds * 1000);
                        } catch (NumberFormatException ignored) {
                            return 300_000;
                        }
                    }
                }
            }
        }
        return 300_000;
    }

    private record CachedJwks(JWKSet jwkSet, long expiresAtEpochMs) {
    }
}
