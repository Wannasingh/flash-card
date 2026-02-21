package com.flashcard.backend.controller;

import com.flashcard.backend.payload.response.JwtResponse;
import com.flashcard.backend.service.UserDetailsImpl;
import com.flashcard.backend.payload.request.ProfileUpdateRequest;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.service.SupabaseStorageService;
import com.flashcard.backend.user.User;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.lang.NonNull;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/user")
public class UserController {
    @Autowired
    UserRepository userRepository;

    @Autowired
    SupabaseStorageService storageService;

    @Autowired
    com.flashcard.backend.service.BadgeService badgeService;

    @GetMapping("/profile/{id}")
    @Operation(summary = "Get public profile by ID")
    public ResponseEntity<com.flashcard.backend.payload.response.PublicProfileResponse> getPublicProfile(@PathVariable Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));

        com.flashcard.backend.payload.response.PublicProfileResponse response = com.flashcard.backend.payload.response.PublicProfileResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .displayName(user.getDisplayName())
                .imageUrl(user.getImageUrl())
                .totalXP(user.getTotalXP())
                .weeklyXP(user.getWeeklyXP())
                .streakDays(user.getStreakDays())
                .badges(badgeService.getUserBadges(user))
                .activeAuraCode(user.getActiveAuraCode())
                .activeSkinCode(user.getActiveSkinCode())
                .build();
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public JwtResponse getUserProfile(@AuthenticationPrincipal UserDetailsImpl userDetails,
                                      @NonNull HttpServletRequest request) {
        if (userDetails == null) {
            throw new RuntimeException("User not authenticated");
        }

        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<String> roles = userDetails.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toList());

        return createJwtResponse(user, roles, request);
    }

    @Operation(summary = "View profile image (proxy)")
    @GetMapping("/profile/image/view")
    public ResponseEntity<byte[]> viewProfileImage(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        if (userDetails == null) {
            return ResponseEntity.status(401).build();
        }

        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("User not found"));

        String storedPath = user.getImageUrl();
        if (storedPath == null || storedPath.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        // If it's an external URL (Google/Apple), redirect to it
        if (storedPath.startsWith("http")) {
            return ResponseEntity.status(302)
                    .header(HttpHeaders.LOCATION, storedPath)
                    .build();
        }

        try {
            byte[] imageData = storageService.downloadImage(storedPath);
            if (imageData == null || imageData.length == 0) {
                return ResponseEntity.notFound().build();
            }

            String contentType = storedPath.endsWith(".jpg") || storedPath.endsWith(".jpeg")
                    ? "image/jpeg"
                    : storedPath.endsWith(".webp") ? "image/webp" : "image/png";

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CACHE_CONTROL, "public, max-age=3600")
                    .body(imageData);
        } catch (Exception e) {
            System.err.println("Error proxying image: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @PutMapping("/profile")
    public JwtResponse updateProfile(@AuthenticationPrincipal UserDetailsImpl userDetails,
                                     @Valid @RequestBody ProfileUpdateRequest request) {
        if (userDetails == null) {
            throw new RuntimeException("User not authenticated");
        }

        Long userId = userDetails.getId();
        if (userId == null) {
            throw new RuntimeException("User ID not found in session");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (request.getDisplayName() != null) {
            user.setDisplayName(request.getDisplayName());
        }
        
        // If image URL is updated manually, set source to MANUAL
        if (request.getImageUrl() != null) {
            user.setImageUrl(request.getImageUrl());
            user.setImageSource("MANUAL");
            user.setImageUpdatedAt(Instant.now());
        }

        userRepository.save(user);

        List<String> roles = userDetails.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toList());

        return createJwtResponse(user, roles);
    }

    @Operation(summary = "Upload profile image")
    @PostMapping(value = "/profile/image", consumes = "multipart/form-data")
    public JwtResponse uploadProfileImage(@AuthenticationPrincipal UserDetailsImpl userDetails,
                                          @RequestPart("file") MultipartFile file) throws IOException, InterruptedException {
        if (userDetails == null) {
            throw new RuntimeException("User not authenticated");
        }

        Long userId = userDetails.getId();
        if (userId == null) {
            throw new RuntimeException("User ID not found in session");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        byte[] imageData = file.getBytes();
        String contentType = file.getContentType();
        System.out.println("Received file upload: name=" + file.getOriginalFilename() + ", size=" + file.getSize() + ", contentType=" + contentType);

        // Reject empty files
        if (imageData.length == 0) {
            throw new RuntimeException("File is empty. Please select a valid image file.");
        }

        // Sniff actual MIME type from magic bytes if declared type is not an image
        if (contentType == null || !contentType.startsWith("image/")) {
            contentType = sniffImageType(imageData);
            System.out.println("Sniffed content type from magic bytes: " + contentType);
            if (contentType == null) {
                throw new RuntimeException("Invalid file type. Only PNG, JPEG, and WebP images are allowed.");
            }
        }

        try {
            // Delete old image if exists (non-critical, won't block upload)
            String oldImageUrl = user.getImageUrl();
            if (oldImageUrl != null && !oldImageUrl.isEmpty()) {
                storageService.deleteOldImage(oldImageUrl);
            }

            String imageUrl = storageService.uploadProfilePicture(user.getId(), imageData, contentType);
            
            user.setImageUrl(imageUrl);
            user.setImageSource("MANUAL");
            user.setImageUpdatedAt(Instant.now());
            userRepository.save(user);
        } catch (Exception e) {
            System.err.println("Upload failed: " + e.getMessage());
            throw e;
        }

        List<String> roles = userDetails.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toList());

        return createJwtResponse(user, roles);
    }

    private JwtResponse createJwtResponse(User user, List<String> roles) {
        return createJwtResponse(user, roles, null);
    }

    private JwtResponse createJwtResponse(@NonNull User user, @NonNull List<String> roles, HttpServletRequest request) {
        String imageUrl = user.getImageUrl();

        if (imageUrl != null && !imageUrl.isEmpty() && !imageUrl.startsWith("http")) {
            // Return backend-proxied URL so iOS app bypasses ATS
            if (request != null) {
                String baseUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort();
                imageUrl = baseUrl + "/api/user/profile/image/view";
            } else {
                // Fallback: try signed URL
                try {
                    imageUrl = storageService.getSignedUrl(imageUrl);
                } catch (Exception e) {
                    System.err.println("Error signing URL: " + e.getMessage());
                }
            }
        }

        return new JwtResponse(
                null,
                user.getId(),
                user.getUsername(),
                user.getEmail(),
                user.getDisplayName(),
                imageUrl,
                roles,
                user.getTotalXP(),
                user.getWeeklyXP(),
                badgeService.getUserBadges(user),
                user.getActiveAuraCode(),
                user.getActiveSkinCode()
        );
    }

    /**
     * Detect image MIME type from magic bytes.
     * Returns null if the bytes don't match a known image type.
     */
    private String sniffImageType(byte[] data) {
        if (data.length < 4) return null;

        // PNG: starts with 0x89 'P' 'N' 'G'
        if (data[0] == (byte) 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47) {
            return "image/png";
        }
        // JPEG: starts with 0xFF 0xD8 0xFF
        if (data[0] == (byte) 0xFF && data[1] == (byte) 0xD8 && data[2] == (byte) 0xFF) {
            return "image/jpeg";
        }
        // WebP: starts with 'RIFF' ... 'WEBP'
        if (data.length >= 12 && data[0] == 'R' && data[1] == 'I' && data[2] == 'F' && data[3] == 'F'
                && data[8] == 'W' && data[9] == 'E' && data[10] == 'B' && data[11] == 'P') {
            return "image/webp";
        }
        return null;
    }

    /** Schema class for OpenAPI file upload documentation (used by Scalar UI) */
    public static class FileUploadForm {
        @Schema(type = "string", format = "binary", description = "The image file to upload (PNG, JPEG, or WebP)")
        public MultipartFile file;
    }
}
