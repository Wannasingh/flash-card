package com.flashcard.backend.entity;

import com.flashcard.backend.user.User;
import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.Instant;

@Entity
@Table(name = "study_progress", schema = "flashcard")
@IdClass(StudyProgressId.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudyProgress {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Id
    @Column(name = "card_id")
    private Long cardId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "card_id", insertable = false, updatable = false)
    private Card card;

    @Column(name = "easiness_factor", nullable = false)
    private Float easinessFactor = 2.5f;

    @Column(name = "interval_days", nullable = false)
    private Integer intervalDays = 0;

    @Column(name = "repetitions", nullable = false)
    private Integer repetitions = 0;

    @Column(name = "next_review_at")
    private Instant nextReviewAt;

    @Column(name = "last_reviewed_at")
    private Instant lastReviewedAt;
}
