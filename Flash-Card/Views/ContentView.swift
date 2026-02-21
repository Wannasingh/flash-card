import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var session: SessionStore
    @State private var showWelcomeScreen = true
    @State private var showLoginSignupScreen = false

    var body: some View {
        if session.isLoggedIn {
            HomeView()
        } else if showWelcomeScreen {
            WelcomeView(showWelcomeScreen: $showWelcomeScreen, showLoginSignupScreen: $showLoginSignupScreen)
        } else {
            LoginSignupView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(SessionStore.shared)
    }
}
