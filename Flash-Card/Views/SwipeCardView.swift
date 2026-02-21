import SwiftUI

// Model for Phase 4 UI mapping
struct CardModel: Identifiable {
    let id: UUID
    let backendId: Int? // Required for API syncing
    let frontText: String
    let backText: String
    
    init(id: UUID = UUID(), backendId: Int? = nil, frontText: String, backText: String) {
        self.id = id
        self.backendId = backendId
        self.frontText = frontText
        self.backText = backText
    }
}

struct SwipeCardView: View {
    let card: CardModel
    var onSwipe: (Int) -> Void // 5 = Right (Remembered), 2 = Left (Forgot)
    
    @State private var offset: CGSize = .zero
    @State private var isShowingBack = false
    
    var body: some View {
        ZStack {
            // Card Background
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Theme.cardGradient)
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Theme.neonPink.opacity(0.3), lineWidth: 2))
                .shadow(color: Theme.neonPink.opacity(0.15), radius: 20, x: 0, y: 15)
            
            // Text Content
            VStack {
                Spacer()
                Text(isShowingBack ? card.backText : card.frontText)
                    .cyberpunkFont(size: 32)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    // Added a 3D flip effect feeling when text changes
                    .rotation3DEffect(.degrees(isShowingBack ? 360 : 0), axis: (x: 0, y: 1, z: 0))
                
                Spacer()
                
                HStack {
                    Image(systemName: "hand.tap.fill")
                    Text(isShowingBack ? "TAP TO HIDE" : "TAP TO REVEAL")
                }
                .font(.caption.bold())
                .foregroundColor(Theme.textSecondary)
                .padding(.bottom, 24)
            }
        }
        .frame(width: 320, height: 480)
        // 3D rotation based on drag offset (left/right tilt)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .offset(x: offset.width, y: abs(offset.width) * 0.1) // Slight drop when dragged horizontally
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                }
                .onEnded { gesture in
                    let swipeThreshold: CGFloat = 100
                    if gesture.translation.width > swipeThreshold {
                        // Swiped Right - Mastered
                        swipe(direction: 5)
                    } else if gesture.translation.width < -swipeThreshold {
                        // Swiped Left - Forgot
                        swipe(direction: 2)
                    } else {
                        // Spring Snap Back to Center
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            offset = .zero
                        }
                    }
                }
        )
        // Flip Gesture
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isShowingBack.toggle()
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
    
    private func swipe(direction: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            offset.width = direction == 5 ? 500 : -500 // Fly off screen
        }
        
        // Brief delay before removing to let the animation finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSwipe(direction)
        }
    }
}

struct SwipeCardView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeCardView(card: CardModel(frontText: "Spaced Repetition System", backText: "A method to review flashcards at increasing intervals to combat the forgetting curve.")) { _ in }
            .preferredColorScheme(.dark)
            .background(Theme.cyberDark.ignoresSafeArea())
    }
}
