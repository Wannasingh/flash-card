import SwiftUI

struct LeaderboardView: View {
    @State private var entries: [LeaderboardEntry] = []
    @State private var isWeekly = true
    @State private var isLoading = false
    @State private var selectedUserId: Int64?
    
    let api = LeaderboardAPI.shared
    let tokenStore = KeychainStore.shared
    
    var body: some View {
        ZStack {
            // Background: Liquid Glass Mesh
            AnimatedGradientMesh()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("HALL OF FAME")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .italic()
                        .foregroundStyle(.linearGradient(colors: [.white, .white.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    
                    Spacer()
                    
                    Picker("Timeframe", selection: $isWeekly) {
                        Text("Weekly").tag(true)
                        Text("All-Time").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                    .onChange(of: isWeekly) { _, _ in
                        Task { await loadLeaderboard() }
                    }
                }
                .padding()
                .padding(.top, 20)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Top 3 Podium
                            if entries.count >= 3 {
                                podiumSection
                                    .padding(.top, 40)
                            }
                            
                            // Ranking List
                            VStack(spacing: 12) {
                                ForEach(entries.indices, id: \.self) { index in
                                    if index >= 3 || entries.count < 3 {
                                        Button(action: { selectedUserId = Int64(entries[index].userId) }) {
                                            LeaderboardRow(entry: entries[index])
                                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .task {
            await loadLeaderboard()
        }
        .fullScreenCover(item: Binding(
            get: { selectedUserId.map { IdentifiableInt64(id: $0) } },
            set: { selectedUserId = $0?.id }
        )) { ident in
            PublicProfileView(userId: ident.id)
        }
    }
    
    struct IdentifiableInt64: Identifiable {
        let id: Int64
    }
    
    private var podiumSection: some View {
        HStack(alignment: .bottom, spacing: -15) {
            // 2nd Place
            Button(action: { selectedUserId = Int64(entries[1].userId) }) {
                PodiumItem(entry: entries[1], place: 2, color: .gray)
                    .scaleEffect(0.9)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 1st Place
            Button(action: { selectedUserId = Int64(entries[0].userId) }) {
                PodiumItem(entry: entries[0], place: 1, color: .orange)
                    .scaleEffect(1.1)
                    .zIndex(1)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 3rd Place
            Button(action: { selectedUserId = Int64(entries[2].userId) }) {
                PodiumItem(entry: entries[2], place: 3, color: .brown)
                    .scaleEffect(0.8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    @MainActor
    private func loadLeaderboard() async {
        guard let token = try? tokenStore.getString(forKey: "accessToken") else { return }
        
        isLoading = true
        do {
            if isWeekly {
                entries = try await api.fetchGlobalLeaderboard(token: token)
            } else {
                entries = try await api.fetchAllTimeLeaderboard(token: token)
            }
        } catch {
            print("Failed to load leaderboard: \(error)")
        }
        isLoading = false
    }
}

struct PodiumItem: View {
    let entry: LeaderboardEntry
    let place: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(color, lineWidth: 3))
                    .shadow(color: color.opacity(0.5), radius: 10)
                
                if let urlString = entry.imageUrl, let url = URL(string: urlString) {
                    CachedAsyncImage(url: url) { img in
                        img.resizable().clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.fill").foregroundStyle(.white.opacity(0.3))
                    }
                    .frame(width: 74, height: 74)
                    .aura(entry.activeAuraCode)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                // Rank Badge
                Text("\(place)")
                    .font(.caption2.bold())
                    .padding(5)
                    .background(color)
                    .clipShape(Circle())
                    .offset(x: 25, y: -25)
            }
            
            Text(entry.displayName ?? entry.username)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text("\(Int(entry.xp)) XP")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(color)
        }
        .frame(width: 100)
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    
    var body: some View {
        HStack(spacing: 15) {
            Text("\(entry.rank)")
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 30)
            
            if let urlString = entry.imageUrl, let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { img in
                    img.resizable().clipShape(Circle())
                } placeholder: {
                    Circle().fill(.white.opacity(0.1))
                }
                .frame(width: 40, height: 40)
                .aura(entry.activeAuraCode)
            } else {
                Circle().fill(.white.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .aura(entry.activeAuraCode)
                    .overlay(Image(systemName: "person.fill").font(.caption))
            }
            
            VStack(alignment: .leading) {
                Text(entry.displayName ?? entry.username)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(entry.streak) day streak")
                }
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("\(Int(entry.xp))")
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
            Text("XP")
                .font(.caption2.bold())
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}
