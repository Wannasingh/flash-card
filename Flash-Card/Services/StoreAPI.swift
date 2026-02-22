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

class StoreAPI: BaseAPI {
    static let shared = StoreAPI()
    
    func getItems() async throws -> [StoreItem] {
        let request = try createRequest(path: "/api/store/items", method: "GET")
        return try await performRequest(request, responseType: [StoreItem].self)
    }
    
    func getInventory() async throws -> [StoreItem] {
        let request = try createRequest(path: "/api/store/inventory", method: "GET")
        return try await performRequest(request, responseType: [StoreItem].self)
    }
    
    func purchaseItem(code: String) async throws {
        let request = try createRequest(path: "/api/store/purchase/\(code)", method: "POST")
        _ = try await performRequest(request, responseType: MessageResponse.self)
    }
    
    func equipItem(code: String) async throws {
        let request = try createRequest(path: "/api/store/equip/\(code)", method: "POST")
        _ = try await performRequest(request, responseType: MessageResponse.self)
    }
}
