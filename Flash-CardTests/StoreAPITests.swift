import XCTest
@testable import Flash_Card

final class StoreAPITests: XCTestCase {
    
    var storeAPI: StoreAPI!
    var mockSession: URLSession!
    
    override func setUpWithError() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        storeAPI = StoreAPI(urlSession: mockSession)
    }
    
    func testGetItems_Success() async throws {
        let mockData = """
        [
            {"id": 1, "code": "AURA_BLUE", "name": "Blue Aura", "type": "AURA", "price": 50, "visualConfig": null}
        ]
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/store/items")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, mockData)
        }
        
        let items = try await storeAPI.getItems()
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].code, "AURA_BLUE")
        XCTAssertEqual(items[0].price, 50)
    }
    
    func testGetInventory_Success() async throws {
        let mockData = """
        [
            {"id": 2, "code": "SKIN_GLASS", "name": "Glass Skin", "type": "SKIN", "price": 100, "visualConfig": "{}"}
        ]
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/store/inventory")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, mockData)
        }
        
        let items = try await storeAPI.getInventory()
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].code, "SKIN_GLASS")
    }
    
    func testPurchaseItem_Success() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/store/purchase/AURA_BLUE")
            XCTAssertEqual(request.httpMethod, "POST")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        try await storeAPI.purchaseItem(code: "AURA_BLUE")
    }
    
    func testEquipItem_Success() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/store/equip/AURA_BLUE")
            XCTAssertEqual(request.httpMethod, "POST")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        try await storeAPI.equipItem(code: "AURA_BLUE")
    }
}

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}
