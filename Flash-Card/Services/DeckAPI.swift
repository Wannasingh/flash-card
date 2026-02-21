import Foundation

struct DeckListResponse: Codable {
    let decks: [DeckDTO]
}

struct DeckDTO: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let customColorHex: String?
    let priceCoins: Int
    let isPublic: Bool
    let creatorId: Int
    let creatorName: String
    let cardCount: Int
    let owned: Bool
}

struct BrainDumpCardDto: Codable, Identifiable {
    var id: UUID = UUID()
    let frontText: String
    let backText: String
    let aiMnemonic: String
    
    enum CodingKeys: String, CodingKey {
        case frontText, backText, aiMnemonic
    }
}

struct BrainDumpResponse: Codable {
    let cards: [BrainDumpCardDto]
}

class DeckAPI {
    static let shared = DeckAPI()
    
    private var baseURL: URL {
        AppConfig.backendBaseURL.appendingPathComponent("/api/decks")
    }
    
    // Fetch user's personal library
    func fetchMyLibrary(token: String) async throws -> [DeckDTO] {
        let url = baseURL.appendingPathComponent("/library")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSLocalizedString("Invalid network response", comment: "") as! Error
        }
        
        if httpResponse.statusCode == 200 {
            // API returns a List directly, not wrapped in an object
            return try JSONDecoder().decode([DeckDTO].self, from: data)
        } else {
            throw NSLocalizedString("Failed to fetch library", comment: "") as! Error
        }
    }
    
    // Fetch public marketplace decks
    func fetchMarketplace(token: String) async throws -> [DeckDTO] {
        let url = baseURL.appendingPathComponent("/marketplace")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSLocalizedString("Invalid network response", comment: "") as! Error
        }
        
        if httpResponse.statusCode == 200 {
            return try JSONDecoder().decode([DeckDTO].self, from: data)
        } else {
            throw NSLocalizedString("Failed to fetch marketplace", comment: "") as! Error
        }
    }
    
    // Purchase or Acquire a Deck
    func acquireDeck(token: String, deckId: Int) async throws {
        let url = baseURL.appendingPathComponent("/\(deckId)/acquire")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSLocalizedString("Invalid network response", comment: "") as! Error
        }
        
        // 200 OK, 400 Insufficient Coins
        if httpResponse.statusCode != 200 {
             throw NSLocalizedString("Failed to acquire deck (Error \(httpResponse.statusCode))", comment: "") as! Error
        }
    }
    
    // Create a new Deck
    func createDeck(token: String, title: String, description: String, customColorHex: String, priceCoins: Int, isPublic: Bool, cards: [BrainDumpCardDto]? = nil) async throws -> DeckDTO {
        let url = baseURL
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "title": title,
            "description": description,
            "customColorHex": customColorHex,
            "priceCoins": priceCoins,
            "isPublic": isPublic
        ]
        
        var finalPayload = payload
        if let cards = cards {
            let cardsPayload = cards.map { card in
                return [
                    "frontText": card.frontText,
                    "backText": card.backText,
                    "aiMnemonic": card.aiMnemonic
                ]
            }
            finalPayload["cards"] = cardsPayload
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: finalPayload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSLocalizedString("Invalid network response", comment: "") as! Error
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            return try JSONDecoder().decode(DeckDTO.self, from: data)
        } else {
             throw NSLocalizedString("Failed to create deck (Error \(httpResponse.statusCode))", comment: "") as! Error
        }
    }
    
    // Add a Card to an existing Deck
    func addCardToDeck(token: String, deckId: Int, frontContent: String, backContent: String, frontMediaUrl: String?, backMediaUrl: String?, aiMnemonic: String?) async throws {
        let url = baseURL.appendingPathComponent("/\(deckId)/cards")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var payload: [String: Any] = [
            "deckId": deckId,
            "frontContent": frontContent,
            "backContent": backContent
        ]
        
        if let fmUrl = frontMediaUrl { payload["frontMediaUrl"] = fmUrl }
        if let bmUrl = backMediaUrl  { payload["backMediaUrl"] = bmUrl }
        if let aiMn = aiMnemonic     { payload["aiMnemonic"] = aiMn }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSLocalizedString("Invalid network response", comment: "") as! Error
        }
        
        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
             throw NSLocalizedString("Failed to add card to deck (Error \(httpResponse.statusCode))", comment: "") as! Error
        }
    }
    
    // Generate AI Mnemonic
    func generateAiMnemonic(token: String, frontText: String) async throws -> String {
        let url = AppConfig.backendBaseURL.appendingPathComponent("/api/cards/ai-mnemonic")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Pass the string directly or wrap it? The Spring backend reads @RequestBody String
        request.httpBody = frontText.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSLocalizedString("Invalid network response", comment: "") as! Error
        }
        
        if httpResponse.statusCode == 200 {
            struct MessageResponse: Codable {
                let message: String
            }
            let msgObj = try JSONDecoder().decode(MessageResponse.self, from: data)
            return msgObj.message
        } else {
             throw NSLocalizedString("Failed to generate AI mnemonic (Error \(httpResponse.statusCode))", comment: "") as! Error
        }
    }
    
    // AI Brain Dump: Generate a list of cards from raw text
    func brainDump(token: String, text: String) async throws -> [BrainDumpCardDto] {
        let url = baseURL.appendingPathComponent("/braindump")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSLocalizedString("Invalid network response", comment: "") as! Error
        }
        
        if httpResponse.statusCode == 200 {
            let res = try JSONDecoder().decode(BrainDumpResponse.self, from: data)
            return res.cards
        } else {
             throw NSLocalizedString("Failed to generate cards (Error \(httpResponse.statusCode))", comment: "") as! Error
        }
    }
}

