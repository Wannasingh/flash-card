import Foundation

/**
 CardModel: The central data structure for a single flashcard.
 Support text, images, video, AR models, and AI-generated mnemonics.
 */
struct CardModel: Identifiable, Codable {
    let id: UUID
    let backendId: Int?
    let frontText: String
    let backText: String
    let imageUrl: String?
    let videoUrl: String?
    let arModelUrl: String?
    let memeUrl: String?
    let aiMnemonic: String?
    
    init(id: UUID = UUID(), 
         backendId: Int? = nil, 
         frontText: String, 
         backText: String, 
         imageUrl: String? = nil, 
         videoUrl: String? = nil, 
         arModelUrl: String? = nil, 
         memeUrl: String? = nil, 
         aiMnemonic: String? = nil) {
        self.id = id
        self.backendId = backendId
        self.frontText = frontText
        self.backText = backText
        self.imageUrl = imageUrl
        self.videoUrl = videoUrl
        self.arModelUrl = arModelUrl
        self.memeUrl = memeUrl
        self.aiMnemonic = aiMnemonic
    }
}
