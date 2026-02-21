package com.flashcard.backend.controller;

import com.flashcard.backend.payload.response.LeaderboardEntry;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.user.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import jakarta.servlet.http.HttpServletRequest;

import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/leaderboard")
public class LeaderboardController {

    @Autowired
    private UserRepository userRepository;

    private String getProxiedImageUrl(User user, String baseUrl) {
        String url = user.getImageUrl();
        if (url != null && !url.isEmpty() && !url.startsWith("http")) {
            return baseUrl + "/api/user/profile/" + user.getId() + "/image";
        }
        return url;
    }

    @GetMapping("/global")
    public List<LeaderboardEntry> getGlobalLeaderboard(HttpServletRequest request) {
        String baseUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort();
        List<User> topUsers = userRepository.findTop50ByOrderByWeeklyXPDesc();
        AtomicInteger rank = new AtomicInteger(1);
        
        return topUsers.stream()
                .map(user -> new LeaderboardEntry(
                        user.getId(),
                        user.getUsername(),
                        user.getDisplayName(),
                        getProxiedImageUrl(user, baseUrl),
                        user.getWeeklyXP().doubleValue(),
                        rank.getAndIncrement(),
                        user.getStreakDays()
                ))
                .collect(Collectors.toList());
    }
    
    @GetMapping("/all-time")
    public List<LeaderboardEntry> getAllTimeLeaderboard(HttpServletRequest request) {
        String baseUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort();
        List<User> topUsers = userRepository.findTop50ByOrderByTotalXPDesc();
        AtomicInteger rank = new AtomicInteger(1);
        
        return topUsers.stream()
                .map(user -> new LeaderboardEntry(
                        user.getId(),
                        user.getUsername(),
                        user.getDisplayName(),
                        getProxiedImageUrl(user, baseUrl),
                        user.getTotalXP().doubleValue(),
                        rank.getAndIncrement(),
                        user.getStreakDays()
                ))
                .collect(Collectors.toList());
    }
}
