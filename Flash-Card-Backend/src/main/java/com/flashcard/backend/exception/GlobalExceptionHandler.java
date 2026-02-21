package com.flashcard.backend.exception;

import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.security.SignatureException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.text.ParseException;
import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // ─── Validation Errors ───────────────────────────────────────────────────────

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex, HttpServletRequest request) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        for (FieldError fe : ex.getBindingResult().getFieldErrors()) {
            if (!fieldErrors.containsKey(fe.getField())) {
                fieldErrors.put(fe.getField(), fe.getDefaultMessage());
            }
        }
        log("⚠️  Validation failed [" + request.getMethod() + " " + request.getRequestURI() + "] → " + fieldErrors);
        return build(HttpStatus.BAD_REQUEST, "Validation failed", request, fieldErrors);
    }

    // ─── Database / Conflict ─────────────────────────────────────────────────────

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiError> handleDataIntegrity(DataIntegrityViolationException ex, HttpServletRequest request) {
        log("⚠️  Data conflict [" + request.getRequestURI() + "] → " + ex.getMostSpecificCause().getMessage());
        return build(HttpStatus.CONFLICT, "Data conflict: resource already exists", request, null);
    }

    // ─── Auth Errors ──────────────────────────────────────────────────────────────

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ApiError> handleBadCredentials(BadCredentialsException ex, HttpServletRequest request) {
        log("🔐 Bad credentials [" + request.getRequestURI() + "]");
        return build(HttpStatus.UNAUTHORIZED, "Invalid username or password", request, null);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiError> handleAccessDenied(AccessDeniedException ex, HttpServletRequest request) {
        log("🚫 Access denied [" + request.getMethod() + " " + request.getRequestURI() + "] → Need higher role");
        return build(HttpStatus.FORBIDDEN, "You don't have permission to access this resource", request, null);
    }

    // ─── JWT Errors ──────────────────────────────────────────────────────────────

    @ExceptionHandler(ExpiredJwtException.class)
    public ResponseEntity<ApiError> handleExpiredJwt(ExpiredJwtException ex, HttpServletRequest request) {
        log("🔑 JWT expired [" + request.getRequestURI() + "]");
        return build(HttpStatus.UNAUTHORIZED, "Token expired. Please login again.", request, null);
    }

    @ExceptionHandler(MalformedJwtException.class)
    public ResponseEntity<ApiError> handleMalformedJwt(MalformedJwtException ex, HttpServletRequest request) {
        log("🔑 JWT malformed [" + request.getRequestURI() + "]");
        return build(HttpStatus.UNAUTHORIZED, "Invalid token format", request, null);
    }

    @ExceptionHandler(SignatureException.class)
    public ResponseEntity<ApiError> handleBadSignature(SignatureException ex, HttpServletRequest request) {
        log("🔑 JWT bad signature [" + request.getRequestURI() + "]");
        return build(HttpStatus.UNAUTHORIZED, "Token signature verification failed", request, null);
    }

    @ExceptionHandler(ParseException.class)
    public ResponseEntity<ApiError> handleJwtParse(ParseException ex, HttpServletRequest request) {
        log("🔑 JWT parse error [" + request.getRequestURI() + "]");
        return build(HttpStatus.UNAUTHORIZED, "Invalid token", request, null);
    }

    // ─── Bad Requests ─────────────────────────────────────────────────────────────

    @ExceptionHandler({ IllegalStateException.class, IllegalArgumentException.class })
    public ResponseEntity<ApiError> handleBadRequest(RuntimeException ex, HttpServletRequest request) {
        log("⚠️  Bad request [" + request.getRequestURI() + "] → " + ex.getMessage());
        return build(HttpStatus.BAD_REQUEST, "Bad request: " + ex.getMessage(), request, null);
    }

    // ─── Catch-all (500) ─────────────────────────────────────────────────────────

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleGeneric(Exception ex, HttpServletRequest request) {
        log("❌ Internal error [" + request.getMethod() + " " + request.getRequestURI() + "] → " + ex.getClass().getSimpleName() + ": " + ex.getMessage());
        // Only dump full stack trace in dev profile to keep production logs clean
        if (isDevMode()) {
            ex.printStackTrace();
        }
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred. Please try again.", request, null);
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────────

    private ResponseEntity<ApiError> build(HttpStatus status, String message, HttpServletRequest request, Map<String, String> fieldErrors) {
        ApiError body = new ApiError(
                System.currentTimeMillis(),
                status.value(),
                status.getReasonPhrase(),
                message,
                request.getRequestURI(),
                fieldErrors);
        return ResponseEntity.status(status).body(body);
    }

    /** Clean, single-line logging like Node/Express: no ugly stack traces spamming the terminal. */
    private void log(String message) {
        System.out.println("[API] " + message);
    }

    private boolean isDevMode() {
        String profile = System.getProperty("spring.profiles.active", "");
        return profile.contains("dev");
    }
}
