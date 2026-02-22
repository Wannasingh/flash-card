import Foundation

/**
 DeckModel: The central data structure for a flashcard deck.
 Used across Feed, Library, and Shop with SSoT.
 */
struct DeckModel: Identifiable, Codable {
    let id: UUID
    let backendId: Int?
    let title: String
    let creatorId: Int64?
    let creatorName: String
    let cardCount: Int
    let price: Int // 0 if free/owned
    let colorHex: String
    let description: String?
    let coverImageUrl: String?
    let previewVideoUrl: String?
    
    // SSoT additions - tracking local engagement states if needed
    // var isLiked: Bool = false
    // var isSaved: Bool = false
    
    init(id: UUID = UUID(), 
         backendId: Int? = nil, 
         title: String, 
         creatorId: Int64? = nil, 
         creatorName: String, 
         cardCount: Int, 
         price: Int = 0, 
         colorHex: String = "FF0080", 
         description: String? = nil, 
         coverImageUrl: String? = nil, 
         previewVideoUrl: String? = nil) {
        self.id = id
        self.backendId = backendId
        self.title = title
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.cardCount = cardCount
        self.price = price
        self.colorHex = colorHex
        self.description = description
        self.coverImageUrl = coverImageUrl
        self.previewVideoUrl = previewVideoUrl
    }
}
