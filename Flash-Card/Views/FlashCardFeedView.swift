import SwiftUI
import AVKit

struct FlashCardFeedView: View {
    @EnvironmentObject var dataStore: AppDataStore
    @EnvironmentObject var themeManager: ThemeManager
    
    // Vertical Page Tab View Style for "Short Video" feel
    var body: some View {
        ZStack {
            // Background
            themeManager.currentTheme.background.edgesIgnoringSafeArea(.all)
            
            if dataStore.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.primaryAccent))
                    Text("Connecting to Neural Net...")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .padding(.top, 10)
                }
            } else if let errorMessage = dataStore.errorMessage {
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
                        Task { await dataStore.refreshMarketplace() }
                    }
                    .padding()
                    .background(themeManager.currentTheme.primaryAccent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                // Native Vertical Paging ScrollView (iOS 17+)
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(dataStore.marketplaceDecks) { deck in
                            FeedCardView(deck: deck)
                                .containerRelativeFrame([.horizontal, .vertical])
                        }
                    }
                }
                .scrollTargetBehavior(.paging)
                .ignoresSafeArea(.all)
                
                // Overlay connectivity status
                ConnectivityBanner()
            }
        }
        .task {
            if dataStore.marketplaceDecks.isEmpty {
                await dataStore.refreshMarketplace()
            }
        }
    }
    
}

struct FeedCardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let deck: DeckModel
    @State private var isLiked = false
    @State private var isSaved = false
    @State private var isFollowed = false
    
    var body: some View {
        ZStack {
            // Background Image / Video / Gradient
            if let videoUrlStr = deck.previewVideoUrl, let videoUrl = URL(string: videoUrlStr) {
                // Loop video automatically
                VideoPlayerView(url: videoUrl)
                    .ignoresSafeArea()
            } else if let imageUrlStr = deck.coverImageUrl, let imageUrl = URL(string: imageUrlStr) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable()
                             .scaledToFill()
                    case .failure:
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: deck.colorHex), themeManager.currentTheme.background]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    @unknown default:
                        EmptyView()
                    }
                }
                .ignoresSafeArea()
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: deck.colorHex), themeManager.currentTheme.background]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .ignoresSafeArea()
            }
            
            // Subtle dark overlay to ensure text readability
            themeManager.currentTheme.feedOverlayGradient
                .ignoresSafeArea()
            
            // Content Overlay
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    // Deck Info Card (Bottom Left)
                    VStack(alignment: .leading, spacing: 12) {
                        NavigationLink(destination: PublicProfileView(userId: deck.creatorId ?? 0)) {
                            HStack(spacing: 8) {
                                if let imageUrl = deck.creatorImageUrl, let url = URL(string: imageUrl) {
                                    CachedAsyncImage(url: url) { image in
                                        image.resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .foregroundColor(.white)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                }
                                
                                Text("@\(deck.creatorName)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
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
                    VStack(spacing: 20) {
                        // Profile Pic (Action representation)
                        NavigationLink(destination: PublicProfileView(userId: deck.creatorId ?? 0)) {
                            VStack(spacing: -10) {
                                if let imageUrl = deck.creatorImageUrl, let url = URL(string: imageUrl) {
                                    CachedAsyncImage(url: url) { image in
                                        image.resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                                    .background(Color.gray)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 48, height: 48)
                                        .foregroundColor(.white)
                                        .background(Color.gray)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                }
                                
                                if !isFollowed {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(themeManager.currentTheme.primaryAccent)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.success)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                            }
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
                        
                        // Study / Deck Detail Button
                        NavigationLink(destination: DeckDetailView(deck: deck, isOwned: false)) {
                            ActionIcon(icon: "play.circle.fill", label: "Study", iconColor: .white)
                        }
                        
                        // Share Button
                        ShareLink(item: URL(string: "https://flashcardapp.com/deck/\(deck.backendId ?? 0)")!, subject: Text("Check out this deck: \(deck.title)"), message: Text("I found this awesome deck on FlashCard!")) {
                            ActionIcon(icon: "arrowshape.turn.up.right.fill", label: "Share", iconColor: .white)
                        }
                    }
                    .padding(.bottom, 10)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120) // Extra padding to clear the HomeView Bottom TabBar completely
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

// Silent looping video player for backgrounds
struct VideoPlayerView: UIViewControllerRepresentable {
    var url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVQueuePlayer(url: url)
        
        let playerItem = AVPlayerItem(url: url)
        let playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        
        // Hide controls and auto play silently
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        
        player.isMuted = true
        player.play()
        
        // Keep a reference to looper to prevent it from being deallocated
        context.coordinator.looper = playerLooper
        
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Handle updates if URL changes
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var looper: AVPlayerLooper?
    }
}
