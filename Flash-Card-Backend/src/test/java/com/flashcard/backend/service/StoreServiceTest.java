package com.flashcard.backend.service;

import com.flashcard.backend.repository.StoreItemRepository;
import com.flashcard.backend.repository.UserInventoryRepository;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.user.StoreItem;
import com.flashcard.backend.user.User;
import com.flashcard.backend.user.UserInventory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class StoreServiceTest {

    @Mock
    private StoreItemRepository storeItemRepository;

    @Mock
    private UserInventoryRepository userInventoryRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private StoreService storeService;

    private User user;
    private StoreItem item;

    @BeforeEach
    void setUp() {
        user = new User();
        user.setId(1L);
        user.setCoins(100);

        item = new StoreItem();
        item.setCode("AURA_BLUE");
        item.setPrice(50);
        item.setType(StoreItem.ItemType.AURA);
    }

    @Test
    void purchaseItem_Success() {
        when(userInventoryRepository.existsByUserAndItem_Code(user, "AURA_BLUE")).thenReturn(false);
        when(storeItemRepository.findByCode("AURA_BLUE")).thenReturn(Optional.of(item));

        storeService.purchaseItem(user, "AURA_BLUE");

        assertThat(user.getCoins()).isEqualTo(50);
        verify(userRepository).save(user);
        verify(userInventoryRepository).save(any(UserInventory.class));
    }

    @Test
    void purchaseItem_AlreadyOwned_ThrowsException() {
        when(userInventoryRepository.existsByUserAndItem_Code(user, "AURA_BLUE")).thenReturn(true);

        assertThatThrownBy(() -> storeService.purchaseItem(user, "AURA_BLUE"))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Item already owned");

        verify(userRepository, never()).save(any());
    }

    @Test
    void purchaseItem_InsufficientCoins_ThrowsException() {
        user.setCoins(10);
        when(userInventoryRepository.existsByUserAndItem_Code(user, "AURA_BLUE")).thenReturn(false);
        when(storeItemRepository.findByCode("AURA_BLUE")).thenReturn(Optional.of(item));

        assertThatThrownBy(() -> storeService.purchaseItem(user, "AURA_BLUE"))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Insufficient coins");
    }

    @Test
    void equipItem_Success() {
        when(storeItemRepository.findByCode("AURA_BLUE")).thenReturn(Optional.of(item));
        when(userInventoryRepository.existsByUserAndItem_Code(user, "AURA_BLUE")).thenReturn(true);

        storeService.equipItem(user, "AURA_BLUE");

        assertThat(user.getActiveAuraCode()).isEqualTo("AURA_BLUE");
        verify(userRepository).save(user);
    }

    @Test
    void equipItem_NotOwned_ThrowsException() {
        when(storeItemRepository.findByCode("AURA_BLUE")).thenReturn(Optional.of(item));
        when(userInventoryRepository.existsByUserAndItem_Code(user, "AURA_BLUE")).thenReturn(false);

        assertThatThrownBy(() -> storeService.equipItem(user, "AURA_BLUE"))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Item not owned");
    }
}
