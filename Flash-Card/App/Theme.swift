import SwiftUI

// MARK: - Legacy Theme Engine (Transitional)
// We retain this so existing views compile, but point them
// towards the current theme managed by ThemeManager.
// Ideally, views should use @EnvironmentObject var themeManager: ThemeManager.
enum Theme {
    static var manager: ThemeManager { ThemeManager.shared }
    static var current: AppTheme { ThemeManager.shared.currentTheme }
    
    // Background Colors
    static var cyberDark: Color { current.background }
    static var cyberCard: Color { current.surface }
    
    // Accents & Neons
    static var neonPink: Color { current.primaryAccent }
    static var cyanAccent: Color { current.secondaryAccent }
    static var electricBlue: Color { current.secondaryAccent } // Fallback
    static var cyberYellow: Color { current.warning }
    static var warning: Color { current.warning }
    static var matrixGreen: Color { current.highlight }
    static var success: Color { current.highlight }
    
    // Text
    static var textPrimary: Color { current.textPrimary }
    static var textSecondary: Color { current.textSecondary }
    
    // Gradients
    static var neonGradient: LinearGradient { current.mainGradient }
    static var cardGradient: LinearGradient { current.cardGradient }
}

// Custom Font Modifier
struct CyberpunkFont: ViewModifier {
    var size: CGFloat
    var weight: Font.Weight = .bold
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: .rounded))
    }
}

extension View {
    func cyberpunkFont(size: CGFloat, weight: Font.Weight = .bold) -> some View {
        self.modifier(CyberpunkFont(size: size, weight: weight))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
