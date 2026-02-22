import SwiftUI

struct StudySessionView: View {
    @StateObject private var viewModel = StudyViewModel()
    let deckId: Int?
    
    init(deckId: Int? = nil) {
        self.deckId = deckId
    }
    
    var body: some View {
        ZStack {
            Color.clear.liquidGlassBackground()
            
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
                    
                    // Magic Mic Toggle
                    Button(action: {
                        viewModel.toggleVoiceMode()
                    }) {
                        Image(systemName: viewModel.isVoiceModeActive ? "mic.fill" : "mic.slash")
                            .font(.system(size: 24))
                            .foregroundColor(viewModel.isVoiceModeActive ? Theme.neonPink : Theme.textSecondary)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(viewModel.isVoiceModeActive ? Theme.neonPink : Color.clear, lineWidth: 2))
                    }
                    .padding(.leading, 12)
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
                        
                        // Voice Feedback Overlay
                        if let evaluation = viewModel.lastEvaluation {
                            Text(evaluation)
                                .cyberpunkFont(size: 40)
                                .foregroundColor(.white)
                                .padding()
                                .background(Theme.neonPink.opacity(0.8))
                                .cornerRadius(20)
                                .shadow(radius: 10)
                                .transition(.scale.combined(with: .opacity))
                                .zIndex(100)
                        }
                        
                        if viewModel.isVoiceModeActive {
                            VStack {
                                Spacer()
                                HStack {
                                    if viewModel.voiceTutor.isSpeaking {
                                        Label("Tutor is Speaking...", systemImage: "speaker.wave.2.fill")
                                            .foregroundColor(Theme.cyanAccent)
                                    } else if viewModel.voiceTutor.isListening {
                                        Label("Listening for Answer...", systemImage: "waveform.circle.fill")
                                            .foregroundColor(Theme.neonPink)
                                            .symbolEffect(.variableColor.iterative, options: .repeating)
                                    }
                                }
                                .cyberpunkFont(size: 14)
                                .padding()
                                .background(.ultraThinMaterial.opacity(0.8))
                                .cornerRadius(20)
                                .padding(.bottom, 20)
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
        .task {
            await viewModel.fetchDueCards(deckId: deckId)
        }
    }
    
    private func handleSwipe(card: CardModel, quality: Int) {
        // Haptic Feedback based on success
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(quality > 3 ? .success : .warning)
        
        // Pass to ViewModel to remove from UI and Fire to Backend
        viewModel.submitReview(for: card, quality: quality, isGlobalSession: deckId == nil)
    }
}

struct StudySessionView_Previews: PreviewProvider {
    static var previews: some View {
        StudySessionView()
    }
}
