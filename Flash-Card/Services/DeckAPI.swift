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

class DeckAPI {
    static let shared = DeckAPI()
    
    private let baseURL = "http://localhost:8080/api/decks"
    
    // Fetch user's personal library
    func fetchMyLibrary(token: String) async throws -> [DeckDTO] {
        guard let url = URL(string: "\(baseURL)/library") else {
            throw NSLocalizedString("Invalid URL", comment: "") as! Error
        }
        
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
        guard let url = URL(string: "\(baseURL)/marketplace") else {
            throw NSLocalizedString("Invalid URL", comment: "") as! Error
        }
        
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
        guard let url = URL(string: "\(baseURL)/\(deckId)/acquire") else {
            throw NSLocalizedString("Invalid URL", comment: "") as! Error
        }
        
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
    func createDeck(token: String, title: String, description: String, customColorHex: String, priceCoins: Int, isPublic: Bool) async throws -> DeckDTO {
        guard let url = URL(string: baseURL) else {
            throw NSLocalizedString("Invalid URL", comment: "") as! Error
        }
        
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
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
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
}
