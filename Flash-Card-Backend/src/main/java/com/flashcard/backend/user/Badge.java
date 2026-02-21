package com.flashcard.backend.user;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "badges", schema = "flashcard")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class Badge {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String code; // e.g., "STREAK_7"

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String description;

    private String iconUrl;

    @Enumerated(EnumType.STRING)
    private BadgeCategory category;

    public enum BadgeCategory {
        STUDY, DUEL, SOCIAL, STREAK
    }
}
