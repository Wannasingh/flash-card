package com.flashcard.backend.service;

import com.flashcard.backend.repository.BadgeRepository;
import com.flashcard.backend.repository.UserBadgeRepository;
import com.flashcard.backend.user.Badge;
import com.flashcard.backend.user.User;
import com.flashcard.backend.user.UserBadge;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class BadgeService {

    @Autowired
    private BadgeRepository badgeRepository;

    @Autowired
    private UserBadgeRepository userBadgeRepository;

    @Transactional
    public void awardBadgeIfEligible(User user, String badgeCode) {
        if (userBadgeRepository.existsByUserAndBadge_Code(user, badgeCode)) {
            return; // Already earned
        }

        badgeRepository.findByCode(badgeCode).ifPresent(badge -> {
            UserBadge userBadge = UserBadge.builder()
                    .user(user)
                    .badge(badge)
                    .build();
            userBadgeRepository.save(userBadge);
        });
    }

    public List<Badge> getUserBadges(User user) {
        return userBadgeRepository.findByUser(user).stream()
                .map(UserBadge::getBadge)
                .collect(Collectors.toList());
    }
}
