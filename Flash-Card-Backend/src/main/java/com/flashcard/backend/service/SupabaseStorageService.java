package com.flashcard.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.UUID;

@Service
public class SupabaseStorageService {

    @Value("${flashcard.supabase.url:}")
    private String supabaseUrl;

    @Value("${flashcard.supabase.key:}")
    private String supabaseKey;

    @Value("${flashcard.supabase.bucket:flashcard.profile.picture}")
    private String bucketName;

    // Use HTTP/1.1 to avoid HTTP/2 connection pooling EOFException
    private final HttpClient httpClient = HttpClient.newBuilder()
            .version(HttpClient.Version.HTTP_1_1)
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    @PostConstruct
    public void init() {
        if (supabaseUrl == null || supabaseUrl.isEmpty()) {
            System.err.println("WARNING: flashcard.supabase.url is not configured!");
        } else {
            System.out.println("SupabaseStorageService initialized with URL: " + supabaseUrl);
        }
        if (supabaseKey == null || supabaseKey.isEmpty()) {
            System.err.println("WARNING: flashcard.supabase.key is not configured!");
        }
    }

    private String getBaseUrl() {
        String baseUrl = supabaseUrl;
        if (baseUrl == null || baseUrl.isEmpty()) {
            throw new IllegalStateException("flashcard.supabase.url is not configured. Set it in .env");
        }
        if (!baseUrl.startsWith("http")) {
            baseUrl = "http://" + baseUrl;
        }
        if (baseUrl.endsWith("/")) {
            baseUrl = baseUrl.substring(0, baseUrl.length() - 1);
        }
        return baseUrl;
    }

    /**
     * Upload a profile picture.
     * Uses UUID-based folder for uniqueness.
     */
    public String uploadProfilePicture(Long userId, byte[] imageData, String contentType) throws IOException, InterruptedException {
        String folderName = UUID.nameUUIDFromBytes(("user-" + userId).getBytes()).toString();
        String fileName = folderName + "/" + UUID.randomUUID() + getExtension(contentType);

        String baseUrl = getBaseUrl();
        String uploadUrl = baseUrl + "/storage/v1/object/" + bucketName + "/" + fileName;
        System.out.println("Uploading to Supabase: " + uploadUrl + " (Size: " + imageData.length + " bytes, Type: " + contentType + ")");

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(uploadUrl))
                .header("Authorization", "Bearer " + supabaseKey)
                .header("apikey", supabaseKey)
                .header("Content-Type", contentType)
                .POST(HttpRequest.BodyPublishers.ofByteArray(imageData))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            System.err.println("Supabase upload error: " + response.statusCode() + " — " + response.body());
            throw new IOException("Supabase returned error " + response.statusCode() + ": " + response.body());
        }

        System.out.println("Upload successful: " + fileName);
        return bucketName + "/" + fileName;
    }

    /**
     * Delete an old profile picture from Supabase storage.
     */
    public void deleteOldImage(String storedPath) {
        if (storedPath == null || storedPath.startsWith("http") || storedPath.isEmpty()) {
            return;
        }

        try {
            String objectPath = storedPath;
            if (storedPath.startsWith(bucketName + "/")) {
                objectPath = storedPath.substring(bucketName.length() + 1);
            }

            String baseUrl = getBaseUrl();
            String deleteUrl = baseUrl + "/storage/v1/object/" + bucketName + "/" + objectPath;

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(deleteUrl))
                    .header("Authorization", "Bearer " + supabaseKey)
                    .header("apikey", supabaseKey)
                    .DELETE()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                System.err.println("Failed to delete old image (non-critical): " + response.statusCode());
            }
        } catch (Exception e) {
            System.err.println("Error deleting old image (non-critical): " + e.getMessage());
        }
    }

    /**
     * Generate a signed URL for a stored image path.
     * Uses 24-hour expiry.
     */
    public String getSignedUrl(String fullPath) throws IOException, InterruptedException {
        if (fullPath == null || fullPath.startsWith("http")) {
            return fullPath;
        }

        String baseUrl = getBaseUrl();
        String signUrl = baseUrl + "/storage/v1/object/sign/" + fullPath;
        String jsonPayload = "{\"expiresIn\": 86400}";

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(signUrl))
                .header("Authorization", "Bearer " + supabaseKey)
                .header("apikey", supabaseKey)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(jsonPayload))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            System.err.println("Signed URL error: " + response.statusCode() + " — " + response.body());
            return null;
        }

        try {
            com.fasterxml.jackson.databind.JsonNode node =
                    new com.fasterxml.jackson.databind.ObjectMapper().readTree(response.body());
            String signedPath = node.get("signedURL").asText();
            if (signedPath.startsWith("/object/")) {
                return baseUrl + "/storage/v1" + signedPath;
            }
            return baseUrl + signedPath;
        } catch (Exception e) {
            System.err.println("Error parsing signed URL: " + e.getMessage());
            return null;
        }
    }

    /**
     * Download image bytes from Supabase storage.
     * Used by the backend proxy to serve images to iOS clients.
     */
    public byte[] downloadImage(String storedPath) throws IOException, InterruptedException {
        String signedUrl = getSignedUrl(storedPath);
        if (signedUrl == null) {
            return null;
        }

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(signedUrl))
                .timeout(Duration.ofSeconds(15))
                .GET()
                .build();

        HttpResponse<byte[]> response = httpClient.send(request, HttpResponse.BodyHandlers.ofByteArray());
        if (response.statusCode() != 200) {
            System.err.println("Failed to download image: " + response.statusCode());
            return null;
        }
        return response.body();
    }

    private String getExtension(String contentType) {
        if (contentType == null) return ".png";
        return switch (contentType) {
            case "image/jpeg" -> ".jpg";
            case "image/webp" -> ".webp";
            default -> ".png";
        };
    }
}
