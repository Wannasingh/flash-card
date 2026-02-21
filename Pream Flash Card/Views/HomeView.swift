import SwiftUI

struct HomeView: View {
    var body: some View {
        TabView {
            Text("Home Content")
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            Text("Decks Content")
                .tabItem {
                    Label("Decks", systemImage: "square.stack.fill")
                }

            Text("Study Content")
                .tabItem {
                    Label("Study", systemImage: "book.closed.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
