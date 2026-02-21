import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        NavigationView {
            ZStack {
                Theme.cyberDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        HStack(spacing: 16) {
                            if let imageUrl = sessionStore.userProfile?.imageUrl, let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.crop.circle.badge.checkmark")
                                        .resizable()
                                        .foregroundColor(Theme.neonPink)
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Theme.cyanAccent, lineWidth: 2))
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
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
                        .background(Theme.cyberCard)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.neonPink.opacity(0.5), lineWidth: 1))
                        .padding(.horizontal)
                        
                        // Gamification Dashboard (Placeholders for Step C Data)
                        HStack(spacing: 16) {
                            StatBox(icon: "flame.fill", title: "Streak", value: "12 Days", color: Theme.cyberYellow)
                            StatBox(icon: "bitcoinsign.circle.fill", title: "Coins", value: "350 🪙", color: Theme.electricBlue)
                        }
                        .padding(.horizontal)
                        
                        // Action Buttons
                        VStack(spacing: 16) {
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
        .background(Theme.cyberCard)
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
        .background(Theme.cyberCard)
        .cornerRadius(12)
    }
}

extension View {
    func navigationBarBackground() -> some View {
        self.onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1.0)
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
