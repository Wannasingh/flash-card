import SwiftUI

// MARK: - Gen-Z Cyberpunk Theme Engine
enum Theme {
    // Background Colors
    static let cyberDark = Color(red: 0.06, green: 0.09, blue: 0.16)   // #0F172A
    static let cyberCard = Color(red: 0.12, green: 0.16, blue: 0.25)   // Slightly brighter for cards
    
    // Accents & Neons
    static let neonPink = Color(red: 1.0, green: 0.0, blue: 0.5)       // #FF0080
    static let cyanAccent = Color(red: 0.0, green: 0.9, blue: 1.0)     // #00E5FF
    static let electricBlue = Color(red: 0.0, green: 0.39, blue: 1.0)  // #0063FF
    static let cyberYellow = Color(red: 1.0, green: 0.9, blue: 0.0)    // #FFE600
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.gray
    
    // Gradients
    static let neonGradient = LinearGradient(
        gradient: Gradient(colors: [neonPink, electricBlue]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [cyberCard, cyberCard.opacity(0.8)]),
        startPoint: .top,
        endPoint: .bottom
    )
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
