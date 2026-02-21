import SwiftUI
import AVKit
import SceneKit

// Model for Phase 4 UI mapping
struct CardModel: Identifiable {
    let id: UUID
    let backendId: Int? // Required for API syncing
    let frontText: String
    let backText: String
    let imageUrl: String?
    let videoUrl: String?
    let arModelUrl: String?
    let memeUrl: String?
    let aiMnemonic: String?
    
    init(id: UUID = UUID(), backendId: Int? = nil, frontText: String, backText: String, imageUrl: String? = nil, videoUrl: String? = nil, arModelUrl: String? = nil, memeUrl: String? = nil, aiMnemonic: String? = nil) {
        self.id = id
        self.backendId = backendId
        self.frontText = frontText
        self.backText = backText
        self.imageUrl = imageUrl
        self.videoUrl = videoUrl
        self.arModelUrl = arModelUrl
        self.memeUrl = memeUrl
        self.aiMnemonic = aiMnemonic
    }
}

struct SwipeCardView: View {
    let card: CardModel
    var onSwipe: (Int) -> Void // 5 = Right (Remembered), 2 = Left (Forgot)
    
    @EnvironmentObject var sessionStore: SessionStore
    @State private var offset: CGSize = .zero
    @State private var isShowingBack = false
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            // Dynamic Card Skin Background
            Color.clear
                .cardSkin(sessionStore.userProfile?.activeSkinCode)
                .frame(width: 320, height: 480)
            
            // Text Content
            VStack {
                Spacer()
                
                if isShowingBack, let videoStr = card.videoUrl, let vUrl = URL(string: videoStr) {
                    VideoPlayer(player: player)
                        .frame(height: 180)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        .onAppear {
                            if player == nil {
                                player = AVPlayer(url: vUrl)
                            }
                            player?.play()
                        }
                        .onDisappear {
                            player?.pause()
                            player = nil // Free memory when swiped away
                        }
                } else if isShowingBack, let arStr = card.arModelUrl, let arUrl = URL(string: arStr) {
                    // AR Models are typically lighter when discarded, but we can do the same pattern if needed.
                    SceneView(scene: try? SCNScene(url: arUrl), options: [.autoenablesDefaultLighting, .allowsCameraControl])
                        .frame(height: 180)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                }
                
                Text(isShowingBack ? card.backText : card.frontText)
                    .cyberpunkFont(size: isShowingBack && (card.videoUrl != nil || card.arModelUrl != nil) ? 24 : 32)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    // Added a 3D flip effect feeling when text changes
                    .rotation3DEffect(.degrees(isShowingBack ? 360 : 0), axis: (x: 0, y: 1, z: 0))
                
                if isShowingBack, let mnemonic = card.aiMnemonic, !mnemonic.isEmpty {
                    Text("💡 \(mnemonic)")
                        .font(.subheadline.italic())
                        .foregroundColor(Theme.cyberYellow)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }
                
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
                        // Spring Snap Back to Center (Liquid Glass Physics)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.5, blendDuration: 0.2)) {
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
