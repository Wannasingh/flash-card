import Foundation

class StudyAPI {
    static let shared = StudyAPI()
    
    // Using the proxy URL defined in AppConfig or a raw string for now
    private let baseURL = "\(AppConfig.backendBaseURL)/api/study"
    
    func fetchDueCards(token: String) async throws -> [CardModel] {
        guard let url = URL(string: "\(baseURL)/due-cards") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let cards = try JSONDecoder().decode([CardResponse].self, from: data)
        
        // Map backend CardResponse to frontend CardModel
        return cards.map {
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
    
    func submitReview(token: String, cardId: Int, quality: Int) async throws {
        guard let url = URL(string: "\(baseURL)/\(cardId)/review") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["quality": quality]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
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
