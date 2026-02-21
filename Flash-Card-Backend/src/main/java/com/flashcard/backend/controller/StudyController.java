package com.flashcard.backend.controller;

import com.flashcard.backend.payload.request.ReviewRequest;
import com.flashcard.backend.payload.response.CardResponse;
import com.flashcard.backend.payload.response.MessageResponse;
import com.flashcard.backend.payload.response.StudyStatsResponse;
import com.flashcard.backend.service.StudyService;
import com.flashcard.backend.service.UserDetailsImpl;
import com.flashcard.backend.service.XPService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/study")
@Tag(name = "Study Session", description = "Spaced Repetition System (SRS) and Gamification APIs")
public class StudyController {

    @Autowired
    private StudyService studyService;

    @Autowired
    private XPService xpService;

    @Operation(summary = "Get cards that are due for review today")
    @GetMapping("/due-cards")
    public ResponseEntity<List<CardResponse>> getDueCards(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        List<CardResponse> dueCards = studyService.getDueCards(userDetails.getId());
        return ResponseEntity.ok(dueCards);
    }

    @Operation(summary = "Submit a review score for a single card (0-5 quality)")
    @PostMapping("/{cardId}/review")
    public ResponseEntity<MessageResponse> reviewCard(@PathVariable Long cardId,
                                                      @Valid @RequestBody ReviewRequest request,
                                                      @AuthenticationPrincipal UserDetailsImpl userDetails) {
        studyService.reviewCard(userDetails.getId(), cardId, request.getQuality());
        xpService.grantXPForReview(userDetails.getId());
        return ResponseEntity.ok(new MessageResponse("Review processed. Gamification updated."));
    }

    @Operation(summary = "Get user's study gamification statistics (Coins, Streaks)")
    @GetMapping("/stats")
    public ResponseEntity<StudyStatsResponse> getStudyStats(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        StudyStatsResponse stats = studyService.getStudyStats(userDetails.getId());
        return ResponseEntity.ok(stats);
    }
}
