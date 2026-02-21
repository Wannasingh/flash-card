import Foundation

final class AuthAPI {
    static let shared = AuthAPI()

    private init() {}

    private let session = URLSession.shared

    func login(usernameOrEmail: String, password: String) async throws -> JwtResponse {
        try await postJSON(
            path: "/api/auth/signin",
            body: ["username": usernameOrEmail, "password": password],
            response: JwtResponse.self
        )
    }

    func signup(username: String, email: String, password: String) async throws {
        _ = try await postJSON(
            path: "/api/auth/signup",
            body: ["username": username, "email": email, "password": password],
            response: MessageResponse.self
        )
    }

    func oauthApple(identityToken: String, rawNonce: String?, displayName: String?) async throws -> JwtResponse {
        var body: [String: Any] = ["identityToken": identityToken]
        if let rawNonce, !rawNonce.isEmpty {
            body["rawNonce"] = rawNonce
        }
        if let displayName, !displayName.isEmpty {
            body["displayName"] = displayName
        }
        return try await postJSON(path: "/api/auth/oauth/apple", body: body, response: JwtResponse.self)
    }

    func oauthGoogle(code: String, codeVerifier: String, redirectUri: String) async throws -> JwtResponse {
        return try await postJSON(
            path: "/api/auth/oauth/google",
            body: ["code": code, "codeVerifier": codeVerifier, "redirectUri": redirectUri],
            response: JwtResponse.self
        )
    }

    func updateProfile(displayName: String, imageUrl: String?) async throws -> JwtResponse {
        var body: [String: Any] = ["displayName": displayName]
        if let imageUrl {
            body["imageUrl"] = imageUrl
        }
        return try await putJSON(path: "/api/user/profile", body: body, response: JwtResponse.self)
    }

    func fetchProfile() async throws -> JwtResponse {
        return try await getJSON(path: "/api/user/me", response: JwtResponse.self)
    }

    private func getAuthToken() -> String? {
        try? KeychainStore.shared.getString(forKey: "accessToken")
    }

    func uploadProfileImage(data: Data) async throws -> JwtResponse {
        return try await uploadMultipart(path: "/api/user/profile/image", fieldName: "file", fileName: "profile.png", mimeType: "image/png", data: data, response: JwtResponse.self)
    }

    private func uploadMultipart<T: Decodable>(path: String, fieldName: String, fileName: String, mimeType: String, data: Data, response: T.Type) async throws -> T {
        var request = try createRequest(path: path, method: "POST")
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        return try await performRequest(request, response: response)
    }

    private func postJSON<T: Decodable>(path: String, body: [String: Any], response: T.Type) async throws -> T {
        var request = try createRequest(path: path, method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        return try await performRequest(request, response: response)
    }

    private func putJSON<T: Decodable>(path: String, body: [String: Any], response: T.Type) async throws -> T {
        var request = try createRequest(path: path, method: "PUT")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        return try await performRequest(request, response: response)
    }

    private func getJSON<T: Decodable>(path: String, response: T.Type) async throws -> T {
        let request = try createRequest(path: path, method: "GET")
        return try await performRequest(request, response: response)
    }

    private func createRequest(path: String, method: String) throws -> URLRequest {
        let baseURL = AppConfig.backendBaseURL
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest, response: T.Type, isRetry: Bool = false) async throws -> T {
        let (data, urlResponse) = try await session.data(for: request)
        let http = urlResponse as? HTTPURLResponse
        let status = http?.statusCode ?? 0

        // On 401: try silent token refresh once, then retry the original request
        if status == 401 && !isRetry {
            do {
                try await refreshAccessToken()
                // Rebuild the request with the new access token and retry
                var retried = request
                if let newToken = getAuthToken() {
                    retried.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                }
                return try await performRequest(retried, response: response, isRetry: true)
            } catch {
                // Refresh failed (token expired or revoked) → force logout
                await MainActor.run { SessionStore.shared.handleUnauthorized() }
                throw NSError(domain: "AuthAPI", code: 401, userInfo: [
                    NSLocalizedDescriptionKey: "Session expired. Please login again."
                ])
            }
        }

        if (200..<300).contains(status) {
            return try JSONDecoder().decode(T.self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiError.self, from: data) {
            throw NSError(domain: "AuthAPI", code: status, userInfo: [
                NSLocalizedDescriptionKey: apiError.message ?? "Request failed"
            ])
        }

        throw NSError(domain: "AuthAPI", code: status, userInfo: [
            NSLocalizedDescriptionKey: "Request failed with status \(status)"
        ])
    }

    /// Called automatically when a 401 is received. Exchanges the stored refresh token
    /// for a new access token and saves it to Keychain. Throws if refresh is not possible.
    func refreshAccessToken() async throws {
        guard let refreshToken = try? KeychainStore.shared.getString(forKey: "refreshToken"),
              !refreshToken.isEmpty else {
            throw NSError(domain: "AuthAPI", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "No refresh token available"
            ])
        }

        let baseURL = AppConfig.backendBaseURL
        var request = URLRequest(url: baseURL.appendingPathComponent("/api/auth/refresh"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["refreshToken": refreshToken])

        let (data, urlResponse) = try await session.data(for: request)
        let status = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0

        guard (200..<300).contains(status) else {
            throw NSError(domain: "AuthAPI", code: status, userInfo: [
                NSLocalizedDescriptionKey: "Refresh token rejected"
            ])
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

