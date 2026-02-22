package com.flashcard.backend.controller;

import com.flashcard.backend.payload.response.LeaderboardEntry;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.user.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import jakarta.servlet.http.HttpServletRequest;

import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/leaderboard")
public class LeaderboardController {

    @Autowired
    private com.flashcard.backend.service.FollowService followService;

    @Autowired
    private UserRepository userRepository;

    private String getProxiedImageUrl(User user, String baseUrl) {
        String url = user.getImageUrl();
        if (url != null && !url.isEmpty() && !url.startsWith("http")) {
            return baseUrl + "/api/user/profile/" + user.getId() + "/image";
        }
        return url;
    }

    private LeaderboardEntry mapToEntry(User user, String baseUrl, AtomicInteger rank, boolean useWeekly) {
        return new LeaderboardEntry(
                user.getId(),
                user.getUsername(),
                user.getDisplayName(),
                getProxiedImageUrl(user, baseUrl),
                useWeekly ? user.getWeeklyXP().doubleValue() : user.getTotalXP().doubleValue(),
                rank.getAndIncrement(),
                user.getStreakDays(),
                user.getActiveAuraCode()
        );
    }

    @GetMapping("/global")
    public List<LeaderboardEntry> getGlobalLeaderboard(
            @RequestParam(required = false) String country,
            @RequestParam(required = false) String region,
            HttpServletRequest request) {
        String baseUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort();
        
        List<User> topUsers;
        if (country != null && !country.isEmpty()) {
            topUsers = userRepository.findTop50ByCountryOrderByWeeklyXPDesc(country);
        } else if (region != null && !region.isEmpty()) {
            topUsers = userRepository.findTop50ByRegionOrderByWeeklyXPDesc(region);
        } else {
            topUsers = userRepository.findTop50ByOrderByWeeklyXPDesc();
        }

        AtomicInteger rank = new AtomicInteger(1);
        return topUsers.stream()
                .map(user -> mapToEntry(user, baseUrl, rank, true))
                .collect(Collectors.toList());
    }
    
    @GetMapping("/all-time")
    public List<LeaderboardEntry> getAllTimeLeaderboard(
            @RequestParam(required = false) String country,
            @RequestParam(required = false) String region,
            HttpServletRequest request) {
        String baseUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort();
        
        List<User> topUsers;
        if (country != null && !country.isEmpty()) {
            topUsers = userRepository.findTop50ByCountryOrderByTotalXPDesc(country);
        } else if (region != null && !region.isEmpty()) {
            topUsers = userRepository.findTop50ByRegionOrderByTotalXPDesc(region);
        } else {
            topUsers = userRepository.findTop50ByOrderByTotalXPDesc();
        }

        AtomicInteger rank = new AtomicInteger(1);
        return topUsers.stream()
                .map(user -> mapToEntry(user, baseUrl, rank, false))
                .collect(Collectors.toList());
    }

    @GetMapping("/friends")
    public List<LeaderboardEntry> getFriendsLeaderboard(
            @org.springframework.security.core.annotation.AuthenticationPrincipal com.flashcard.backend.service.UserDetailsImpl userDetails,
            HttpServletRequest request) {
        String baseUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort();
        User currentUser = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        List<User> following = followService.getFollowing(currentUser);
        // Include self
        following.add(currentUser);
        
        // Sort by weekly XP
        following.sort((u1, u2) -> u2.getWeeklyXP().compareTo(u1.getWeeklyXP()));

        AtomicInteger rank = new AtomicInteger(1);
        return following.stream()
                .map(user -> mapToEntry(user, baseUrl, rank, true))
                .collect(Collectors.toList());
    }
}
