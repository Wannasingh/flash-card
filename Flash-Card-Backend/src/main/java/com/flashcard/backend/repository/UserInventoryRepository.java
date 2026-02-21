package com.flashcard.backend.repository;

import com.flashcard.backend.user.User;
import com.flashcard.backend.user.UserInventory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserInventoryRepository extends JpaRepository<UserInventory, Long> {
    List<UserInventory> findByUser(User user);
    boolean existsByUserAndItem_Code(User user, String itemCode);
}
