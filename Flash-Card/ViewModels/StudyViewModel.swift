import SwiftUI
import Combine

@MainActor
class StudyViewModel: ObservableObject {
    @Published var dueCards: [CardModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let api = StudyAPI.shared
    private let tokenStore = KeychainStore.shared
    @Published var voiceTutor = VoiceTutorService()
    @Published var isVoiceModeActive = false
    
    // Semantic similarity state
    @Published var lastEvaluation: String?
    
    func toggleVoiceMode() {
        isVoiceModeActive.toggle()
        if isVoiceModeActive {
            startVoiceLoop()
        } else {
            voiceTutor.stopListening()
        }
    }
    
    private func startVoiceLoop() {
        guard isVoiceModeActive, let currentCard = dueCards.last else { return }
        
        voiceTutor.speak(currentCard.frontText) {
            do {
                try self.voiceTutor.startListening { answer in
                    self.evaluateAnswer(answer, for: currentCard)
                }
            } catch {
                self.errorMessage = "Mic error: \(error.localizedDescription)"
                self.isVoiceModeActive = false
            }
        }
    }
    
    private func evaluateAnswer(_ answer: String, for card: CardModel) {
        let cleanAnswer = answer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCorrect = card.backText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Basic semantic match: Check if more than 60% of keywords exist or basic string distance
        // For now, let's do a simple contains check or word overlap
        let answerWords = Set(cleanAnswer.components(separatedBy: .whitespacesAndNewlines))
        let correctWords = Set(cleanCorrect.components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = answerWords.intersection(correctWords)
        let ratio = Double(intersection.count) / Double(max(1, correctWords.count))
        
        if ratio > 0.4 { // Relaxed matching for spoken voice
            lastEvaluation = "CORRECT! ✅"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.submitReview(for: card, quality: 5)
                self.lastEvaluation = nil
                self.startVoiceLoop() // Next card
            }
        } else {
            lastEvaluation = "TRY AGAIN... 🔄"
            // Let them try again once before failing? For now just re-start listening
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.lastEvaluation = nil
                try? self.voiceTutor.startListening { newAnswer in
                    self.evaluateAnswer(newAnswer, for: card)
                }
            }
        }
    }

    
    func fetchDueCards() async {
        // Try to sync any offline reviews first so we don't fetch cards we've already reviewed offline
        await StudySyncManager.shared.syncPendingReviews()
        
        guard let token = try? tokenStore.getString(forKey: "accessToken") else {
            self.errorMessage = "Not logged in"
            self.isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let cards = try await api.fetchDueCards(token: token)
            // Reverse so the first index is at the top of the ZStack visually if rendered back-to-front
            self.dueCards = cards.reversed()
            
            // Sync with Home Screen Widget
            WidgetDataStore.shared.saveDueCardsCount(cards.count)

        } catch {
            self.errorMessage = "Failed to load cards: \(error.localizedDescription)"
            print("Error fetching cards: \(error)")
        }
        
        isLoading = false
    }
    
    func submitReview(for card: CardModel, quality: Int) {
        // Remove locally for immediate UI update
        if let index = dueCards.firstIndex(where: { $0.id == card.id }) {
            dueCards.remove(at: index)
            // Update widget count
            WidgetDataStore.shared.saveDueCardsCount(dueCards.count)
        }
        
        // Ensure backend ID exists (Mock generated cards won't have it)
        guard let backendId = card.backendId, let token = try? tokenStore.getString(forKey: "accessToken") else { return }
        
        // Sync to backend asynchronously
        Task {
            do {
                try await api.submitReview(token: token, cardId: backendId, quality: quality)
                print("Successfully synced review for card \(backendId) with quality \(quality)")
            } catch {
                print("Failed to sync review for card \(backendId): \(error)")
                // Save offline for retry later
                StudySyncManager.shared.queueReview(cardId: backendId, quality: quality)
            }
        }
    }
}
