import SwiftUI
import Combine

@MainActor
class StudyViewModel: ObservableObject {
    @Published var dueCards: [CardModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let api = StudyAPI.shared
    private let tokenStore = KeychainStore.shared
    
    func fetchDueCards() async {
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
                // Optional: Cache failed syncs for retry later (Commit 8)
            }
        }
    }
}
