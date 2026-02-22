import SwiftUI

struct HomeView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView()
        } else {
            TabView {
                NavigationStack {
                    FlashCardFeedView()
                        .toolbar(.hidden, for: .navigationBar) // Ensure video is edge-to-edge
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                
                NavigationStack {
                    SearchView()
                        .navigationTitle("Search")
                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

                NavigationStack {
                    DeckLibraryView()
                        .navigationTitle("Library")
                }
                .tabItem {
                    Label("Library", systemImage: "square.grid.2x2.fill")
                }

                NavigationStack {
                    CreateDeckView()
                        .navigationTitle("Create")
                }
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                
                NavigationStack {
                    LeaderboardView()
                        .navigationTitle("Rankings")
                }
                .tabItem {
                    Label("Rankings", systemImage: "trophy.fill")
                }

                NavigationStack {
                    ProfileView()
                        .navigationTitle("Profile")
                }
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
            }
            .accentColor(Theme.electricBlue)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
