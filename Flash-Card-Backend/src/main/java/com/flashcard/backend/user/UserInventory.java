package com.flashcard.backend.user;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_inventory", schema = "flashcard")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class UserInventory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id", nullable = false)
    private StoreItem item;

    private LocalDateTime acquiredAt;

    @PrePersist
    protected void onCreate() {
        acquiredAt = LocalDateTime.now();
    }
}
