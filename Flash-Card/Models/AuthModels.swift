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
