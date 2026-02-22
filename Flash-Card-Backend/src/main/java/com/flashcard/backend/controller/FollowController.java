package com.flashcard.backend.controller;

import com.flashcard.backend.payload.response.MessageResponse;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.service.FollowService;
import com.flashcard.backend.service.UserDetailsImpl;
import com.flashcard.backend.user.User;
import io.swagger.v3.oas.annotations.Operation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class FollowController {

    @Autowired
    private FollowService followService;

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/follow/{id}")
    @Operation(summary = "Follow a user")
    public ResponseEntity<?> followUser(@AuthenticationPrincipal UserDetailsImpl userDetails, @PathVariable Long id) {
        User follower = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("User not found"));
        try {
            followService.follow(follower, id);
            return ResponseEntity.ok(new MessageResponse("Followed successfully"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    @DeleteMapping("/unfollow/{id}")
    @Operation(summary = "Unfollow a user")
    public ResponseEntity<?> unfollowUser(@AuthenticationPrincipal UserDetailsImpl userDetails, @PathVariable Long id) {
        User follower = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("User not found"));
        try {
            followService.unfollow(follower, id);
            return ResponseEntity.ok(new MessageResponse("Unfollowed successfully"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }
}
