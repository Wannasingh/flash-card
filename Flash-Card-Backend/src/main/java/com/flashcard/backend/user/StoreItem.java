package com.flashcard.backend.user;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "store_items", schema = "flashcard")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class StoreItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String code;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ItemType type;

    @Column(nullable = false)
    private Integer price;

    @Column(columnDefinition = "TEXT")
    private String visualConfig;

    public enum ItemType {
        AURA, SKIN
    }
}
