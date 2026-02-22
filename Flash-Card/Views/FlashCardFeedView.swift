import SwiftUI

struct FlashCardFeedView: View {
    @State private var trendingDecks: [DeckModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Vertical Page Tab View Style for "Short Video" feel
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.neonPink))
                    Text("Connecting to Neural Net...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .padding()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .font(.caption)
                    
                    Text("URL: \(DeckAPI.shared.baseURL)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        
                    Button("Retry") {
                        Task { await loadFeed() }
                    }
                    .padding()
                    .background(Theme.neonPink)
                    .cornerRadius(10)
                }
            } else {
                // Vertical Page TabView for TikTok-like scroll
                GeometryReader { proxy in
                    TabView {
                        ForEach(trendingDecks) { deck in
                            FeedCardView(deck: deck)
                                .rotationEffect(.degrees(-90)) // Counter-rotate content
                                .frame(width: proxy.size.width, height: proxy.size.height)
                        }
                    }
                    .rotationEffect(.degrees(90)) // Rotate TabView to scroll vertically
                    .frame(width: proxy.size.height, height: proxy.size.width)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .ignoresSafeArea()
                }
            }
        }
        .task {
            await loadFeed()
        }
    }
    
    @MainActor
    func loadFeed() async {
        guard let token = try? KeychainStore.shared.getString(forKey: "accessToken") else {
            self.errorMessage = "Please log in to view the feed."
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
            }.shuffled() // Randomize for "Feed" feel
        } catch {
            print("Feed Error: \(error.localizedDescription)")
            self.errorMessage = "Failed to load feed: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

struct FeedCardView: View {
    let deck: DeckModel
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            // Background Image / Gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: deck.colorHex), Color.black]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
            
            // Content Overlay
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    // Deck Info Card (Bottom Left)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                            Text("@\(deck.creatorName)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text(deck.title)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .lineLimit(2)
                            .foregroundColor(.white)
                        
                        if let description = deck.description {
                            Text(description)
                                .font(.subheadline)
                                .lineLimit(3)
                                .opacity(0.8)
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Label("\(deck.cardCount) Cards", systemImage: "rectangle.stack.fill")
                                .font(.caption)
                                .padding(6)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .foregroundColor(.white)
                            
                            Label("\(deck.price) Coins", systemImage: "bitcoinsign.circle.fill")
                                .font(.caption)
                                .padding(6)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .foregroundColor(Theme.cyberYellow)
                        }
                    }
                    .shadow(radius: 5)
                    
                    Spacer()
                    
                    // Right Side Action Buttons
                    VStack(spacing: 25) {
                        ActionIcon(icon: "heart.fill", label: "Like")
                        
                        NavigationLink(destination: DeckDetailView(deck: deck, isOwned: false)) {
                            VStack(spacing: 5) {
                                Image(systemName: "cart.fill.badge.plus")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Theme.neonPink)
                                    .clipShape(Circle())
                                Text("Get")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        ActionIcon(icon: "arrowshape.turn.up.right.fill", label: "Share")
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100) // Space for TabBar
            }
        }
    }
}

struct ActionIcon: View {
    var icon: String
    var label: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .shadow(radius: 5)
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(radius: 5)
        }
    }
}
