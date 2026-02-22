import SwiftUI

/// Defines the color palette for a specific theme.
struct AppTheme: Identifiable, Equatable {
    let id: String
    let name: String
    
    // Backgrounds
    let background: Color
    let surface: Color
    
    // Accents & Neons
    let primaryAccent: Color
    let secondaryAccent: Color
    let highlight: Color // e.g., for positive action or matrix green
    let warning: Color // e.g., for cyber yellow
    
    // Text
    let textPrimary: Color
    let textSecondary: Color
    
    // Gradient
    var mainGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [primaryAccent, secondaryAccent]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cardGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [surface, surface.opacity(0.8)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // TikTok feed background/surface gradients
    var feedOverlayGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.clear, background.opacity(0.9)]),
            startPoint: .center,
            endPoint: .bottom
        )
    }
}

// MARK: - Predefined Themes

extension AppTheme {
    static let cyberpunk = AppTheme(
        id: "cyberpunk",
        name: "Cyberpunk",
        background: Color(red: 0.06, green: 0.09, blue: 0.16), // #0F172A
        surface: Color(red: 0.12, green: 0.16, blue: 0.25),    // Less dark
        primaryAccent: Color(red: 1.0, green: 0.0, blue: 0.5), // #FF0080
        secondaryAccent: Color(red: 0.0, green: 0.39, blue: 1.0), // #0063FF
        highlight: Color(red: 0.0, green: 1.0, blue: 0.0),     // Matrix green
        warning: Color(red: 1.0, green: 0.9, blue: 0.0),       // Cyber yellow
        textPrimary: .white,
        textSecondary: .gray
    )
    
    static let minimalLight = AppTheme(
        id: "minimalLight",
        name: "Minimal Light",
        background: Color(red: 0.95, green: 0.95, blue: 0.97), // Soft off-white
        surface: Color.white,
        primaryAccent: Color(red: 0.1, green: 0.1, blue: 0.15), // Very dark blue/black
        secondaryAccent: Color(red: 0.4, green: 0.4, blue: 0.45),
        highlight: Color(red: 0.2, green: 0.8, blue: 0.4),      // Soft green
        warning: Color(red: 0.9, green: 0.6, blue: 0.1),        // Soft orange
        textPrimary: .black,
        textSecondary: .gray
    )
    
    static let allThemes = [cyberpunk, minimalLight]
}
