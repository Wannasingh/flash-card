package com.flashcard.backend.security.jwt;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.flashcard.backend.service.UserDetailsServiceImpl;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.security.SignatureException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;

/**
 * JWT Authentication Filter.
 *
 * Design Principle:
 *   - NEVER crash with 500 due to a bad/expired token.
 *   - If token is missing  → pass through (let Spring Security decide based on endpoint config).
 *   - If token is invalid  → immediately respond 401 JSON, do NOT continue the filter chain.
 *   - If token is valid    → set authentication context and continue normally.
 *
 * Mobile Best Practice:
 *   - Clients (iOS/Android) MUST send the JWT in the Authorization header:
 *       Authorization: Bearer <token>
 *   - Tokens should be stored in Keychain (iOS) or EncryptedSharedPreferences (Android), NOT in plain storage.
 *   - When server returns 401, the app should attempt a token refresh before re-logging the user out.
 */
@Component
public class AuthTokenFilter extends OncePerRequestFilter {
    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private UserDetailsServiceImpl userDetailsService;

    private static final Logger logger = LoggerFactory.getLogger(AuthTokenFilter.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected boolean shouldNotFilter(@NonNull HttpServletRequest request) throws ServletException {
        String path = request.getRequestURI();
        logger.debug("AuthTokenFilter shouldNotFilter invoked for path: {}", path);
        boolean shouldSkip = path.startsWith("/api/auth/") || path.startsWith("/api/openai/")
                || path.startsWith("/scalar") || path.startsWith("/v3/api-docs/") || path.startsWith("/webjars/");
        logger.debug("shouldNotFilter returning: {}", shouldSkip);
        return shouldSkip;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        logger.debug("AuthTokenFilter doFilterInternal invoked for path: {}", request.getRequestURI());

        String jwt = parseJwt(request);

        // No token present – pass through and let Spring Security handle it based on
        // whether the endpoint is protected or public.
        if (jwt == null) {
            filterChain.doFilter(request, response);
            return;
        }

        // Token exists → validate it. ANY error → 401 immediately.
        try {
            if (jwtUtils.validateJwtToken(jwt)) {
                String username = jwtUtils.getUserNameFromJwtToken(jwt);
                UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        userDetails, null, userDetails.getAuthorities());
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        } catch (ExpiredJwtException e) {
            System.out.println("[API] 🔑 JWT expired [" + request.getRequestURI() + "] → responding 401");
            sendUnauthorized(response, "Token expired. Please login again.");
            return;
        } catch (MalformedJwtException e) {
            System.out.println("[API] 🔑 JWT malformed [" + request.getRequestURI() + "] → responding 401");
            sendUnauthorized(response, "Invalid token format.");
            return;
        } catch (SignatureException e) {
            System.out.println("[API] 🔑 JWT bad signature [" + request.getRequestURI() + "] → responding 401");
            sendUnauthorized(response, "Token signature verification failed.");
            return;
        } catch (Exception e) {
            System.out.println("[API] ⚠️  Auth filter error [" + request.getRequestURI() + "] → " + e.getClass().getSimpleName() + ": " + e.getMessage());
            sendUnauthorized(response, "Authentication failed.");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private String parseJwt(HttpServletRequest request) {
        String headerAuth = request.getHeader("Authorization");
        if (StringUtils.hasText(headerAuth) && headerAuth.startsWith("Bearer ")) {
            return headerAuth.substring(7);
        }
        // Fallback: check for JWT in cookie (for browser-based flows)
        return jwtUtils.getJwtFromCookies(request);
    }

    /**
     * Write a clean JSON 401 response. This ensures the Filter chain is stopped
     * and the client sees a proper error rather than being forwarded to a protected
     * controller that would crash with a NullPointerException on authentication.
     */
    private void sendUnauthorized(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpStatus.UNAUTHORIZED.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        Map<String, Object> body = Map.of(
                "status", 401,
                "error", "Unauthorized",
                "message", message,
                "timestamp", System.currentTimeMillis()
        );
        response.getWriter().write(objectMapper.writeValueAsString(body));
    }
}
