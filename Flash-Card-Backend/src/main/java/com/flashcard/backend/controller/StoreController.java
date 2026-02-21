package com.flashcard.backend.controller;

import com.flashcard.backend.service.StoreService;
import com.flashcard.backend.user.StoreItem;
import com.flashcard.backend.user.User;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.service.UserDetailsImpl;
import io.swagger.v3.oas.annotations.Operation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/store")
public class StoreController {

    @Autowired
    private StoreService storeService;

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/items")
    @Operation(summary = "Get all available store items")
    public ResponseEntity<List<StoreItem>> getAllItems() {
        return ResponseEntity.ok(storeService.getAllItems());
    }

    @GetMapping("/inventory")
    @Operation(summary = "Get current user inventory")
    public ResponseEntity<List<StoreItem>> getUserInventory(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("User not found"));
        return ResponseEntity.ok(storeService.getUserInventory(user));
    }

    @PostMapping("/purchase/{code}")
    @Operation(summary = "Purchase an item")
    public ResponseEntity<?> purchaseItem(@AuthenticationPrincipal UserDetailsImpl userDetails, @PathVariable String code) {
        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("User not found"));
        try {
            storeService.purchaseItem(user, code);
            return ResponseEntity.ok("Purchase successful");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/equip/{code}")
    @Operation(summary = "Equip an owned item")
    public ResponseEntity<?> equipItem(@AuthenticationPrincipal UserDetailsImpl userDetails, @PathVariable String code) {
        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("User not found"));
        try {
            storeService.equipItem(user, code);
            return ResponseEntity.ok("Item equipped");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
