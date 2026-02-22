import Foundation

final class AuthAPI: BaseAPI {
    static let shared = AuthAPI()

    private override init() {}

    func login(usernameOrEmail: String, password: String) async throws -> JwtResponse {
        let request = try createRequest(
            path: "/api/auth/signin",
            method: "POST",
            body: ["username": usernameOrEmail, "password": password]
        )
        return try await performRequest(request, responseType: JwtResponse.self)
    }

    func signup(username: String, email: String, password: String) async throws {
        let request = try createRequest(
            path: "/api/auth/signup",
            method: "POST",
            body: ["username": username, "email": email, "password": password]
        )
        _ = try await performRequest(request, responseType: MessageResponse.self)
    }

    func oauthApple(identityToken: String, rawNonce: String?, displayName: String?) async throws -> JwtResponse {
        var body: [String: Any] = ["identityToken": identityToken]
        if let rawNonce, !rawNonce.isEmpty { body["rawNonce"] = rawNonce }
        if let displayName, !displayName.isEmpty { body["displayName"] = displayName }
        
        let request = try createRequest(path: "/api/auth/oauth/apple", method: "POST", body: body)
        return try await performRequest(request, responseType: JwtResponse.self)
    }

    func oauthGoogle(code: String, codeVerifier: String, redirectUri: String) async throws -> JwtResponse {
        let request = try createRequest(
            path: "/api/auth/oauth/google",
            method: "POST",
            body: ["code": code, "codeVerifier": codeVerifier, "redirectUri": redirectUri]
        )
        return try await performRequest(request, responseType: JwtResponse.self)
    }

    func updateProfile(displayName: String, imageUrl: String?) async throws -> JwtResponse {
        var body: [String: Any] = ["displayName": displayName]
        if let imageUrl { body["imageUrl"] = imageUrl }
        let request = try createRequest(path: "/api/user/profile", method: "PUT", body: body)
        return try await performRequest(request, responseType: JwtResponse.self)
    }

    func fetchProfile() async throws -> JwtResponse {
        let request = try createRequest(path: "/api/user/me", method: "GET")
        return try await performRequest(request, responseType: JwtResponse.self)
    }

    func uploadProfileImage(data: Data) async throws -> JwtResponse {
        var request = try createRequest(path: "/api/user/profile/image", method: "POST")
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        return try await performRequest(request, responseType: JwtResponse.self)
    }

    /// Called automatically by BaseAPI when a 401 is received. 
    /// Exchanges the stored refresh token for a new access token.
    func refreshAccessToken() async throws {
        guard let refreshToken = try? KeychainStore.shared.getString(forKey: "refreshToken"),
              !refreshToken.isEmpty else {
            throw APIError.custom("No refresh token available")
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("/api/auth/refresh"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["refreshToken": refreshToken])

        let (data, urlResponse) = try await session.data(for: request)
        let status = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0

        guard (200..<300).contains(status) else {
            throw APIError.custom("Refresh token rejected (\(status))")
        }

        let refreshResponse = try JSONDecoder().decode(JwtResponse.self, from: data)
        if let newAccessToken = refreshResponse.token {
            try KeychainStore.shared.setString(newAccessToken, forKey: "accessToken")
        }
        if let newRefreshToken = refreshResponse.refreshToken {
            try KeychainStore.shared.setString(newRefreshToken, forKey: "refreshToken")
        }
    }
}

