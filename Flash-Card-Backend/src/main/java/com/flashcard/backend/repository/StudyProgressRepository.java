package com.flashcard.backend.repository;

import com.flashcard.backend.entity.StudyProgress;
import com.flashcard.backend.entity.StudyProgressId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface StudyProgressRepository extends JpaRepository<StudyProgress, StudyProgressId> {
    
    // Find all cards due for review for a specific user
    @Query("SELECT sp FROM StudyProgress sp WHERE sp.userId = :userId AND (sp.nextReviewAt IS NULL OR sp.nextReviewAt <= :now)")
    List<StudyProgress> findDueCards(Long userId, Instant now);

    // Get total cards studied by a user
    long countByUserId(Long userId);
}
