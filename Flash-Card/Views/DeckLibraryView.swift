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
    @EnvironmentObject var themeManager: ThemeManager
    @State private var ownedDecks: [DeckModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Vertical Paging for owned decks
    var body: some View {
        ZStack {
            // Background
            themeManager.currentTheme.background.ignoresSafeArea()
            
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.primaryAccent))
                    Text("Loading Arsenal...")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .padding(.top, 10)
                }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.currentTheme.warning)
                    Text(errorMessage)
                        .padding()
                        .multilineTextAlignment(.center)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    Button("Retry") {
                        Task { await loadLibrary() }
                    }
                    .padding()
                    .background(themeManager.currentTheme.primaryAccent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else if ownedDecks.isEmpty {
                // Empty State
                VStack(spacing: 20) {
                    Image(systemName: "square.stack.3d.up.slash.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    Text("Your Arsenal is Empty")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    Text("Go to the Market to find decks or create your own.")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    NavigationLink(destination: CreateDeckView()) {
                        Text("Create New Deck")
                            .fontWeight(.bold)
                            .padding()
                            .background(themeManager.currentTheme.primaryAccent)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            } else {
                // TikTok Style Feed for Owned Decks
                GeometryReader { proxy in
                    TabView {
                        ForEach(ownedDecks) { deck in
                            LibraryDeckFeedCard(deck: deck)
                                .rotationEffect(.degrees(-90))
                                .frame(width: proxy.size.width, height: proxy.size.height)
                        }
                        
                        // Last Page: Create New Deck Card
                        CreateNewDeckCard()
                            .rotationEffect(.degrees(-90))
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                    .rotationEffect(.degrees(90))
                    .frame(width: proxy.size.height, height: proxy.size.width)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea()
                }
            }
        }
        .task {
            await loadLibrary()
        }
    }
    
    @MainActor
    func loadLibrary() async {
        guard let token = try? KeychainStore.shared.getString(forKey: "accessToken") else {
            self.errorMessage = "Please log in to view your arsenal."
            self.isLoading = false
            return
        }
        
        do {
            isLoading = true
            let dtos = try await DeckAPI.shared.fetchMyLibrary(token: token)
            self.ownedDecks = dtos.map { dto in
                DeckModel(
                    backendId: dto.id,
                    title: dto.title,
                    creatorName: dto.creatorName,
                    cardCount: dto.cardCount,
                    price: dto.priceCoins,
                    colorHex: dto.customColorHex ?? "00E5FF",
                    description: dto.description
                )
            }
        } catch {
            self.errorMessage = "Signal lost. Could not load decks."
            print(error)
        }
        isLoading = false
    }
}

// Full Screen Card for Owned Decks
struct LibraryDeckFeedCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let deck: DeckModel
    
    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: deck.colorHex), themeManager.currentTheme.background]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
            
            themeManager.currentTheme.feedOverlayGradient
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(themeManager.currentTheme.highlight)
                            Text("OWNED")
                                .font(.caption.bold())
                                .foregroundColor(themeManager.currentTheme.highlight)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(themeManager.currentTheme.highlight.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Text(deck.title)
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .lineLimit(2)
                            .foregroundColor(.white)
                        
                        Text("by \(deck.creatorName)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack {
                            Label("\(deck.cardCount) Cards", systemImage: "rectangle.stack.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        // Main Action: Study
                        NavigationLink(destination: DeckDetailView(deck: deck, isOwned: true)) {
                            HStack {
                                Image(systemName: "flame.fill")
                                Text("START STUDYING")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.currentTheme.primaryAccent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

struct CreateNewDeckCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(themeManager.currentTheme.primaryAccent)
                
                Text("Expand Your Arsenal")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                
                Text("Create a new deck to master new skills.")
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                NavigationLink(destination: CreateDeckView()) {
                    Text("Create New Deck")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(themeManager.currentTheme.primaryAccent)
                        .cornerRadius(12)
                }
            }
        }
    }
}
