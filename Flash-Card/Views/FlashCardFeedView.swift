import SwiftUI

struct FlashCardFeedView: View {
    @State private var trendingDecks: [DeckModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @EnvironmentObject var themeManager: ThemeManager
    
    // Vertical Page Tab View Style for "Short Video" feel
    var body: some View {
        ZStack {
            // Background
            themeManager.currentTheme.background.edgesIgnoringSafeArea(.all)
            
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.primaryAccent))
                    Text("Connecting to Neural Net...")
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
                        .font(.caption)
                    
                    Text("URL: \(DeckAPI.shared.baseURL)")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        
                    Button("Retry") {
                        Task { await loadFeed() }
                    }
                    .padding()
                    .background(themeManager.currentTheme.primaryAccent)
                    .foregroundColor(.white)
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
                    .tabViewStyle(.page(indexDisplayMode: .never))
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
    @EnvironmentObject var themeManager: ThemeManager
    let deck: DeckModel
    @State private var isLiked = false
    @State private var isSaved = false
    
    var body: some View {
        ZStack {
            // Background Image / Gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: deck.colorHex), themeManager.currentTheme.background]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
            
            // Subtle dark overlay to ensure text readability
            themeManager.currentTheme.feedOverlayGradient
                .ignoresSafeArea()
            
            // Content Overlay
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    // Deck Info Card (Bottom Left)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.white)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            
                            Text("@\(deck.creatorName)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text(deck.title)
                            .font(.title2)
                            .fontWeight(.heavy)
                            .lineLimit(2)
                            .foregroundColor(.white)
                        
                        if let description = deck.description {
                            Text(description)
                                .font(.subheadline)
                                .lineLimit(3)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        
                        // Tags / Metadata
                        HStack(spacing: 8) {
                            Label("\(deck.cardCount) Cards", systemImage: "rectangle.stack.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                            
                            Label("\(deck.price) Coins", systemImage: "bitcoinsign.circle.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(8)
                                .foregroundColor(themeManager.currentTheme.warning)
                        }
                    }
                    .padding(.bottom, 20)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                    
                    // Right Side Action Buttons
                    VStack(spacing: 24) {
                        // Profile Pic (Action representation)
                        VStack(spacing: -10) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 48, height: 48)
                                .foregroundColor(.white)
                                .background(Color.gray)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(themeManager.currentTheme.primaryAccent)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        
                        // Like Button
                        Button(action: {
                            // Trigger haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
                                isLiked.toggle()
                            }
                        }) {
                            ActionIcon(
                                icon: isLiked ? "heart.fill" : "heart",
                                label: "Like",
                                iconColor: isLiked ? themeManager.currentTheme.primaryAccent : .white
                            )
                        }
                        
                        // Save Button
                        Button(action: {
                            withAnimation { isSaved.toggle() }
                        }) {
                            ActionIcon(
                                icon: isSaved ? "bookmark.fill" : "bookmark",
                                label: "Save",
                                iconColor: isSaved ? themeManager.currentTheme.warning : .white
                            )
                        }
                        
                        // Get/Buy Button
                        NavigationLink(destination: DeckDetailView(deck: deck, isOwned: false)) {
                            ActionIcon(icon: "arrow.down.circle.fill", label: "Get", iconColor: themeManager.currentTheme.highlight)
                        }
                        
                        // Share Button
                        Button(action: {
                            // Share action
                        }) {
                            ActionIcon(icon: "arrowshape.turn.up.right.fill", label: "Share", iconColor: .white)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 60) // Extra padding for new Bottom TabBar
            }
        }
        .onTapGesture(count: 2) {
            // Double tap to like
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
                isLiked = true
            }
        }
    }
}

struct ActionIcon: View {
    var icon: String
    var label: String
    var iconColor: Color = .white
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(iconColor)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
    }
}
