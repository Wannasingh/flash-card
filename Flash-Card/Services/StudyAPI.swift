import Foundation

class StudyAPI: BaseAPI {
    static let shared = StudyAPI()
    
    func fetchDueCards() async throws -> [CardModel] {
        let request = try createRequest(path: "/api/study/due-cards", method: "GET")
        do {
            let cards = try await performRequest(request, responseType: [CardResponse].self)
            CacheManager.shared.save(cards, forKey: "due_cards")
            return mapToModel(cards)
        } catch {
            if let cached = CacheManager.shared.load([CardResponse].self, forKey: "due_cards") {
                print("[StudyAPI] 📶 Network failed, returning cached due cards.")
                return mapToModel(cached)
            }
            throw error
        }
    }
    
    private func mapToModel(_ responses: [CardResponse]) -> [CardModel] {
        return responses.map {
            CardModel(
                id: UUID(),
                backendId: $0.id,
                frontText: $0.frontText,
                backText: $0.backText,
                imageUrl: $0.imageUrl,
                videoUrl: $0.videoUrl,
                arModelUrl: $0.arModelUrl,
                memeUrl: $0.memeUrl,
                aiMnemonic: $0.aiMnemonic
            )
        }
    }
    
    func fetchCardsForDeck(deckId: Int) async throws -> [CardModel] {
        let request = try createRequest(path: "/api/decks/\(deckId)/cards", method: "GET")
        do {
            let cards = try await performRequest(request, responseType: [CardResponse].self)
            CacheManager.shared.save(cards, forKey: "deck_cards_\(deckId)")
            return mapToModel(cards)
        } catch {
            if let cached = CacheManager.shared.load([CardResponse].self, forKey: "deck_cards_\(deckId)") {
                print("[StudyAPI] 📶 Network failed, returning cached deck cards.")
                return mapToModel(cached)
            }
            throw error
        }
    }
    
    func submitReview(cardId: Int, quality: Int) async throws {
        let request = try createRequest(path: "/api/study/\(cardId)/review", method: "POST", body: ["quality": quality])
        _ = try await performRequest(request, responseType: MessageResponse.self)
    }
}

// Struct matching the backend /api/study/due-cards JSON response
struct CardResponse: Codable {
    let id: Int
    let deckId: Int
    let frontText: String
    let backText: String
    let imageUrl: String?
    let videoUrl: String?
    let arModelUrl: String?
    let memeUrl: String?
    let aiMnemonic: String?
}
