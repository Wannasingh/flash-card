import SwiftUI

struct HomeView: View {
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        // Use UIColor based on our CyberDark theme
        appearance.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1.0)
        
        // Unselected items are grey
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        
        // Selected items are electric blue
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.electricBlue)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Theme.electricBlue)]
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        TabView {
            Text("Home")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.cyberDark.ignoresSafeArea())
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            Text("Marketplace")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.cyberDark.ignoresSafeArea())
                .tabItem {
                    Label("Market", systemImage: "cart.fill")
                }

            StudySessionView()
                .tabItem {
                    // Eye-catching center button for studying
                    Label("Study", systemImage: "flame.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .accentColor(Theme.electricBlue)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
