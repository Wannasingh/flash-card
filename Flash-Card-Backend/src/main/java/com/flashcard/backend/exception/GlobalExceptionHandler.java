package com.flashcard.backend.exception;

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

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex, HttpServletRequest request) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        for (FieldError fe : ex.getBindingResult().getFieldErrors()) {
            if (!fieldErrors.containsKey(fe.getField())) {
                fieldErrors.put(fe.getField(), fe.getDefaultMessage());
            }
        }

        return build(HttpStatus.BAD_REQUEST, "Validation failed", request, fieldErrors);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiError> handleDataIntegrity(DataIntegrityViolationException ex,
            HttpServletRequest request) {
        return build(HttpStatus.CONFLICT, "Data conflict", request, null);
    }

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ApiError> handleBadCredentials(BadCredentialsException ex, HttpServletRequest request) {
        return build(HttpStatus.UNAUTHORIZED, "Invalid credentials", request, null);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiError> handleAccessDenied(AccessDeniedException ex, HttpServletRequest request) {
        return build(HttpStatus.FORBIDDEN, "Forbidden", request, null);
    }

    @ExceptionHandler({ IllegalStateException.class, IllegalArgumentException.class })
    public ResponseEntity<ApiError> handleBadRequest(RuntimeException ex, HttpServletRequest request) {
        return build(HttpStatus.BAD_REQUEST, "Bad request", request, null);
    }

    @ExceptionHandler(ParseException.class)
    public ResponseEntity<ApiError> handleJwtParse(ParseException ex, HttpServletRequest request) {
        return build(HttpStatus.UNAUTHORIZED, "Invalid token", request, null);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleGeneric(Exception ex, HttpServletRequest request) {
        ex.printStackTrace(); // Print stack trace for debugging
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "Internal server error", request, null);
    }

    private ResponseEntity<ApiError> build(HttpStatus status, String message, HttpServletRequest request,
            Map<String, String> fieldErrors) {
        ApiError body = new ApiError(
                System.currentTimeMillis(),
                status.value(),
                status.getReasonPhrase(),
                message,
                request.getRequestURI(),
                fieldErrors);
        return ResponseEntity.status(status).body(body);
    }
}
