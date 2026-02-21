import SwiftUI

struct CardView: View {
    let card: CardModel
    @Binding var isFlipped: Bool
    
    var body: some View {
        ZStack {
            // Front side
            CardSideView(text: card.frontText, color: Theme.cyanAccent)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            
            // Back side
            CardSideView(text: card.backText, color: Theme.neonPink)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isFlipped.toggle()
            }
        }
    }
}

struct CardSideView: View {
    let text: String
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(.ultraThinMaterial)
            .frame(width: 320, height: 480)
            .overlay(
                VStack {
                    Text(text)
                        .cyberpunkFont(size: 32)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(30)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(color.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: color.opacity(0.3), radius: 20)
    }
}
