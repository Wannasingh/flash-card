import SwiftUI
import StoreKit

struct ProfileView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @StateObject private var storeManager = StoreKitManager()
    @State private var showPurchaseLoading = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.clear.liquidGlassBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        HStack(spacing: 16) {
                            if let imageUrl = sessionStore.userProfile?.imageUrl, let url = URL(string: imageUrl) {
                                CachedAsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.crop.circle.badge.checkmark")
                                        .resizable()
                                        .foregroundColor(Theme.neonPink)
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .aura(sessionStore.userProfile?.activeAuraCode)
                                .overlay(Circle().stroke(Theme.cyanAccent, lineWidth: 2))
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .aura(sessionStore.userProfile?.activeAuraCode)
                                    .foregroundColor(Theme.neonPink)
                                    .overlay(Circle().stroke(Theme.cyanAccent, lineWidth: 2))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(sessionStore.userProfile?.displayName ?? sessionStore.userProfile?.username ?? "Cyber Player")
                                    .cyberpunkFont(size: 22)
                                    .foregroundColor(Theme.textPrimary)
                                
                                Text(sessionStore.userProfile?.email ?? "Netrunner")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .padding(.horizontal)
                        
                        // Gamification Dashboard
                        HStack(spacing: 16) {
                            StatBox(icon: "flame.fill", title: "Streak", value: "\(sessionStore.userProfile?.streakDays ?? 0) Days", color: Theme.cyberYellow)
                            StatBox(icon: "bitcoinsign.circle.fill", title: "Coins", value: "\(sessionStore.userProfile?.coins ?? 0) 🪙", color: Theme.electricBlue)
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            StatBox(icon: "bolt.fill", title: "Total XP", value: "\(sessionStore.userProfile?.totalXP ?? 0)", color: Theme.cyanAccent)
                            StatBox(icon: "target", title: "Weekly XP", value: "\(sessionStore.userProfile?.weeklyXP ?? 0)", color: Theme.neonPink)
                        }
                        .padding(.horizontal)
                        
                        // Badge Case
                        if let badges = sessionStore.userProfile?.badges, !badges.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("MY BADGES")
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.cyanAccent)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(badges) { badge in
                                            BadgeView(badge: badge, size: 50)
                                        }
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Top Up Coins Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("STORE")
                                .font(.caption.bold())
                                .foregroundColor(Theme.cyberYellow)
                            
                            ForEach(storeManager.coinProducts) { product in
                                Button(action: {
                                    Task {
                                        showPurchaseLoading = true
                                        _ = try? await storeManager.purchase(product)
                                        showPurchaseLoading = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "bitcoinsign.circle.fill")
                                            .foregroundColor(Theme.cyberYellow)
                                            .font(.title2)
                                        
                                        VStack(alignment: .leading) {
                                            Text(product.displayName)
                                                .font(.headline)
                                                .foregroundColor(Theme.textPrimary)
                                            Text(product.description)
                                                .font(.caption)
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                        Spacer()
                                        
                                        if showPurchaseLoading {
                                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                                        } else {
                                            Text(product.displayPrice)
                                                .font(.subheadline.bold())
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Theme.neonGradient)
                                                .foregroundColor(.white)
                                                .cornerRadius(12)
                                        }
                                    }
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            NavigationLink(destination: StoreView()) {
                                ActionRow(icon: "sparkles", title: "Aura Store", color: .yellow)
                            }
                            
                            NavigationLink(destination: EditProfileView()) {
                                ActionRow(icon: "pencil.line", title: "Edit Profile", color: Theme.cyanAccent)
                            }
                            
                            Button(action: {
                                sessionStore.logout()
                            }) {
                                ActionRow(icon: "power", title: "System Logout", color: Theme.neonPink)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await sessionStore.refreshProfile()
                }
            }
            .navigationTitle("Player Stats")
            .navigationBarBackground()
        }
    }
}

// Reusable UI Components for Profile
struct StatBox: View {
    var icon: String
    var title: String
    var value: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            Text(value)
                .cyberpunkFont(size: 18)
                .foregroundColor(Theme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.4), lineWidth: 1))
    }
}

struct ActionRow: View {
    var icon: String
    var title: String
    var color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            Text(title)
                .cyberpunkFont(size: 16)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Theme.textSecondary)
                .font(.system(size: 14))
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
}

extension View {
    func navigationBarBackground() -> some View {
        self.onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground() // Make the navigation bar glass
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().tintColor = UIColor(Theme.cyanAccent)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(SessionStore.shared)
    }
}
