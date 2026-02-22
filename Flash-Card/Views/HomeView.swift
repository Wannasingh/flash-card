import SwiftUI

struct HomeView: View {
    
    enum Tab {
        case market
        case library
        case study
        case rankings
        case profile
    }
    
    @State private var selectedTab: Tab = .market
    // 0 = Menu Page, 1 = Content Page
    @State private var currentPage: Int = 1
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView()
        } else {
            // Horizontal Paging View
            TabView(selection: $currentPage) {
                // Page 0: The Menu
                SideMenuView(selectedTab: $selectedTab, currentPage: $currentPage)
                    .tag(0)
                    .ignoresSafeArea()
                
                // Page 1: The Main Content
                NavigationView {
                    ZStack {
                        // Content based on selection
                        switch selectedTab {
                        case .market:
                            FlashCardFeedView()
                        case .library:
                            DeckLibraryView()
                        case .study:
                            StudySessionView()
                        case .rankings:
                            LeaderboardView()
                        case .profile:
                            ProfileView()
                        }
                        
                        // Floating Menu Button (Top Left)
                        VStack {
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        currentPage = 0 // Go to Menu Page
                                    }
                                }) {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                }
                                .padding(.leading, 16)
                                .padding(.top, 50) // Adjust for Safe Area
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                    .navigationBarHidden(true)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tag(1)
                .ignoresSafeArea() // Ensure content goes edge-to-edge
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()
            .background(Theme.cyberDark)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
