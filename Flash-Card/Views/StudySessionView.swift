import SwiftUI

struct StudySessionView: View {
    @StateObject private var viewModel = StudyViewModel()
    
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
                        Text("Spaced Repetition Active")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(viewModel.dueCards.count)")
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
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .tint(Theme.neonPink)
                } else if viewModel.dueCards.isEmpty {
                    StudySessionSummaryView()
                } else {
                    ZStack {
                        // Render cards. ZStack puts the last item on top.
                        ForEach(viewModel.dueCards) { card in
                            SwipeCardView(card: card) { quality in
                                handleSwipe(card: card, quality: quality)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Bottom Legend / Instructions
                if !viewModel.dueCards.isEmpty {
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
        .onAppear {
            Task {
                await viewModel.fetchDueCards()
            }
        }
    }
    
    private func handleSwipe(card: CardModel, quality: Int) {
        // Haptic Feedback based on success
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(quality > 3 ? .success : .warning)
        
        // Pass to ViewModel to remove from UI and Fire to Backend
        viewModel.submitReview(for: card, quality: quality)
    }
}

struct StudySessionView_Previews: PreviewProvider {
    static var previews: some View {
        StudySessionView()
    }
}
