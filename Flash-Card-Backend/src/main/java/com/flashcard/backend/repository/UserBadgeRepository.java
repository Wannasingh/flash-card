package com.flashcard.backend.repository;

import com.flashcard.backend.user.UserBadge;
import com.flashcard.backend.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface UserBadgeRepository extends JpaRepository<UserBadge, Long> {
    List<UserBadge> findByUser(User user);
    boolean existsByUserAndBadge_Code(User user, String badgeCode);
}
