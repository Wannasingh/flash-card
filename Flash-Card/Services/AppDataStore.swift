import SwiftUI
import Combine

/**
 AppDataStore: The single source of truth for the entire application.
 Manages global state including marketplace decks, library, and user credits.
 Synchronizes with local cache for instant loading.
 */
@MainActor
class AppDataStore: ObservableObject {
    static let shared = AppDataStore()
    
    // Global State
    @Published var marketplaceDecks: [DeckModel] = []
    @Published var libraryDecks: [DeckModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Services
    private let deckAPI = DeckAPI.shared
    
    private init() {
        // Load initial state from cache for instant UI
        loadFromCache()
    }
    
    private func loadFromCache() {
        if let cachedMarket = CacheManager.shared.load([DeckDTO].self, forKey: "marketplace") {
            self.marketplaceDecks = mapDTOs(cachedMarket)
        }
        if let cachedLibrary = CacheManager.shared.load([DeckDTO].self, forKey: "library") {
            self.libraryDecks = mapDTOs(cachedLibrary)
        }
    }
    
    // MARK: - Actions
    
    func refreshMarketplace() async {
        do {
            isLoading = true
            let dtos = try await deckAPI.fetchMarketplace()
            self.marketplaceDecks = mapDTOs(dtos)
            errorMessage = nil
        } catch {
            print("[AppDataStore] Marketplace fetch error: \(error)")
            // If we have no data at all, show the error
            if marketplaceDecks.isEmpty {
                errorMessage = "Failed to load marketplace: \(error.localizedDescription)"
            }
        }
        isLoading = false
    }
    
    func refreshLibrary() async {
        do {
            isLoading = true
            let dtos = try await deckAPI.fetchMyLibrary()
            self.libraryDecks = mapDTOs(dtos)
            errorMessage = nil
        } catch {
            print("[AppDataStore] Library fetch error: \(error)")
            if libraryDecks.isEmpty {
                errorMessage = "Failed to load library: \(error.localizedDescription)"
            }
        }
        isLoading = false
    }
    
    func acquireDeck(_ deck: DeckModel) async -> Bool {
        guard let deckId = deck.backendId else { return false }
        do {
            _ = try await deckAPI.acquireDeck(deckId: deckId)
            // Immediately update library to reflect acquisition globally
            await refreshLibrary()
            return true
        } catch {
            print("[AppDataStore] Acquire error: \(error)")
            return false
        }
    }
    
    func isDeckOwned(backendId: Int?) -> Bool {
        guard let id = backendId else { return false }
        return libraryDecks.contains(where: { $0.backendId == id })
    }
    
    func updateCardCount(deckId: Int, newCount: Int) {
        // Update in marketplace if found
        if let idx = marketplaceDecks.firstIndex(where: { $0.backendId == deckId }) {
            let old = marketplaceDecks[idx]
            marketplaceDecks[idx] = DeckModel(
                id: old.id,
                backendId: old.backendId,
                title: old.title,
                creatorId: old.creatorId,
                creatorName: old.creatorName,
                cardCount: newCount,
                price: old.price,
                colorHex: old.colorHex,
                description: old.description,
                coverImageUrl: old.coverImageUrl,
                previewVideoUrl: old.previewVideoUrl
            )
        }
        // Update in library if found
        if let idx = libraryDecks.firstIndex(where: { $0.backendId == deckId }) {
            let old = libraryDecks[idx]
            libraryDecks[idx] = DeckModel(
                id: old.id,
                backendId: old.backendId,
                title: old.title,
                creatorId: old.creatorId,
                creatorName: old.creatorName,
                cardCount: newCount,
                price: old.price,
                colorHex: old.colorHex,
                description: old.description,
                coverImageUrl: old.coverImageUrl,
                previewVideoUrl: old.previewVideoUrl
            )
        }
    }
    
    // MARK: - Helpers
    
    private func mapDTOs(_ dtos: [DeckDTO]) -> [DeckModel] {
        return dtos.map { dto in
            DeckModel(
                backendId: dto.id,
                title: dto.title,
                creatorId: Int64(dto.creatorId),
                creatorName: dto.creatorName,
                cardCount: dto.cardCount,
                price: dto.priceCoins,
                colorHex: dto.customColorHex ?? "FF0080",
                description: dto.description,
                coverImageUrl: dto.coverImageUrl,
                previewVideoUrl: dto.previewVideoUrl
            )
        }
    }
}
