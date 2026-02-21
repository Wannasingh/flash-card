import SwiftUI

struct AuraDecorator: ViewModifier {
    let auraCode: String?
    
    func body(content: Content) -> some View {
        ZStack {
            if let code = auraCode {
                auraEffect(for: code)
            }
            content
        }
    }
    
    @ViewBuilder
    private func auraEffect(for code: String) -> some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date.timeIntervalSince1970
            
            switch code {
            case "AURA_CYAN":
                Circle()
                    .stroke(Theme.cyanAccent.opacity(0.5), lineWidth: 4)
                    .blur(radius: 4)
                    .scaleEffect(1.1)
                    .shadow(color: Theme.cyanAccent, radius: 10)
            case "AURA_NEON_PINK":
                Circle()
                    .stroke(Color.pink.opacity(0.6), lineWidth: 4)
                    .blur(radius: 2)
                    .scaleEffect(1.15)
                    .shadow(color: Color.pink, radius: 15)
                    .hueRotation(.degrees(Double(Int(now * 10) % 360)))
            default:
                EmptyView()
            }
        }
    }
}

extension View {
    func aura(_ code: String?) -> some View {
        self.modifier(AuraDecorator(auraCode: code))
    }
}
