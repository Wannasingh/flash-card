import SwiftUI

struct SideMenuView: View {
    @Binding var selectedTab: HomeView.Tab
    @Binding var currentPage: Int // 0 = Menu, 1 = Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Profile Header (Small)
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(Theme.cyanAccent)
                
                VStack(alignment: .leading) {
                    Text("Welcome Back")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("NetRunner")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 60)
            
            Divider().background(Color.gray.opacity(0.5))
            
            // Menu Items
            VStack(alignment: .leading, spacing: 25) {
                MenuRow(icon: "play.rectangle.on.rectangle.fill", text: "Market", tab: .market, selectedTab: $selectedTab, currentPage: $currentPage)
                MenuRow(icon: "square.grid.2x2.fill", text: "Library", tab: .library, selectedTab: $selectedTab, currentPage: $currentPage)
                MenuRow(icon: "flame.fill", text: "Study", tab: .study, selectedTab: $selectedTab, currentPage: $currentPage)
                MenuRow(icon: "trophy.fill", text: "Rankings", tab: .rankings, selectedTab: $selectedTab, currentPage: $currentPage)
                MenuRow(icon: "person.fill", text: "Profile", tab: .profile, selectedTab: $selectedTab, currentPage: $currentPage)
            }
            
            Spacer()
            
            // Bottom Info
            Text("v1.0.0 CyberBuild")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Theme.cyberDark.ignoresSafeArea())
    }
}

struct MenuRow: View {
    let icon: String
    let text: String
    let tab: HomeView.Tab
    @Binding var selectedTab: HomeView.Tab
    @Binding var currentPage: Int
    
    var body: some View {
        Button(action: {
            withAnimation {
                selectedTab = tab
                currentPage = 1 // Go back to Content Page
            }
        }) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .frame(width: 30)
                    .foregroundColor(selectedTab == tab ? Theme.neonPink : .gray)
                
                Text(text)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(selectedTab == tab ? .white : .gray)
            }
            .contentShape(Rectangle()) // Hit test for the whole row
        }
        .buttonStyle(PlainButtonStyle())
    }
}
