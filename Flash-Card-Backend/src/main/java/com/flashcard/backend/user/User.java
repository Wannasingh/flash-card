package com.flashcard.backend.user;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "users",
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

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(name = "user_roles",
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
