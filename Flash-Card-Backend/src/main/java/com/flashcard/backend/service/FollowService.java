package com.flashcard.backend.service;

import com.flashcard.backend.repository.UserFollowRepository;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.user.User;
import com.flashcard.backend.user.UserFollow;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@Service
@SuppressWarnings("null")
public class FollowService {

    @Autowired
    private UserFollowRepository followRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public void follow(User follower, Long followingId) {
        if (followingId == null) {
            throw new RuntimeException("Target user ID cannot be null");
        }
        if (follower.getId().equals(followingId)) {
            throw new RuntimeException("You cannot follow yourself");
        }

        User following = userRepository.findById(followingId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (followRepository.existsByFollowerAndFollowing(follower, following)) {
            throw new RuntimeException("Already following this user");
        }

        UserFollow follow = UserFollow.builder()
                .follower(follower)
                .following(following)
                .createdAt(Instant.now())
                .build();

        followRepository.save(follow);
    }

    @Transactional
    public void unfollow(User follower, Long followingId) {
        if (followingId == null) {
            throw new RuntimeException("Target user ID cannot be null");
        }
        User following = userRepository.findById(followingId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        UserFollow follow = followRepository.findByFollowerAndFollowing(follower, following)
                .orElseThrow(() -> new RuntimeException("Not following this user"));

        followRepository.delete(follow);
    }

    public List<User> getFollowing(User user) {
        return followRepository.findByFollower(user).stream()
                .map(UserFollow::getFollowing)
                .collect(Collectors.toList());
    }
}
