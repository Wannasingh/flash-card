package com.flashcard.backend.component;

import com.flashcard.backend.entity.Card;
import com.flashcard.backend.entity.Deck;
import com.flashcard.backend.entity.UserDeck;
import com.flashcard.backend.repository.CardRepository;
import com.flashcard.backend.repository.DeckRepository;
import com.flashcard.backend.repository.UserDeckRepository;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.user.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

@Component
public class DataSeeder implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DeckRepository deckRepository;

    @Autowired
    private CardRepository cardRepository;

    @Autowired
    private UserDeckRepository userDeckRepository;

    @Override
    public void run(String... args) throws Exception {
        String deckTitle = "Cyberpunk Slang 2077";
        Deck deck = null;

        // 1. Check if Deck exists
        Optional<Deck> existingDeck = deckRepository.findByTitle(deckTitle);
        if (existingDeck.isPresent()) {
            deck = existingDeck.get();
            System.out.println("Deck '" + deckTitle + "' already exists. Checking user_decks...");
        } else {
            // Create Deck if not exists
            deck = createDeck(deckTitle);
        }

        if (deck == null)
            return; // Should not happen

        // 2. Ensure UserDeck entry exists for the creator
        User creator = deck.getCreator();
        if (creator != null) {
            boolean userDeckExists = userDeckRepository.existsByUserAndDeckId(creator, deck.getId());
            if (!userDeckExists) {
                createUserDeck(creator, deck);
                System.out.println("Added deck to creator's library (user_decks table).");
            } else {
                System.out.println("Deck is already in creator's library.");
            }
        }
    }

    private Deck createDeck(String title) {
        // Get the requested user ID 7
        Long targetUserId = 7L;
        Optional<User> userOpt = userRepository.findById(targetUserId);

        User creator;
        if (userOpt.isPresent()) {
            creator = userOpt.get();
            System.out.println("Found User ID " + targetUserId + ": " + creator.getUsername());
        } else {
            System.out.println(
                    "User ID " + targetUserId + " not found. Attempting to fallback to first available user...");
            creator = userRepository.findAll().stream().findFirst().orElse(null);
            if (creator != null) {
                System.out.println("Fallback to User ID " + creator.getId());
            }
        }

        if (creator == null) {
            System.out.println("No users found to assign deck to. Skipping seeding.");
            return null;
        }

        Deck deck = new Deck();
        deck.setTitle(title);
        deck.setDescription("Essential slang for surviving Night City. Learn the lingo, choom.");
        deck.setTags(Arrays.asList("cyberpunk", "slang", "scifi", "english"));
        deck.setCreator(creator);
        deck.setIsPublic(true);
        deck.setPrice(0);

        deck = deckRepository.save(deck);
        System.out.println("Seeded deck: " + deck.getTitle() + " for User ID " + creator.getId());

        createCards(deck);

        return deck;
    }

    private void createCards(Deck deck) {
        List<String[]> cardsData = Arrays.asList(
                new String[] { "Choom / Choomba", "Friend, buddy, or pal. Derived from \"chumbatta\"." },
                new String[] { "Nova", "Cool, awesome, great." },
                new String[] { "Preem", "Premium, top-tier, excellent." },
                new String[] { "Delta", "To leave, get out of here quickly. \"Lets delta!\"" },
                new String[] { "Klepped", "Stolen." },
                new String[] { "Biz", "Business, situation, or problem." },
                new String[] { "Gonk", "Idiot, fool, or someone lacking intelligence." },
                new String[] { "Flatline", "To die or kill." },
                new String[] { "Zeroed", "Killed or eliminated." },
                new String[] { "Eddies", "Eurodollars (E$), the main currency." },
                new String[] { "Input", "Girlfriend or female partner." },
                new String[] { "Output", "Boyfriend or male partner." },
                new String[] { "Ripperdoc", "A medical practitioner who installs cyberware." },
                new String[] { "Corpo", "Someone who works for a megacorporation." },
                new String[] { "Netrunner", "A hacker who interfaces with the Net." },
                new String[] { "Solo", "A mercenary bodyguard or assassin." },
                new String[] { "Fixer", "A middleman who arranges deals and jobs for mercenaries." },
                new String[] { "Chrome", "Cyberware or cybernetic implants." },
                new String[] { "Brain Dance (BD)", "A recording of someone elses neural experience." },
                new String[] { "Edge", "The boundary of what is safe or legal; living on the edge." });

        for (String[] data : cardsData) {
            createCard(deck, data[0], data[1]);
        }
        System.out.println("Seeded " + cardsData.size() + " cards for deck: " + deck.getTitle());
    }

    private void createCard(Deck deck, String front, String back) {
        Card card = new Card();
        card.setDeck(deck);
        card.setFrontText(front);
        card.setBackText(back);
        cardRepository.save(card);
    }

    private void createUserDeck(User user, Deck deck) {
        UserDeck userDeck = new UserDeck();
        userDeck.setUserId(user.getId());
        userDeck.setDeckId(deck.getId());
        userDeck.setIsFavorite(false);
        userDeck.setAcquiredAt(Instant.now());
        userDeckRepository.save(userDeck);
    }
}
