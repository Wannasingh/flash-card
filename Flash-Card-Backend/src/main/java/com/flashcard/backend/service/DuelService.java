package com.flashcard.backend.service;

import com.flashcard.backend.payload.response.DuelMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedBlockingQueue;

@Service
@SuppressWarnings("null")
public class DuelService {

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private com.flashcard.backend.repository.UserRepository userRepository;

    @Autowired
    private BadgeService badgeService;

    private final LinkedBlockingQueue<String> matchmakingQueue = new LinkedBlockingQueue<>();
    private final Map<String, String> activeDuels = new ConcurrentHashMap<>(); // username -> opponent
    private final Map<String, Long> duelIds = new ConcurrentHashMap<>();

    public void joinQueue(String username) {
        if (matchmakingQueue.contains(username) || activeDuels.containsKey(username)) return;

        matchmakingQueue.offer(username);
        checkMatchmaking();
    }

    private synchronized void checkMatchmaking() {
        while (matchmakingQueue.size() >= 2) {
            String p1 = matchmakingQueue.poll();
            String p2 = matchmakingQueue.poll();

            if (p1 != null && p2 != null) {
                Long duelId = System.currentTimeMillis();
                activeDuels.put(p1, p2);
                activeDuels.put(p2, p1);
                duelIds.put(p1, duelId);
                duelIds.put(p2, duelId);

                // Notify both players
                sendMatchNotification(p1, p2, duelId);
                sendMatchNotification(p2, p1, duelId);
            }
        }
    }

    private void sendMatchNotification(String player, String opponent, Long duelId) {
        DuelMessage msg = DuelMessage.builder()
                .type(DuelMessage.Type.MATCHED)
                .DuelId(duelId)
                .sender("SYSTEM")
                .opponent(opponent)
                .content("MATCH_FOUND")
                .build();
        
        messagingTemplate.convertAndSendToUser(player, "/topic/duel", msg);
    }

    public void updateProgress(String username, Double progress) {
        String opponent = activeDuels.get(username);
        if (opponent != null) {
            DuelMessage msg = DuelMessage.builder()
                    .type(DuelMessage.Type.PROGRESS)
                    .DuelId(duelIds.get(username))
                    .sender(username)
                    .progress(progress)
                    .build();
            
            messagingTemplate.convertAndSendToUser(opponent, "/topic/duel", msg);
            
            if (progress >= 1.0) {
                finishDuel(username, opponent);
            }
        }
    }

    private void finishDuel(String winner, String loser) {
        DuelMessage msg = DuelMessage.builder()
                .type(DuelMessage.Type.FINISH)
                .content(winner)
                .build();

        messagingTemplate.convertAndSendToUser(winner, "/topic/duel", msg);
        messagingTemplate.convertAndSendToUser(loser, "/topic/duel", msg);

        // Award Badge
        userRepository.findByUsername(winner).ifPresent(user -> {
            badgeService.awardBadgeIfEligible(user, "DUEL_WINNER");
        });

        // Cleanup
        activeDuels.remove(winner);
        activeDuels.remove(loser);
        duelIds.remove(winner);
        duelIds.remove(loser);
    }

    public void sendReaction(String username, String reaction) {
        String opponent = activeDuels.get(username);
        if (opponent != null) {
            DuelMessage msg = DuelMessage.builder()
                    .type(DuelMessage.Type.CHAT)
                    .sender(username)
                    .content(reaction)
                    .build();
            messagingTemplate.convertAndSendToUser(opponent, "/topic/duel", msg);
        }
    }

    public void quitDuel(String username) {
        matchmakingQueue.remove(username);
        String opponent = activeDuels.get(username);
        if (opponent != null) {
            finishDuel(opponent, username); // Opponent wins by default
        }
    }
}
