import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @AppStorage("selectedThemeId") private var selectedThemeId: String = AppTheme.cyberpunk.id
    
    @Published var currentTheme: AppTheme {
        didSet {
            // Because @AppStorage doesn't directly trigger @Published updates
            // when we change the property, we sync it here.
            selectedThemeId = currentTheme.id
        }
    }
    
    static let shared = ThemeManager()
    
    private init() {
        // Load initial theme based on stored ID
        let savedId = UserDefaults.standard.string(forKey: "selectedThemeId") ?? AppTheme.cyberpunk.id
        self.currentTheme = AppTheme.allThemes.first { $0.id == savedId } ?? .cyberpunk
    }
    
    func setTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.currentTheme = theme
        }
    }
}
