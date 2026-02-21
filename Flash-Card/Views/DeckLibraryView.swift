import SwiftUI

// Mock model for Phase 5 UI before hooking up APIs
struct DeckModel: Identifiable {
    let id = UUID()
    let backendId: Int?
    let title: String
    let creatorName: String
    let cardCount: Int
    let price: Int // 0 if free/owned
    let colorHex: String
    let description: String?
}

struct DeckLibraryView: View {
    @State private var ownedDecks: [DeckModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    func loadLibrary() async {
        guard let token = try? KeychainStore.shared.getString(forKey: "accessToken") else {
            self.errorMessage = "Please log in to view your arsenal."
            self.isLoading = false
            return
        }
        
        do {
            isLoading = true
            let dtos = try await DeckAPI.shared.fetchMyLibrary(token: token)
            // Map DTO to UI Model
            self.ownedDecks = dtos.map { dto in
                DeckModel(
                    backendId: dto.id,
                    title: dto.title,
                    creatorName: dto.creatorName,
                    cardCount: dto.cardCount,
                    price: dto.priceCoins,
                    colorHex: dto.customColorHex ?? "00E5FF", // Fallback Cyberpunk color
                    description: dto.description
                )
            }
        } catch {
            self.errorMessage = "Signal lost. Could not load decks."
            print(error)
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
                        // User Stats Header
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Your Arsenal")
                                    .cyberpunkFont(size: 28)
                                    .foregroundColor(Theme.textPrimary)
                                
                                NavigationLink(destination: DuelLobbyView()) {
                                    HStack {
                                        Image(systemName: "bolt.shield.fill")
                                            .foregroundColor(Theme.cyberYellow)
                                        Text("ENTER ARENA")
                                            .font(.caption.bold())
                                            .foregroundColor(Theme.cyberYellow)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Theme.cyberYellow.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cyberYellow.opacity(0.5), lineWidth: 1))
                                }
                            }
                            Spacer()
                            Text("\(ownedDecks.count) Decks")
                                .font(.headline)
                                .foregroundColor(Theme.cyanAccent)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Grid of Decks
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(ownedDecks) { deck in
                                NavigationLink(destination: DeckDetailView(deck: deck, isOwned: true)) {
                                    DeckCardView(deck: deck, isOwned: true)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // "Create New" Button
                            NavigationLink(destination: CreateDeckView()) {
                                VStack {
                                    Image(systemName: "plus.app.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.neonPink)
                                    Text("New Deck")
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                        .padding(.top, 8)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Theme.cyberCard)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                        .foregroundColor(Theme.neonPink.opacity(0.5))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Library")
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await loadLibrary()
                }
            }
        }
    }
}

struct DeckCardView: View {
    let deck: DeckModel
    let isOwned: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            // Cover Image Placeholder (Gradient based on hex)
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: deck.colorHex).opacity(0.8))
                    .frame(height: 120)
                
                if !isOwned {
                    HStack {
                        Spacer()
                        VStack {
                            HStack(spacing: 4) {
                                Text("\(deck.price)")
                                    .fontWeight(.bold)
                                Image(systemName: "bitcoinsign.circle.fill")
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                            .foregroundColor(Theme.cyberYellow)
                            .padding(8)
                        }
                    }
                }
            }
            
            // Text Info
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.title)
                    .cyberpunkFont(size: 16)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)
                
                Text("by \(deck.creatorName)")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                
                HStack {
                    Image(systemName: "square.stack.3d.up.fill")
                        .foregroundColor(Theme.cyanAccent)
                    Text("\(deck.cardCount) cards")
                        .font(.caption2.bold())
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .background(.regularMaterial)
        // Add a subtle border for the glass edge effect
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .cornerRadius(20)
        .shadow(color: Color(hex: deck.colorHex).opacity(0.3), radius: 15, x: 0, y: 10)
    }
}


struct DeckLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        DeckLibraryView()
    }
}
