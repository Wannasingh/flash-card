import SwiftUI
import Combine

@MainActor
class SessionStore: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userProfile: JwtResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    static let shared = SessionStore()

    private init() {
        checkLogin()
    }

    func checkLogin() {
        let tokenOrNil = try? KeychainStore.shared.getString(forKey: "accessToken")
        if let token = tokenOrNil ?? nil, !token.isEmpty {
            isLoggedIn = true
            Task {
                await refreshProfile()
            }
        } else {
            isLoggedIn = false
        }
    }
    
    func refreshProfile() async {
        do {
            let response = try await AuthAPI.shared.fetchProfile()
            self.userProfile = response
        } catch {
            print("Failed to fetch profile: \(error)")
            // If unauthorized, maybe logout?
            // logout() 
        }
    }

    func login(usernameOrEmail: String, password: String) async {
        await performAuth {
            let response = try await AuthAPI.shared.login(usernameOrEmail: usernameOrEmail, password: password)
            self.handleSuccess(response: response)
        }
    }

    func signup(username: String, email: String, password: String) async {
        await performAuth {
            try await AuthAPI.shared.signup(username: username, email: email, password: password)
            // Auto login after signup
            let response = try await AuthAPI.shared.login(usernameOrEmail: email, password: password)
            self.handleSuccess(response: response)
        }
    }

    func loginWithApple(identityToken: String, rawNonce: String?, displayName: String?) async {
        await performAuth {
            let response = try await AuthAPI.shared.oauthApple(identityToken: identityToken, rawNonce: rawNonce, displayName: displayName)
            self.handleSuccess(response: response)
        }
    }

    func loginWithGoogle(code: String, codeVerifier: String, redirectUri: String) async {
        await performAuth {
            let response = try await AuthAPI.shared.oauthGoogle(code: code, codeVerifier: codeVerifier, redirectUri: redirectUri)
            self.handleSuccess(response: response)
        }
    }

    func logout() {
        KeychainStore.shared.delete(forKey: "accessToken")
        self.isLoggedIn = false
        self.userProfile = nil
    }

    private func performAuth(action: @escaping () async throws -> Void) async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            try await action()
        } catch {
            self.isLoading = false
            self.errorMessage = (error as NSError).localizedDescription
        }
    }

    private func handleSuccess(response: JwtResponse) {
        do {
            if let token = response.token {
                try KeychainStore.shared.setString(token, forKey: "accessToken")
            }
            self.userProfile = response
            self.isLoggedIn = true
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to save token: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
}
