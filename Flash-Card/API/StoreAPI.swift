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
    
    func getItems() async throws -> [StoreItem] {
        guard let url = URL(string: "\(baseURL)/api/store/items") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([StoreItem].self, from: data)
    }
    
    func getInventory() async throws -> [StoreItem] {
        guard let url = URL(string: "\(baseURL)/api/store/inventory") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([StoreItem].self, from: data)
    }
    
    func purchaseItem(code: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/store/purchase/\(code)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
    }
    
    func equipItem(code: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/store/equip/\(code)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await self.urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
    }
}
