import SwiftUI

struct StudySessionView: View {
    // Top card is the LAST item in the array for SwiftUI's ZStack mapping
    @State private var mockCards: [CardModel] = [
        CardModel(frontText: "Tinder-Style Setup", backText: "Uses DragGesture and Spring Animations to make reviewing feel less like a chore and more like a game."),
        CardModel(frontText: "Dark Mode 🌙", backText: "Reduces eye strain for late-night study sessions (classic Gen-Z trait)."),
        CardModel(frontText: "Gamification", backText: "Earning coins and streaks for swiping consistently.")
    ].reversed()
    
    var body: some View {
        ZStack {
            Theme.cyberDark.ignoresSafeArea()
            
            VStack {
                // Top Action Bar
                HStack {
                    VStack(alignment: .leading) {
                        Text("Session 🔥")
                            .cyberpunkFont(size: 28)
                            .foregroundColor(Theme.textPrimary)
                        Text("Tinder Mode Active")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(mockCards.count)")
                            .cyberpunkFont(size: 24)
                            .foregroundColor(Theme.cyanAccent)
                        Text("CARDS LEFT")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Card Stack Area
                if mockCards.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 70))
                            .foregroundColor(Theme.cyberYellow)
                            .shadow(color: Theme.cyberYellow.opacity(0.5), radius: 20)
                        
                        Text("All Caught Up!")
                            .cyberpunkFont(size: 28)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("You've conquered your due reviews. Enjoy your day! 🍹")
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ZStack {
                        // Render cards. ZStack puts the last item on top.
                        ForEach(mockCards) { card in
                            SwipeCardView(card: card) { quality in
                                handleSwipe(card: card, quality: quality)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Bottom Legend / Instructions
                if !mockCards.isEmpty {
                    HStack {
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.uturn.left.circle.fill")
                                .foregroundColor(Theme.neonPink)
                                .font(.system(size: 36))
                            Text("Forget")
                                .font(.caption.bold())
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.uturn.right.circle.fill")
                                .foregroundColor(Theme.electricBlue)
                                .font(.system(size: 36))
                            Text("Remember")
                                .font(.caption.bold())
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 50)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func handleSwipe(card: CardModel, quality: Int) {
        // Quality 2 = Forget/Left, Quality 5 = Remember/Right
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(quality > 3 ? .success : .warning)
        
        // Remove the top card from the deck array to visually "pop" it out
        withAnimation(.easeOut) {
            mockCards.removeAll { $0.id == card.id }
        }
    }
}

struct StudySessionView_Previews: PreviewProvider {
    static var previews: some View {
        StudySessionView()
    }
}
