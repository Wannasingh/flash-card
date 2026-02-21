import Foundation

class LeaderboardAPI {
    static let shared = LeaderboardAPI()
    private let baseURL = "\(AppConfig.backendBaseURL)/api/leaderboard"
    
    func fetchGlobalLeaderboard(token: String) async throws -> [LeaderboardEntry] {
        guard let url = URL(string: "\(baseURL)/global") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([LeaderboardEntry].self, from: data)
    }
    
    func fetchAllTimeLeaderboard(token: String) async throws -> [LeaderboardEntry] {
        guard let url = URL(string: "\(baseURL)/all-time") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([LeaderboardEntry].self, from: data)
    }
}

struct LeaderboardEntry: Codable, Identifiable {
    let userId: Int
    let username: String
    let displayName: String?
    let imageUrl: String?
    let xp: Double
    let rank: Int
    let streak: Int
    let activeAuraCode: String?
    
    var id: Int { userId }
}
