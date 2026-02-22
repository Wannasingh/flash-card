import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sessionStore: SessionStore
    
    @State private var displayName: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert: Bool = false
    
    var body: some View {
        ZStack {
            Color.clear.liquidGlassBackground()
            
            Form {
            Section {
                HStack {
                    Spacer()
                    ZStack(alignment: .bottomTrailing) {
                        if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else if let imageUrl = sessionStore.userProfile?.imageUrl, let url = URL(string: imageUrl) {
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image(systemName: "camera.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .background(Color.white)
                                .clipShape(Circle())
                                .foregroundColor(.blue)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical)
                
                TextField("Display Name", text: $displayName)
                    .autocapitalization(.words)
            } header: {
                Text("Profile Information")
            } footer: {
                Text("This is the name that will be shown to other users.")
            }
            
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Section {
                Button(action: saveProfile) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                }
                .disabled(isLoading || (displayName.isEmpty && selectedImageData == nil))
                .listRowBackground((displayName.isEmpty && selectedImageData == nil) ? Color.blue.opacity(0.5) : Color.blue)
            }
        }
        .scrollContentBackground(.hidden)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
        .onAppear {
            displayName = sessionStore.userProfile?.displayName ?? ""
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Profile updated successfully.")
        }
    }
    
    private func saveProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                var updatedProfile: JwtResponse?
                
                // 1. Upload image if selected
                if let selectedImageData {
                    updatedProfile = try await AuthAPI.shared.uploadProfileImage(data: selectedImageData)
                }
                
                // 2. Update display name if it changed
                if displayName != sessionStore.userProfile?.displayName {
                    updatedProfile = try await AuthAPI.shared.updateProfile(
                        displayName: displayName,
                        imageUrl: nil
                    )
                }
                
                if let updatedProfile {
                    sessionStore.userProfile = updatedProfile
                }
                
                await MainActor.run {
                    isLoading = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditProfileView()
                .environmentObject(SessionStore.shared)
        }
    }
}
