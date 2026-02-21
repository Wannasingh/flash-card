import SwiftUI

struct MarketplaceView: View {
    @State private var trendingDecks: [DeckModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    @MainActor
    func loadMarketplace() async {
        guard let token = try? KeychainStore.shared.getString(forKey: "accessToken") else {
            self.errorMessage = "Please log in to use the Marketplace."
            self.isLoading = false
            return
        }
        
        do {
            isLoading = true
            let dtos = try await DeckAPI.shared.fetchMarketplace(token: token)
            self.trendingDecks = dtos.map { dto in
                DeckModel(
                    backendId: dto.id,
                    title: dto.title,
                    creatorName: dto.creatorName,
                    cardCount: dto.cardCount,
                    price: dto.priceCoins,
                    colorHex: dto.customColorHex ?? "FF0080",
                    description: dto.description
                )
            }
        } catch {
            self.errorMessage = "Failed to load marketplace."
        }
        isLoading = false
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid Glass Background
                Color.clear.liquidGlassBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Header Banner
                        ZStack(alignment: .leading) {
                            Theme.neonGradient
                                .cornerRadius(20)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Creator Market")
                                        .cyberpunkFont(size: 24)
                                        .foregroundColor(Theme.textPrimary)
                                    Text("Discover top decks from the community. Spend coins to unlock.")
                                        .font(.caption)
                                        .foregroundColor(Theme.textPrimary.opacity(0.8))
                                }
                                Spacer()
                                Image(systemName: "cart.fill.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .padding()
                        }
                        .frame(height: 120)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Section Title
                        HStack {
                            Text("Trending Now 🔥")
                                .cyberpunkFont(size: 22)
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Button("See All") { }
                                .font(.caption.bold())
                                .foregroundColor(Theme.neonPink)
                        }
                        .padding(.horizontal)
                        
                        // Discover Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(trendingDecks) { deck in
                                NavigationLink(destination: DeckDetailView(deck: deck, isOwned: false)) {
                                    DeckCardView(deck: deck, isOwned: false)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarHidden(true)
            .task {
                await loadMarketplace()
            }
        }
    }
}

struct MarketplaceView_Previews: PreviewProvider {
    static var previews: some View {
        MarketplaceView()
    }
}
