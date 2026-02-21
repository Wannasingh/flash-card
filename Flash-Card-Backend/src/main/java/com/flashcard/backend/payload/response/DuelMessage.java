package com.flashcard.backend.payload.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class DuelMessage {
    public enum Type {
        JOIN,        // User waiting for duel
        MATCHED,     // Duel started
        PROGRESS,    // Score update
        FINISH,      // Duel ended
        CHAT,        // Emoji reaction
        QUIT         // User disconnected
    }

    private Type type;
    private Long DuelId;
    private String sender;
    private String opponent;
    private Double progress; // 0.0 to 1.0
    private String content;  // Emoji or winner name
}
