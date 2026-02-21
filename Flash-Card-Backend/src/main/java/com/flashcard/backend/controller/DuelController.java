package com.flashcard.backend.controller;

import com.flashcard.backend.payload.response.DuelMessage;
import com.flashcard.backend.service.DuelService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.stereotype.Controller;

import java.security.Principal;

@Controller
public class DuelController {

    @Autowired
    private DuelService duelService;

    @MessageMapping("/duel.join")
    public void joinDuel(Principal principal) {
        if (principal != null) {
            duelService.joinQueue(principal.getName());
        }
    }

    @MessageMapping("/duel.progress")
    public void sendProgress(@Payload DuelMessage message, Principal principal) {
        if (principal != null) {
            duelService.updateProgress(principal.getName(), message.getProgress());
        }
    }

    @MessageMapping("/duel.reaction")
    public void sendReaction(@Payload DuelMessage message, Principal principal) {
        if (principal != null) {
            duelService.sendReaction(principal.getName(), message.getContent());
        }
    }

    @MessageMapping("/duel.quit")
    public void quitDuel(Principal principal) {
        if (principal != null) {
            duelService.quitDuel(principal.getName());
        }
    }
}
