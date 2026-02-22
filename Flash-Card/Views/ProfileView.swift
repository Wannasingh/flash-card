import SwiftUI
import StoreKit

struct ProfileView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var storeManager = StoreKitManager()
    @State private var showPurchaseLoading = false

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.background.ignoresSafeArea()
                
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
                                        .foregroundColor(themeManager.currentTheme.primaryAccent)
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .aura(sessionStore.userProfile?.activeAuraCode)
                                .overlay(Circle().stroke(themeManager.currentTheme.highlight, lineWidth: 2))
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .aura(sessionStore.userProfile?.activeAuraCode)
                                    .foregroundColor(themeManager.currentTheme.primaryAccent)
                                    .overlay(Circle().stroke(themeManager.currentTheme.highlight, lineWidth: 2))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(sessionStore.userProfile?.displayName ?? sessionStore.userProfile?.username ?? "Cyber Player")
                                    .cyberpunkFont(size: 22)
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                                
                                Text(sessionStore.userProfile?.email ?? "Netrunner")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
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
                            StatBox(icon: "flame.fill", title: "Streak", value: "\(sessionStore.userProfile?.streakDays ?? 0) Days", color: themeManager.currentTheme.warning)
                            StatBox(icon: "bitcoinsign.circle.fill", title: "Coins", value: "\(sessionStore.userProfile?.coins ?? 0) 🪙", color: themeManager.currentTheme.highlight)
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            StatBox(icon: "bolt.fill", title: "Total XP", value: "\(sessionStore.userProfile?.totalXP ?? 0)", color: themeManager.currentTheme.secondaryAccent)
                            StatBox(icon: "target", title: "Weekly XP", value: "\(sessionStore.userProfile?.weeklyXP ?? 0)", color: themeManager.currentTheme.primaryAccent)
                        }
                        .padding(.horizontal)
                        
                        // Badge Case
                        if let badges = sessionStore.userProfile?.badges, !badges.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("MY BADGES")
                                    .font(.caption.bold())
                                    .foregroundColor(themeManager.currentTheme.secondaryAccent)
                                
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
                                .foregroundColor(themeManager.currentTheme.warning)
                            
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
                                            .foregroundColor(themeManager.currentTheme.warning)
                                            .font(.title2)
                                        
                                        VStack(alignment: .leading) {
                                            Text(product.displayName)
                                                .font(.headline)
                                                .foregroundColor(themeManager.currentTheme.textPrimary)
                                            Text(product.description)
                                                .font(.caption)
                                                .foregroundColor(themeManager.currentTheme.textSecondary)
                                        }
                                        Spacer()
                                        
                                        if showPurchaseLoading {
                                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                                        } else {
                                            Text(product.displayPrice)
                                                .font(.subheadline.bold())
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(themeManager.currentTheme.mainGradient)
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
                                ActionRow(icon: "pencil.line", title: "Edit Profile", color: themeManager.currentTheme.highlight)
                            }
                            
                            Button(action: {
                                sessionStore.logout()
                            }) {
                                ActionRow(icon: "power", title: "System Logout", color: themeManager.currentTheme.primaryAccent)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .padding(.bottom, 60) // Safe Area for Bottom Tab
                }
                .refreshable {
                    await sessionStore.refreshProfile()
                }
            }
            .navigationTitle("Player Stats")
            .navigationBarBackground(themeColor: themeManager.currentTheme.primaryAccent)
        }
    }
}

// Reusable UI Components for Profile
struct StatBox: View {
    @EnvironmentObject var themeManager: ThemeManager
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
                .foregroundColor(themeManager.currentTheme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondary)
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
    @EnvironmentObject var themeManager: ThemeManager
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
                .foregroundColor(themeManager.currentTheme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .font(.system(size: 14))
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
}

extension View {
    func navigationBarBackground(themeColor: Color) -> some View {
        self.onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground() // Make the navigation bar glass
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().tintColor = UIColor(themeColor)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(SessionStore.shared)
            .environmentObject(ThemeManager.shared)
    }
}
