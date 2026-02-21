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

        // Clean path: remove bucket name if it's already included in fullPath
        // Because the API expects /object/sign/{bucket}/{path}
        String objectPath = fullPath;
        if (fullPath.startsWith(bucketName + "/")) {
            objectPath = fullPath.substring(bucketName.length() + 1);
        }

        String baseUrl = getBaseUrl();
        // Correct API endpoint: /storage/v1/object/sign/{bucket}/{wildcard}
        String signUrl = baseUrl + "/storage/v1/object/sign/" + bucketName + "/" + objectPath;
        
        // JSON payload for expiry
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
            
            // Supabase returns: { "signedURL": "/object/sign/..." } or full URL
            String signedPath = node.get("signedURL").asText();
            
            // Handle relative path response (common in local Supabase)
            if (signedPath.startsWith("/")) {
                // Remove /storage/v1 prefix if it exists in signedPath to avoid duplication when appending to baseUrl
                // But typically local supabase returns /object/sign/... which needs /storage/v1 prefix from baseUrl
                
                // Construct the full URL carefully
                // If baseUrl already ends with /storage/v1, don't duplicate
                // But our getBaseUrl() returns root (e.g. http://localhost:8000)
                
                // Case 1: signedPath starts with /storage/v1 -> just append to host
                if (signedPath.startsWith("/storage/v1")) {
                     return baseUrl + signedPath;
                }
                
                // Case 2: signedPath starts with /object/ -> needs /storage/v1 prefix
                if (signedPath.startsWith("/object/")) {
                    return baseUrl + "/storage/v1" + signedPath;
                }
                
                // Fallback: just append
                return baseUrl + signedPath;
            }
            
            // If it's already a full URL
            return signedPath;
        } catch (Exception e) {
            System.err.println("Error parsing signed URL: " + e.getMessage());
            return null;
        }
    }

    public byte[] downloadImage(String storedPath) throws IOException, InterruptedException {
        String signedUrl = getSignedUrl(storedPath);
        if (signedUrl == null) {
            System.err.println("Failed to get signed URL for: " + storedPath);
            return null;
        }

        System.out.println("Downloading from signed URL: " + signedUrl);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(signedUrl))
                .timeout(Duration.ofSeconds(15))
                .GET()
                .build();

        HttpResponse<byte[]> response = httpClient.send(request, HttpResponse.BodyHandlers.ofByteArray());
        if (response.statusCode() != 200) {
            String errResponse = new String(response.body());
            System.err.println("Failed to download image from signed URL. Status: " + response.statusCode() + " Response: " + errResponse);
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
