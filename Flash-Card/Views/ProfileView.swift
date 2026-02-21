import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 16) {
                        if let imageUrl = sessionStore.userProfile?.imageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(sessionStore.userProfile?.displayName ?? sessionStore.userProfile?.username ?? "User")
                                .font(.headline)
                            Text(sessionStore.userProfile?.email ?? "No Email")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Account") {
                    NavigationLink(destination: EditProfileView()) {
                        Label("Edit Profile", systemImage: "pencil")
                    }
                    NavigationLink(destination: Text("Settings (Coming Soon)")) {
                        Label("Settings", systemImage: "gear")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        sessionStore.logout()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(SessionStore.shared)
    }
}
