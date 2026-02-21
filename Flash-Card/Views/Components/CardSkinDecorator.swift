import SwiftUI

struct CardSkinDecorator: ViewModifier {
    let skinCode: String?
    
    func body(content: Content) -> some View {
        ZStack {
            if let code = skinCode {
                skinBackground(for: code)
            } else {
                defaultBackground
            }
            content
        }
    }
    
    @ViewBuilder
    private var defaultBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.3), lineWidth: 1))
            .shadow(color: Theme.neonPink.opacity(0.15), radius: 20, x: 0, y: 15)
    }
    
    @ViewBuilder
    private func skinBackground(for code: String) -> some View {
        switch code {
        case "SKIN_RETRO_GRID":
            ZStack {
                Color.black
                RetroGridView()
                    .opacity(0.3)
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.pink.opacity(0.5), lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: Color.pink.opacity(0.3), radius: 15)
        case "SKIN_CYBER_GRADIENT":
            RoundedRectangle(cornerRadius: 30)
                .fill(LinearGradient(colors: [Theme.cyanAccent.opacity(0.3), Theme.neonPink.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.5), lineWidth: 1))
                .shadow(color: Theme.cyanAccent.opacity(0.4), radius: 20)
        default:
            defaultBackground
        }
    }
}

struct RetroGridView: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 20
            for x in stride(from: 0, through: size.width, by: step) {
                context.stroke(Path(CGRect(x: x, y: 0, width: 0.5, height: size.height)), with: .color(.pink))
            }
            for y in stride(from: 0, through: size.height, by: step) {
                context.stroke(Path(CGRect(x: 0, y: y, width: size.width, height: 0.5)), with: .color(.pink))
            }
        }
    }
}

extension View {
    func cardSkin(_ code: String?) -> some View {
        self.modifier(CardSkinDecorator(skinCode: code))
    }
}
