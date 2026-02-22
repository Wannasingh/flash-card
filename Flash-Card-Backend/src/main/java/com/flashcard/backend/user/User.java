package com.flashcard.backend.user;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "users", schema = "flashcard",
        uniqueConstraints = {
                @UniqueConstraint(columnNames = "username"),
                @UniqueConstraint(columnNames = "email")
        })
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String username;

    @Column(nullable = false)
    private String email;

    @Column
    private String password;

    @Column(name = "display_name")
    private String displayName;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "image_source")
    private String imageSource; // "OAUTH" or "MANUAL"

    @Column(name = "image_updated_at")
    private Instant imageUpdatedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "last_login_at")
    private Instant lastLoginAt;

    @Column(name = "coins", nullable = false)
    private Integer coins = 0;

    @Column(name = "streak_days", nullable = false)
    private Integer streakDays = 0;

    @Column(name = "last_study_date")
    private java.time.LocalDate lastStudyDate;

    @Column(name = "total_xp", nullable = false)
    private Long totalXP = 0L;

    @Column(name = "weekly_xp", nullable = false)
    private Long weeklyXP = 0L;

    @Column(name = "active_aura_code")
    private String activeAuraCode;

    @Column(name = "active_skin_code")
    private String activeSkinCode;

    @Column(name = "country")
    private String country;

    @Column(name = "region")
    private String region;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(name = "user_roles", schema = "flashcard",
            joinColumns = @JoinColumn(name = "user_id"),
            inverseJoinColumns = @JoinColumn(name = "role_id"))
    private Set<Role> roles = new HashSet<>();

    public User(String username, String email, String password) {
        this.username = username;
        this.email = email;
        this.password = password;
    }

    public static User oauthUser(String username, String email, String displayName, String imageUrl) {
        User user = new User();
        user.username = username;
        user.email = email;
        user.password = null;
        user.displayName = displayName;
        user.imageUrl = imageUrl;
        user.createdAt = Instant.now();
        user.lastLoginAt = Instant.now();
        return user;
    }
}
