import SwiftUI

struct PublicProfileView: View {
    let userId: Int64
    @State private var profile: PublicProfileResponse?
    @State private var publicDecks: [DeckModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Theme.cyberDark.liquidGlassBackground()
            
            if isLoading {
                ProgressView().tint(Theme.cyanAccent)
            } else if let profile = profile {
                VStack(spacing: 30) {
                    // Header with Avatar and Name
                    VStack(spacing: 15) {
                        ProfileAvatarView(imageUrl: profile.imageUrl)
                            .frame(width: 120, height: 120)
                            .aura(profile.activeAuraCode)
                        
                        VStack(spacing: 5) {
                            Text(profile.displayName ?? profile.username)
                                .cyberpunkFont(size: 28)
                                .foregroundColor(.white)
                            
                            Text("@\(profile.username)")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Stats Grid
                    HStack(spacing: 20) {
                        StatItem(title: "TOTAL XP", value: "\(profile.totalXP)", icon: "bolt.fill", color: Theme.cyanAccent)
                        StatItem(title: "STREAK", value: "\(profile.streakDays)d", icon: "flame.fill", color: Theme.cyberYellow)
                        StatItem(title: "WEEKLY", value: "\(profile.weeklyXP)", icon: "star.fill", color: Theme.neonPink)
                    }
                    .padding()
                    .background(.white.opacity(0.05))
                    .cornerRadius(15)
                    
                    // Badge Case (Existing)
                    VStack(alignment: .leading, spacing: 20) {
                        Text("BADGE CASE")
                            .cyberpunkFont(size: 18)
                            .foregroundColor(Theme.cyanAccent)
                        
                        if profile.badges.isEmpty {
                            Text("No trophies acquired yet.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                                ForEach(profile.badges) { badge in
                                    BadgeView(badge: badge)
                                }
                            }
                        }
                    }
                    .padding()
                    
                    // Public Decks Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("PUBLIC SIGNAL DECKS")
                            .cyberpunkFont(size: 18)
                            .foregroundColor(Theme.neonPink)
                        
                        if publicDecks.isEmpty {
                            Text("No public decks decrypted.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(publicDecks) { deck in
                                        NavigationLink(destination: DeckDetailView(deck: deck, isOwned: false)) {
                                            CreatorDeckCard(deck: deck)
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button("CLOSE SIGNAL") {
                        dismiss()
                    }
                    .foregroundColor(Theme.neonPink)
                    .cyberpunkFont(size: 14)
                    .padding(.bottom, 20)
                }
            } else {
                Text(errorMessage ?? "Signal Lost")
                    .foregroundColor(.red)
            }
        }
        .task {
            await loadProfile()
        }
    }
    
    @MainActor
    private func loadProfile() async {
        do {
            async let profileTask = UserAPI.shared.fetchPublicProfile(userId: userId)
            async let decksTask = DeckAPI.shared.fetchUserPublicDecks(userId: userId)
            
            let (fetchedProfile, fetchedDecks) = try await (profileTask, decksTask)
            
            self.profile = fetchedProfile
            self.publicDecks = fetchedDecks.map { dto in
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
                    previewVideoUrl: dto.previewVideoUrl,
                    creatorImageUrl: dto.creatorImageUrl
                )
            }
            self.isLoading = false
        } catch {
            print("Profile load error: \(error)")
            self.errorMessage = "Failed to intercept profile data."
            self.isLoading = false
        }
    }
}

struct CreatorDeckCard: View {
    let deck: DeckModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: deck.colorHex))
                .frame(width: 140, height: 100)
                .overlay(
                    VStack {
                        Spacer()
                        Text("\(deck.cardCount) Cards")
                            .font(.system(size: 10, weight: .black))
                            .padding(4)
                            .background(.black.opacity(0.4))
                            .cornerRadius(4)
                            .padding(8)
                    },
                    alignment: .bottomTrailing
                )
            
            Text(deck.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text("\(deck.price) Coins")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.cyberYellow)
        }
        .frame(width: 140)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileAvatarView: View {
    let imageUrl: String?
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.cyberCard)
                .overlay(Circle().stroke(Theme.cyanAccent.opacity(0.5), lineWidth: 2))
                .shadow(color: Theme.cyanAccent, radius: 10)
            
            if let urlString = imageUrl, let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }
}
