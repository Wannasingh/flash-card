package com.flashcard.backend.service;

import com.flashcard.backend.repository.StoreItemRepository;
import com.flashcard.backend.repository.UserInventoryRepository;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.user.StoreItem;
import com.flashcard.backend.user.User;
import com.flashcard.backend.user.UserInventory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@SuppressWarnings("null")
public class StoreService {

    @Autowired
    private StoreItemRepository storeItemRepository;

    @Autowired
    private UserInventoryRepository userInventoryRepository;

    @Autowired
    private UserRepository userRepository;

    public List<StoreItem> getAllItems() {
        return storeItemRepository.findAll();
    }

    public List<StoreItem> getUserInventory(User user) {
        return userInventoryRepository.findByUser(user).stream()
                .map(UserInventory::getItem)
                .collect(Collectors.toList());
    }

    @Transactional
    public void purchaseItem(User user, String itemCode) {
        if (userInventoryRepository.existsByUserAndItem_Code(user, itemCode)) {
            throw new RuntimeException("Item already owned");
        }

        StoreItem item = storeItemRepository.findByCode(itemCode)
                .orElseThrow(() -> new RuntimeException("Item not found"));

        if (user.getCoins() < item.getPrice()) {
            throw new RuntimeException("Insufficient coins");
        }

        // Deduct coins
        user.setCoins(user.getCoins() - item.getPrice());
        userRepository.save(user);

        // Add to inventory
        UserInventory inventory = UserInventory.builder()
                .user(user)
                .item(item)
                .build();
        userInventoryRepository.save(inventory);
    }

    @Transactional
    public void equipItem(User user, String itemCode) {
        StoreItem item = storeItemRepository.findByCode(itemCode)
                .orElseThrow(() -> new RuntimeException("Item not found"));

        if (!userInventoryRepository.existsByUserAndItem_Code(user, itemCode)) {
            throw new RuntimeException("Item not owned");
        }

        if (item.getType() == StoreItem.ItemType.AURA) {
            user.setActiveAuraCode(itemCode);
        } else if (item.getType() == StoreItem.ItemType.SKIN) {
            user.setActiveSkinCode(itemCode);
        }

        userRepository.save(user);
    }
}
