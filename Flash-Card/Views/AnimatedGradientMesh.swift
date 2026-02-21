import SwiftUI

struct AnimatedGradientMesh: View {
    @State private var start = UnitPoint(x: 0, y: -2)
    @State private var end = UnitPoint(x: 4, y: 0)
    
    // We use our signature Cyberpunk theme colors but blended dynamically
    let colors = [Theme.cyberDark, Theme.electricBlue.opacity(0.6), Theme.neonPink.opacity(0.4), Theme.cyberDark]
    
    var body: some View {
        ZStack {
            // Deep space background
            Theme.cyberDark.ignoresSafeArea()
            
            // Lava lamp style morphing blobs
            LinearGradient(gradient: Gradient(colors: colors), startPoint: start, endPoint: end)
                .animation(Animation.easeInOut(duration: 10).repeatForever(autoreverses: true).speed(0.5), value: start)
                .onAppear {
                    self.start = UnitPoint(x: 4, y: 0)
                    self.end = UnitPoint(x: 0, y: 2)
                    self.start = UnitPoint(x: -4, y: 20)
                    self.end = UnitPoint(x: 4, y: 0)
                }
                .blendMode(.screen)
                .opacity(0.8)
                .blur(radius: 60) // High blur creates that liquid mesh aesthetic
                .ignoresSafeArea()
        }
    }
}

// Background Modifier for easy injection into any view
struct LiquidGlassBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            AnimatedGradientMesh()
            content
        }
    }
}

extension View {
    func liquidGlassBackground() -> some View {
        self.modifier(LiquidGlassBackgroundModifier())
    }
}
