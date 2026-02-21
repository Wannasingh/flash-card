import Foundation

enum ItemType: String, Codable {
    case aura = "AURA"
    case skin = "SKIN"
}

struct StoreItem: Codable, Identifiable {
    let id: Int
    let code: String
    let name: String
    let type: ItemType
    let price: Int
    let visualConfig: String?
}

class StoreAPI {
    static let shared = StoreAPI()
    private let baseURL = AppConfig.backendBaseURL.absoluteString
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    // ─── JWT Interceptor ──────────────────────────────────────────────────────────
    // Best Practice: attach token via Authorization header on every request.
    // Token is read from Keychain (secure encrypted hardware-backed storage),
    // NOT from plain UserDefaults which can be read by any jailbroken process.
    private func authorizedRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = try? KeychainStore.shared.getString(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    func getItems() async throws -> [StoreItem] {
        guard let url = URL(string: "\(baseURL)/api/store/items") else { throw URLError(.badURL) }
        let (data, response) = try await urlSession.data(for: authorizedRequest(url: url))
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode([StoreItem].self, from: data)
    }

    func getInventory() async throws -> [StoreItem] {
        guard let url = URL(string: "\(baseURL)/api/store/inventory") else { throw URLError(.badURL) }
        let (data, response) = try await urlSession.data(for: authorizedRequest(url: url))
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode([StoreItem].self, from: data)
    }

    func purchaseItem(code: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/store/purchase/\(code)") else { throw URLError(.badURL) }
        let (_, response) = try await urlSession.data(for: authorizedRequest(url: url, method: "POST"))
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
    }

    func equipItem(code: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/store/equip/\(code)") else { throw URLError(.badURL) }
        let (_, response) = try await urlSession.data(for: authorizedRequest(url: url, method: "POST"))
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
    }
}

