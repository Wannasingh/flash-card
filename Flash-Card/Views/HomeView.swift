import SwiftUI

struct HomeView: View {
    enum Tab {
        case market
        case library
        case add
        case rankings
        case profile
    }
    
    @State private var selectedTab: Tab = .market
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @AppStorage("isTabBarHidden") var isTabBarHidden: Bool = false
    
    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView()
        } else {
            ZStack(alignment: .bottom) {
                // Background
                themeManager.currentTheme.background
                    .ignoresSafeArea()
                
                // Main Content
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        FlashCardFeedView()
                            .ignoresSafeArea()
                            .toolbar(.hidden, for: .navigationBar)
                    }
                    .tag(Tab.market)
                    
                    NavigationStack {
                        DeckLibraryView()
                            .toolbar(.hidden, for: .navigationBar)
                    }
                    .tag(Tab.library)
                    
                    NavigationStack {
                        CreateDeckView()
                            .toolbar(.hidden, for: .navigationBar)
                    }
                    .tag(Tab.add)
                    
                    NavigationStack {
                        LeaderboardView()
                            .toolbar(.hidden, for: .navigationBar)
                    }
                    .tag(Tab.rankings)
                    
                    NavigationStack {
                        ProfileView()
                            .toolbar(.hidden, for: .navigationBar)
                    }
                    .tag(Tab.profile)
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // Allows swiping sideways between main tabs!
                .ignoresSafeArea()
                
                // Custom Bottom Navigation Bar
                if !isTabBarHidden {
                    VStack(spacing: 0) {
                    Spacer()
                    
                    HStack(spacing: 0) {
                        TabBarItem(icon: "play.rectangle.fill", label: "Home", isSelected: selectedTab == .market) {
                            withAnimation { selectedTab = .market }
                        }
                        
                        TabBarItem(icon: "books.vertical.fill", label: "Library", isSelected: selectedTab == .library) {
                            withAnimation { selectedTab = .library }
                        }
                        
                        // Center Add Button
                        Button(action: {
                            withAnimation { selectedTab = .add }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeManager.currentTheme.primaryAccent)
                                    .frame(width: 48, height: 32)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        TabBarItem(icon: "trophy.fill", label: "Rank", isSelected: selectedTab == .rankings) {
                            withAnimation { selectedTab = .rankings }
                        }
                        
                        TabBarItem(icon: "person.fill", label: "Profile", isSelected: selectedTab == .profile) {
                            withAnimation { selectedTab = .profile }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.bottom, 20) // Safe Area
                    .background(Color.black.opacity(0.85)) // TikTok dark bar vibe
                }
                .ignoresSafeArea(edges: .bottom)
                }
            }
        }
    }
}

struct TabBarItem: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .white : themeManager.currentTheme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
