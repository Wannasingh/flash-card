package com.flashcard.backend.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.flashcard.backend.payload.request.BrainDumpRequest;
import com.flashcard.backend.payload.response.BrainDumpCardDto;
import com.flashcard.backend.payload.response.BrainDumpResponse;
import org.springframework.ai.chat.ChatClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AIBrainDumpService {

    private final ChatClient chatClient;
    private final ObjectMapper objectMapper;

    @Autowired
    public AIBrainDumpService(ChatClient chatClient) {
        this.chatClient = chatClient;
        this.objectMapper = new ObjectMapper();
    }

    public BrainDumpResponse generateCardsFromText(BrainDumpRequest request) {
        String promptText = "You are a professional flashcard creator. Your task is to extract key facts from the following text and format them as a JSON array of flashcards.\n" +
                "Each flashcard must have the following fields:\n" +
                "- frontText (the question or concept)\n" +
                "- backText (the answer or definition)\n" +
                "- aiMnemonic (a clever, short mnemonic or memory trick to help remember the fact)\n\n" +
                "Return ONLY a valid JSON array of objects. Do not include markdown formatting like ```json or anything else. Just the raw array.\n\n" +
                "Text:\n" + request.getText();

        String rawResponse = chatClient.call(promptText);

        try {
            // Clean up potential markdown formatting if the LLM ignores instructions
            String cleanJson = rawResponse.trim();
            if (cleanJson.startsWith("```json")) {
                cleanJson = cleanJson.substring(7);
            }
            if (cleanJson.endsWith("```")) {
                cleanJson = cleanJson.substring(0, cleanJson.length() - 3);
            }
            cleanJson = cleanJson.trim();

            List<BrainDumpCardDto> cards = objectMapper.readValue(cleanJson, new TypeReference<List<BrainDumpCardDto>>() {});
            return new BrainDumpResponse(cards);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to parse AI response into flashcards: " + e.getMessage(), e);
        }
    }
}
