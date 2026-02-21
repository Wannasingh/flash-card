import Foundation

enum AppConfig {
    static var backendBaseURL: URL {
        if let v = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String, !v.isEmpty, !v.contains("$") {
             return URL(string: v) ?? URL(string: "http://localhost:8081")!
        }
        return URL(string: "http://localhost:8081")!
    }

    static var googleClientId: String {
        guard let val = Bundle.main.object(forInfoDictionaryKey: "GoogleOAuthClientId") as? String,
              !val.isEmpty, !val.contains("$") else {
            fatalError("GoogleOAuthClientId not configured in Info.plist / xcconfig")
        }
        return val
    }

    static var googleRedirectScheme: String {
        guard let val = Bundle.main.object(forInfoDictionaryKey: "GoogleOAuthRedirectScheme") as? String,
              !val.isEmpty, !val.contains("$") else {
            fatalError("GoogleOAuthRedirectScheme not configured in Info.plist / xcconfig")
        }
        return val
    }
}
