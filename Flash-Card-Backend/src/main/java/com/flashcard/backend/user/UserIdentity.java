package com.flashcard.backend.user;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(name = "user_identities", schema = "flashcard", uniqueConstraints = {
        @UniqueConstraint(columnNames = { "provider", "provider_user_id" }),
        @UniqueConstraint(columnNames = { "user_id", "provider" })
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserIdentity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 20)
    private String provider;

    @Column(name = "provider_user_id", nullable = false, length = 255)
    private String providerUserId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    public static UserIdentity of(User user, String provider, String providerUserId) {
        UserIdentity identity = new UserIdentity();
        identity.user = user;
        identity.provider = provider;
        identity.providerUserId = providerUserId;
        identity.createdAt = Instant.now();
        return identity;
    }
}
