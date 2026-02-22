import Foundation

/// Base class for all API services, providing centralized networking logic,
/// automatic token refresh on 401 Unauthorized, and request retries.
class BaseAPI {
    internal let session = URLSession.shared
    
    internal var baseURL: URL {
        AppConfig.backendBaseURL
    }
    
    /// Main entry point for performing network requests with automatic auth handling.
    internal func performRequest<T: Decodable>(_ request: URLRequest, responseType: T.Type, isRetry: Bool = false) async throws -> T {
        let (data, response) = try await session.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 0
        
        // Handle 401 Unauthorized: Try silent token refresh
        if statusCode == 401 && !isRetry {
            print("[Network] 🔑 Unauthorized (401) -> Attempting token refresh...")
            do {
                try await AuthAPI.shared.refreshAccessToken()
                
                // Re-build request with new token
                var retriedRequest = request
                if let newToken = try? KeychainStore.shared.getString(forKey: "accessToken") {
                    retriedRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                }
                
                print("[Network] 🔄 Token refreshed -> Retrying original request...")
                return try await performRequest(retriedRequest, responseType: responseType, isRetry: true)
            } catch {
                print("[Network] ❌ Refresh failed -> Logging out user")
                await MainActor.run {
                    SessionStore.shared.handleUnauthorized()
                }
                throw APIError.custom("Session expired. Please log in again.")
            }
        }
        
        // Check for success range
        guard (200..<300).contains(statusCode) else {
            // Attempt to decode backend error message
            if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                throw APIError.custom(apiError.message ?? "Request failed (Error \(statusCode))")
            }
            throw APIError.custom("Request failed with status \(statusCode)")
        }
        
        // Decode successful response
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("[Network] 🫥 Decoding Error: \(error)")
            throw APIError.custom("Failed to process server response.")
        }
    }
    
    /// Helper to create a standard JSON URLRequest
    internal func createRequest(path: String, method: String, body: [String: Any]? = nil) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = try? KeychainStore.shared.getString(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        return request
    }
}

/// Shared error response model from backend
struct ApiErrorResponse: Codable {
    let message: String?
    let timestamp: String?
}

/// Consolidated API Errors
enum APIError: LocalizedError {
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .custom(let message): return message
        }
    }
}
