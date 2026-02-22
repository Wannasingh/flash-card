import Foundation

struct DeckListResponse: Codable {
    let decks: [DeckDTO]
}

struct DeckDTO: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let customColorHex: String?
    let coverImageUrl: String?
    let previewVideoUrl: String?
    let priceCoins: Int
    let isPublic: Bool
    let creatorId: Int
    let creatorName: String
    let creatorImageUrl: String?
    let cardCount: Int
    let owned: Bool
}

struct BrainDumpCardDto: Codable, Identifiable {
    var id: UUID = UUID()
    var frontText: String
    var backText: String
    var aiMnemonic: String
    
    enum CodingKeys: String, CodingKey {
        case frontText, backText, aiMnemonic
    }
}

struct BrainDumpResponse: Codable {
    let cards: [BrainDumpCardDto]
}

class DeckAPI: BaseAPI {
    static let shared = DeckAPI()
    
    // Fetch user's personal library
    func fetchMyLibrary() async throws -> [DeckDTO] {
        let request = try createRequest(path: "/api/decks/library", method: "GET")
        do {
            let dtos = try await performRequest(request, responseType: [DeckDTO].self)
            CacheManager.shared.save(dtos, forKey: "library")
            return dtos
        } catch {
            if let cached = CacheManager.shared.load([DeckDTO].self, forKey: "library") {
                print("[DeckAPI] 📶 Network failed, returning cached library.")
                return cached
            }
            throw error
        }
    }
    
    // Fetch public marketplace decks
    func fetchMarketplace() async throws -> [DeckDTO] {
        let request = try createRequest(path: "/api/decks/marketplace", method: "GET")
        do {
            let dtos = try await performRequest(request, responseType: [DeckDTO].self)
            CacheManager.shared.save(dtos, forKey: "marketplace")
            return dtos
        } catch {
            if let cached = CacheManager.shared.load([DeckDTO].self, forKey: "marketplace") {
                print("[DeckAPI] 📶 Network failed, returning cached marketplace.")
                return cached
            }
            throw error
        }
    }
    
    // Purchase or Acquire a Deck
    func acquireDeck(deckId: Int) async throws {
        let request = try createRequest(path: "/api/decks/\(deckId)/acquire", method: "POST")
        _ = try await performRequest(request, responseType: MessageResponse.self)
    }
    
    // Create a new Deck
    func createDeck(title: String, description: String, customColorHex: String, priceCoins: Int, isPublic: Bool, coverImageUrl: String? = nil, previewVideoUrl: String? = nil, cards: [BrainDumpCardDto]? = nil) async throws -> DeckDTO {
        var payload: [String: Any] = [
            "title": title,
            "description": description,
            "customColorHex": customColorHex,
            "priceCoins": priceCoins,
            "isPublic": isPublic
        ]
        
        if let cover = coverImageUrl { payload["coverImageUrl"] = cover }
        if let pv = previewVideoUrl  { payload["previewVideoUrl"] = pv }
        
        if let cards = cards {
            payload["cards"] = cards.map { [
                "frontText": $0.frontText,
                "backText": $0.backText,
                "aiMnemonic": $0.aiMnemonic
            ]}
        }
        
        let request = try createRequest(path: "/api/decks", method: "POST", body: payload)
        return try await performRequest(request, responseType: DeckDTO.self)
    }
    
    // Add a Card to an existing Deck
    func addCardToDeck(deckId: Int, frontContent: String, backContent: String, frontMediaUrl: String?, backMediaUrl: String?, aiMnemonic: String?) async throws {
        var payload: [String: Any] = [
            "deckId": deckId,
            "frontContent": frontContent,
            "backContent": backContent
        ]
        
        if let fmUrl = frontMediaUrl { payload["frontMediaUrl"] = fmUrl }
        if let bmUrl = backMediaUrl  { payload["backMediaUrl"] = bmUrl }
        if let aiMn = aiMnemonic     { payload["aiMnemonic"] = aiMn }
        
        let request = try createRequest(path: "/api/decks/\(deckId)/cards", method: "POST", body: payload)
        _ = try await performRequest(request, responseType: MessageResponse.self)
    }
    
    // Generate AI Mnemonic
    func generateAiMnemonic(frontText: String, backText: String, cardId: Int? = nil) async throws -> String {
        var path = "/api/cards/ai-mnemonic"
        if let cardId = cardId {
            path += "?cardId=\(cardId)"
        }
        
        let payload: [String: Any] = [
            "frontContent": frontText,
            "backContent": backText
        ]
        
        let request = try createRequest(path: path, method: "POST", body: payload)
        
        // This endpoint is slightly non-standard: it might return CardDTO or MessageResponse
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        
        if statusCode == 401 {
            try await AuthAPI.shared.refreshAccessToken()
            return try await generateAiMnemonic(frontText: frontText, backText: backText, cardId: cardId)
        }
        
        if let card = try? JSONDecoder().decode(CardDTO.self, from: data) {
            return card.aiMnemonic ?? ""
        } else if let msg = try? JSONDecoder().decode(MessageResponse.self, from: data) {
            return msg.message ?? ""
        }
        
        throw APIError.custom("Failed to generate AI mnemonic")
    }

    struct CardDTO: Codable {
        let id: Int
        let aiMnemonic: String?
    }

    // AI Brain Dump: Generate a list of cards from raw text
    func brainDump(text: String) async throws -> [BrainDumpCardDto] {
        let request = try createRequest(path: "/api/decks/braindump", method: "POST", body: ["text": text])
        let res = try await performRequest(request, responseType: BrainDumpResponse.self)
        return res.cards
    }
    
    // Fetch public decks for a specific user
    func fetchUserPublicDecks(userId: Int64) async throws -> [DeckDTO] {
        let request = try createRequest(path: "/api/decks/user/\(userId)", method: "GET")
        return try await performRequest(request, responseType: [DeckDTO].self)
    }
}


