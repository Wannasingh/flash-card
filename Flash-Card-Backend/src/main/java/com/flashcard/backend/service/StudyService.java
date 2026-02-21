package com.flashcard.backend.service;

import com.flashcard.backend.entity.Card;
import com.flashcard.backend.entity.StudyProgress;
import com.flashcard.backend.entity.StudyProgressId;
import com.flashcard.backend.exception.ResourceNotFoundException;
import com.flashcard.backend.payload.response.CardResponse;
import com.flashcard.backend.payload.response.StudyStatsResponse;
import com.flashcard.backend.repository.CardRepository;
import com.flashcard.backend.repository.StudyProgressRepository;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.user.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
@SuppressWarnings("null")
public class StudyService {

    @Autowired
    private StudyProgressRepository studyProgressRepository;

    @Autowired
    private CardRepository cardRepository;

    @Autowired
    private UserRepository userRepository;

    public List<CardResponse> getDueCards(Long userId) {
        List<StudyProgress> dueProgresses = studyProgressRepository.findDueCards(userId, Instant.now());
        
        return dueProgresses.stream()
                .map(p -> mapCardToResponse(p.getCard()))
                .collect(Collectors.toList());
    }

    @Transactional
    public void reviewCard(Long userId, Long cardId, Integer quality) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new ResourceNotFoundException("Card not found"));

        StudyProgressId progressId = new StudyProgressId(userId, cardId);
        StudyProgress progress = studyProgressRepository.findById(progressId)
                .orElse(new StudyProgress(userId, cardId, user, card, 2.5f, 0, 0, Instant.now(), null));

        // SM-2 Algorithm Implementation
        if (quality >= 3) {
            // Correct response
            if (progress.getRepetitions() == 0) {
                progress.setIntervalDays(1);
            } else if (progress.getRepetitions() == 1) {
                progress.setIntervalDays(6);
            } else {
                progress.setIntervalDays(Math.round(progress.getIntervalDays() * progress.getEasinessFactor()));
            }
            progress.setRepetitions(progress.getRepetitions() + 1);
        } else {
            // Incorrect response
            progress.setRepetitions(0);
            progress.setIntervalDays(1);
        }

        // Calculate new Easiness Factor (EF)
        float newEF = progress.getEasinessFactor() + (0.1f - (5 - quality) * (0.08f + (5 - quality) * 0.02f));
        if (newEF < 1.3f) newEF = 1.3f; // Minimum EF limit
        progress.setEasinessFactor(newEF);

        // Calculate next review date
        Instant nextReview = Instant.now().plus(progress.getIntervalDays(), ChronoUnit.DAYS);
        progress.setNextReviewAt(nextReview);
        progress.setLastReviewedAt(Instant.now());

        studyProgressRepository.save(progress);

        // Update Gamification stats (Streak and Coins)
        updateGamificationStats(user);
    }

    public StudyStatsResponse getStudyStats(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        long totalStudied = studyProgressRepository.countByUserId(userId);
        long dueToday = studyProgressRepository.findDueCards(userId, Instant.now()).size();

        return StudyStatsResponse.builder()
                .coins(user.getCoins())
                .streakDays(user.getStreakDays())
                .totalCardsStudied(totalStudied)
                .cardsDueToday(dueToday)
                .totalXP(user.getTotalXP())
                .weeklyXP(user.getWeeklyXP())
                .build();
    }

    private void updateGamificationStats(User user) {
        LocalDate today = LocalDate.now(ZoneId.systemDefault());
        
        if (user.getLastStudyDate() == null) {
            // First time studying
            user.setStreakDays(1);
            user.setCoins(user.getCoins() + 10); // Reward for starting
        } else if (user.getLastStudyDate().equals(today.minusDays(1))) {
            // Studied yesterday, increment streak
            user.setStreakDays(user.getStreakDays() + 1);
            user.setCoins(user.getCoins() + 5); // Daily streak reward
        } else if (user.getLastStudyDate().isBefore(today.minusDays(1))) {
            // Streak broken
            user.setStreakDays(1); // Reset streak
            user.setCoins(user.getCoins() + 1); // Small reward for returning
        }
        
        user.setLastStudyDate(today);
        userRepository.save(user);
    }

    private CardResponse mapCardToResponse(Card card) {
        return CardResponse.builder()
                .id(card.getId())
                .deckId(card.getDeck().getId())
                .frontText(card.getFrontText())
                .backText(card.getBackText())
                .imageUrl(card.getImageUrl())
                .videoUrl(card.getVideoUrl())
                .arModelUrl(card.getArModelUrl())
                .memeUrl(card.getMemeUrl())
                .aiMnemonic(card.getAiMnemonic())
                .createdAt(card.getCreatedAt())
                .updatedAt(card.getUpdatedAt())
                .build();
    }
}
