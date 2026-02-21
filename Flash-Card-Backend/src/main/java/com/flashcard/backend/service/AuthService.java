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
import java.util.Set;
import java.util.stream.Collectors;

@Service
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
        SupabaseStorageService storageService;

        public ResponseEntity<?> authenticateUser(LoginRequest loginRequest) {
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
                try {
                    imageUrl = storageService.getSignedUrl(imageUrl);
                } catch (Exception e) {
                    System.err.println("Error signing URL in AuthService: " + e.getMessage());
                }

                ResponseCookie jwtCookie = jwtUtils.generateJwtCookie(jwt);

                return ResponseEntity.ok()
                                .header(HttpHeaders.SET_COOKIE, jwtCookie.toString())
                                .body(new JwtResponse(jwt,
                                                userDetails.getId(),
                                                userDetails.getUsername(),
                                                userDetails.getEmail(),
                                                userDetails.getDisplayName(),
                                                imageUrl,
                                                roles));
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
