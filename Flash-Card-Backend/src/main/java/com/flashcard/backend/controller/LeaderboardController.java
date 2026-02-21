package com.flashcard.backend.controller;

import com.flashcard.backend.payload.response.LeaderboardEntry;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.user.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/leaderboard")
public class LeaderboardController {

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/global")
    public List<LeaderboardEntry> getGlobalLeaderboard() {
        List<User> topUsers = userRepository.findTop50ByOrderByWeeklyXPDesc();
        AtomicInteger rank = new AtomicInteger(1);
        
        return topUsers.stream()
                .map(user -> new LeaderboardEntry(
                        user.getId(),
                        user.getUsername(),
                        user.getDisplayName(),
                        user.getImageUrl(),
                        user.getWeeklyXP().doubleValue(),
                        rank.getAndIncrement(),
                        user.getStreakDays()
                ))
                .collect(Collectors.toList());
    }
    
    @GetMapping("/all-time")
    public List<LeaderboardEntry> getAllTimeLeaderboard() {
        List<User> topUsers = userRepository.findTop50ByOrderByTotalXPDesc();
        AtomicInteger rank = new AtomicInteger(1);
        
        return topUsers.stream()
                .map(user -> new LeaderboardEntry(
                        user.getId(),
                        user.getUsername(),
                        user.getDisplayName(),
                        user.getImageUrl(),
                        user.getTotalXP().doubleValue(),
                        rank.getAndIncrement(),
                        user.getStreakDays()
                ))
                .collect(Collectors.toList());
    }
}
