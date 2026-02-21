package com.flashcard.backend.security.filter;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.flashcard.backend.exception.ApiError;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class AuthRateLimitFilter extends OncePerRequestFilter {

    private static final long WINDOW_SECONDS = 60;

    private final ObjectMapper objectMapper;
    private final ConcurrentHashMap<String, WindowCounter> signinCounters = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, WindowCounter> signupCounters = new ConcurrentHashMap<>();

    @Value("${flashcard.security.ratelimit.signin.perMinute:10}")
    private int signinPerMinute = 10;

    @Value("${flashcard.security.ratelimit.signup.perMinute:5}")
    private int signupPerMinute = 5;

    public AuthRateLimitFilter(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    protected boolean shouldNotFilter(@NonNull HttpServletRequest request) {
        if (!"POST".equalsIgnoreCase(request.getMethod())) {
            return true;
        }
        String path = request.getRequestURI();
        return !Objects.equals(path, "/api/auth/signin") && !Objects.equals(path, "/api/auth/signup");
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        String path = request.getRequestURI();
        String key = clientKey(request) + "|" + path;

        if (Objects.equals(path, "/api/auth/signin")) {
            if (!allow(signinCounters, key, signinPerMinute)) {
                writeTooManyRequests(response, request);
                return;
            }
        }

        if (Objects.equals(path, "/api/auth/signup")) {
            if (!allow(signupCounters, key, signupPerMinute)) {
                writeTooManyRequests(response, request);
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    private boolean allow(ConcurrentHashMap<String, WindowCounter> map, String key, int limit) {
        long now = System.currentTimeMillis() / 1000;
        WindowCounter counter = map.compute(key, (k, existing) -> {
            if (existing == null || now - existing.windowStartEpochSecond >= WINDOW_SECONDS) {
                return new WindowCounter(now, 1);
            }
            return new WindowCounter(existing.windowStartEpochSecond, existing.count + 1);
        });
        return counter.count <= limit;
    }

    private void writeTooManyRequests(HttpServletResponse response, HttpServletRequest request) throws IOException {
        HttpStatus status = HttpStatus.TOO_MANY_REQUESTS;
        response.setStatus(status.value());
        response.setContentType("application/json");

        ApiError body = new ApiError(
                System.currentTimeMillis(),
                status.value(),
                status.getReasonPhrase(),
                "Too many requests",
                request.getRequestURI(),
                null);

        response.getWriter().write(objectMapper.writeValueAsString(body));
    }

    private String clientKey(HttpServletRequest request) {
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isBlank()) {
            return xff.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private record WindowCounter(long windowStartEpochSecond, int count) {
    }
}
