package com.flashcard.backend.exception;

import java.util.Map;

public record ApiError(
                long timestampEpochMs,
                int status,
                String error,
                String message,
                String path,
                Map<String, String> fieldErrors) {
}
