import Foundation

class LeaderboardAPI: BaseAPI {
    static let shared = LeaderboardAPI()
    
    func fetchGlobalLeaderboard(region: String? = nil) async throws -> [LeaderboardEntry] {
        var path = "/api/leaderboard/global"
        if let region = region {
            path += "?region=\(region.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        let request = try createRequest(path: path, method: "GET")
        return try await performRequest(request, responseType: [LeaderboardEntry].self)
    }
    
    func fetchAllTimeLeaderboard(region: String? = nil) async throws -> [LeaderboardEntry] {
        var path = "/api/leaderboard/all-time"
        if let region = region {
            path += "?region=\(region.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        let request = try createRequest(path: path, method: "GET")
        return try await performRequest(request, responseType: [LeaderboardEntry].self)
    }

    func fetchFriendsLeaderboard() async throws -> [LeaderboardEntry] {
        let request = try createRequest(path: "/api/leaderboard/friends", method: "GET")
        return try await performRequest(request, responseType: [LeaderboardEntry].self)
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
