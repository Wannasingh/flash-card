package com.flashcard.backend.service;

import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.user.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@SuppressWarnings("null")
public class XPService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BadgeService badgeService;

    private static final int XP_PER_REVIEW = 10;
    private static final int XP_BONUS_PER_STREAK_DAY = 2;

    @Transactional
    public void grantXPForReview(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        int baseXP = XP_PER_REVIEW;
        int streakBonus = user.getStreakDays() * XP_BONUS_PER_STREAK_DAY;
        int totalEarned = baseXP + streakBonus;

        user.setTotalXP(user.getTotalXP() + totalEarned);
        user.setWeeklyXP(user.getWeeklyXP() + totalEarned);
        
        userRepository.save(user);

        // Award Badges
        badgeService.awardBadgeIfEligible(user, "FIRST_SWIPE");
        if (user.getTotalXP() >= 1000) {
            badgeService.awardBadgeIfEligible(user, "XP_1000");
        }
    }
}
