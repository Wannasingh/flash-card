import AuthenticationServices
import CryptoKit
import Foundation
import UIKit

struct GoogleOAuthResult {
    let code: String
    let codeVerifier: String
    let redirectUri: String
}

final class GoogleOAuthFlow: NSObject, ASWebAuthenticationPresentationContextProviding {
    func start() async throws -> GoogleOAuthResult {
        let codeVerifier = randomCodeVerifier()
        let codeChallenge = codeChallengeS256(codeVerifier: codeVerifier)
        let state = randomString(length: 16)

        let redirectUri = "\(AppConfig.googleRedirectScheme):/oauth2redirect"
        
        NSLog("DEBUG: Google Client ID: %@", AppConfig.googleClientId)
        NSLog("DEBUG: Redirect URI: %@", redirectUri)
        NSLog("DEBUG: AppConfig.googleRedirectScheme: %@", AppConfig.googleRedirectScheme)

        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            URLQueryItem(name: "client_id", value: AppConfig.googleClientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let url = comps.url else {
            throw NSError(domain: "GoogleOAuth", code: -1)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: AppConfig.googleRedirectScheme) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: NSError(domain: "GoogleOAuth", code: -2))
                    return
                }

                guard let callbackComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
                    continuation.resume(throwing: NSError(domain: "GoogleOAuth", code: -3))
                    return
                }

                let items = callbackComponents.queryItems ?? []
                let returnedState = items.first(where: { $0.name == "state" })?.value
                let code = items.first(where: { $0.name == "code" })?.value

                guard returnedState == state else {
                    continuation.resume(throwing: NSError(domain: "GoogleOAuth", code: -4))
                    return
                }
                guard let code else {
                    continuation.resume(throwing: NSError(domain: "GoogleOAuth", code: -5))
                    return
                }

                continuation.resume(returning: GoogleOAuthResult(code: code, codeVerifier: codeVerifier, redirectUri: redirectUri))
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
            ?? scenes.first as? UIWindowScene
        
        if let scene = windowScene {
            return scene.windows.first { $0.isKeyWindow } ?? scene.windows.first ?? UIWindow(windowScene: scene)
        }
        
        // Final fallback: use the first available window scene to create a window, avoiding init()
        let anyScene = UIApplication.shared.connectedScenes.first { $0 is UIWindowScene } as? UIWindowScene
        if let scene = anyScene {
            return UIWindow(windowScene: scene)
        }
        
        // This is scientifically impossible in a running app, but satisfies the compiler safely
        return UIWindow(frame: .zero)
    }

    private func randomCodeVerifier() -> String {
        randomString(length: 64)
    }

    private func randomString(length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status != errSecSuccess {
            fatalError("Unable to generate random bytes")
        }
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return bytes.map { chars[chars.index(chars.startIndex, offsetBy: Int($0) % chars.count)] }.reduce("", { $0 + String($1) })
    }

    private func codeChallengeS256(codeVerifier: String) -> String {
        let data = Data(codeVerifier.utf8)
        let hashed = SHA256.hash(data: data)
        return Data(hashed).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
