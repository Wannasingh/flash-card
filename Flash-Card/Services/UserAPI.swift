import Foundation

class UserAPI: BaseAPI {
    static let shared = UserAPI()
    
    func fetchPublicProfile(userId: Int64) async throws -> PublicProfileResponse {
        let request = try createRequest(path: "/api/user/profile/\(userId)", method: "GET")
        return try await performRequest(request, responseType: PublicProfileResponse.self)
    }

    func followUser(userId: Int64) async throws {
        let request = try createRequest(path: "/api/follow/\(userId)", method: "POST")
        _ = try await performRequest(request, responseType: MessageResponse.self)
    }

    func unfollowUser(userId: Int64) async throws {
        let request = try createRequest(path: "/api/unfollow/\(userId)", method: "DELETE")
        _ = try await performRequest(request, responseType: MessageResponse.self)
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
