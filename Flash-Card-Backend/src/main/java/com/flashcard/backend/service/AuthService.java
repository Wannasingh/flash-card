package com.flashcard.backend.service;

import com.flashcard.backend.payload.request.LoginRequest;
import com.flashcard.backend.payload.request.SignupRequest;
import com.flashcard.backend.payload.response.JwtResponse;
import com.flashcard.backend.payload.response.MessageResponse;
import com.flashcard.backend.repository.RoleRepository;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.security.jwt.JwtUtils;
import com.flashcard.backend.user.Role;
import com.flashcard.backend.user.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Locale;
import java.util.HashSet;
import java.util.List;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@SuppressWarnings("null")
public class AuthService {

        @Autowired
        AuthenticationManager authenticationManager;

        @Autowired
        UserRepository userRepository;

        @Autowired
        RoleRepository roleRepository;

        @Autowired
        PasswordEncoder encoder;

        @Autowired
        JwtUtils jwtUtils;

        @Autowired
        RefreshTokenService refreshTokenService;

        @Autowired
        SupabaseStorageService storageService;

        public ResponseEntity<?> authenticateUser(LoginRequest loginRequest, HttpServletRequest request) {
                String username = loginRequest.getUsername() == null ? null : loginRequest.getUsername().trim();
                Authentication authentication = authenticationManager.authenticate(
                                new UsernamePasswordAuthenticationToken(username, loginRequest.getPassword()));

                SecurityContextHolder.getContext().setAuthentication(authentication);
                String jwt = jwtUtils.generateJwtToken(authentication);

                UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
                List<String> roles = userDetails.getAuthorities().stream()
                                .map(item -> item.getAuthority())
                                .collect(Collectors.toList());

                String imageUrl = userDetails.getImageUrl();
                if (imageUrl != null && !imageUrl.isEmpty() && !imageUrl.startsWith("http")) {
                    if (request != null) {
                        String baseUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort();
                        imageUrl = baseUrl + "/api/user/profile/" + userDetails.getId() + "/image";
                    } else {
                        try {
                            imageUrl = storageService.getSignedUrl(imageUrl);
                        } catch (Exception e) {
                            System.err.println("Error signing URL in AuthService: " + e.getMessage());
                        }
                    }
                }

                // Generate refresh token
                User user = userRepository.findById(userDetails.getId())
                                .orElseThrow(() -> new RuntimeException("User not found"));
                String refreshTokenString = refreshTokenService.createRefreshToken(user).getToken();

                ResponseCookie jwtCookie = jwtUtils.generateJwtCookie(jwt);

                return ResponseEntity.ok()
                                .header(HttpHeaders.SET_COOKIE, jwtCookie.toString())
                                .body(new JwtResponse(jwt, refreshTokenString,
                                                userDetails.getId(),
                                                userDetails.getUsername(),
                                                userDetails.getEmail(),
                                                userDetails.getDisplayName(),
                                                imageUrl,
                                                roles, 0L, 0L, null, null, null));
        }

        public ResponseEntity<?> registerUser(SignupRequest signupRequest) {
                String username = signupRequest.getUsername() == null ? null : signupRequest.getUsername().trim();
                String email = signupRequest.getEmail() == null ? null
                                : signupRequest.getEmail().trim().toLowerCase(Locale.ROOT);

                if (userRepository.existsByUsername(username)) {
                        return ResponseEntity
                                        .badRequest()
                                        .body(new MessageResponse("Error: User already exists!"));
                }

                if (userRepository.existsByEmail(email)) {
                        return ResponseEntity
                                        .badRequest()
                                        .body(new MessageResponse("Error: User already exists!"));
                }

                // Create new user's account
                User user = new User(username,
                                email,
                                encoder.encode(signupRequest.getPassword()));

                Set<Role> roles = new HashSet<>();
                Role userRole = roleRepository.findByName("ROLE_USER")
                                .orElseThrow(() -> new RuntimeException("Error: Role is not found."));
                roles.add(userRole);

                user.setRoles(roles);
                userRepository.save(user);

                return ResponseEntity.ok(new MessageResponse("User registered successfully!"));
        }
}
