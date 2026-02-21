import Foundation

class UserAPI {
    static let shared = UserAPI()
    private let baseURL = "\(AppConfig.backendBaseURL)/api/user"
    
    func fetchPublicProfile(userId: Int64, token: String) async throws -> PublicProfileResponse {
        guard let url = URL(string: "\(baseURL)/profile/\(userId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(PublicProfileResponse.self, from: data)
    }
}

struct PublicProfileResponse: Codable {
    let id: Int64
    let username: String
    let displayName: String?
    let imageUrl: String?
    let totalXP: Int64
    let weeklyXP: Int64
    let streakDays: Int
    let badges: [BadgeModel]
    let activeAuraCode: String?
    let activeSkinCode: String?
}

struct BadgeModel: Codable, Identifiable {
    let id: Int64
    let code: String
    let name: String
    let description: String
    let iconUrl: String?
    let category: String
}
