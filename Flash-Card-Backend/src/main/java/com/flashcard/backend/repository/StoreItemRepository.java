package com.flashcard.backend.repository;

import com.flashcard.backend.user.StoreItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface StoreItemRepository extends JpaRepository<StoreItem, Long> {
    Optional<StoreItem> findByCode(String code);
}
