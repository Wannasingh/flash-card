import Foundation

struct JwtResponse: Codable {
    let token: String?
    let type: String?
    let id: Int64
    let username: String
    let email: String
    let displayName: String?
    let imageUrl: String?
    let roles: [String]
    let totalXP: Int64?
    let weeklyXP: Int64?
    let badges: [BadgeModel]?
    let activeAuraCode: String?
    let activeSkinCode: String?
    let coins: Int?
    let streakDays: Int?
}

struct MessageResponse: Codable {
    let message: String?
}

struct ApiError: Codable {
    let timestampEpochMs: Int64?
    let status: Int?
    let error: String?
    let message: String?
    let path: String?
    let fieldErrors: [String: String]?
}
