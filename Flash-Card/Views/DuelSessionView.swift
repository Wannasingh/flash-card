import SwiftUI

struct DuelSessionView: View {
    @ObservedObject var viewModel: DuelViewModel
    @State private var currentCardIndex = 0
    @State private var totalCards = 10
    @State private var cards: [CardModel] = [
        CardModel(id: UUID(), frontText: "Stomp Protocol", backText: "Simple Text Oriented Messaging Protocol"),
        CardModel(id: UUID(), frontText: "WebSocket", backText: "Full-duplex communication channel"),
        CardModel(id: UUID(), frontText: "JPA", backText: "Java Persistence API"),
        CardModel(id: UUID(), frontText: "Lombok", backText: "Java library to reduce boilerplate"),
        CardModel(id: UUID(), frontText: "Spring Boot", backText: "Framework for microservices"),
        CardModel(id: UUID(), frontText: "SwiftUI", backText: "Declarative UI for Apple platforms"),
        CardModel(id: UUID(), frontText: "Combine", backText: "Handling asynchronous events in Swift"),
        CardModel(id: UUID(), frontText: "MVVM", backText: "Model-View-ViewModel architecture"),
        CardModel(id: UUID(), frontText: "Lottie", backText: "Vector animation library"),
        CardModel(id: UUID(), frontText: "Vapor", backText: "Swift web framework")
    ]
    
    @State private var isFlipped = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Theme.cyberDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Opponent Progress Bar (Top)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(viewModel.opponentName ?? "Opponent")
                            .font(.caption.bold())
                        Spacer()
                        Text("\(Int(viewModel.opponentProgress * 100))%")
                            .font(.caption.bold())
                    }
                    .foregroundColor(Theme.neonPink)
                    
                    ProgressView(value: viewModel.opponentProgress)
                        .tint(Theme.neonPink)
                        .scaleEffect(y: 2, anchor: .center)
                }
                .padding()
                .background(.ultraThinMaterial)
                
                Spacer()
                
                // My Study Card
                if currentCardIndex < cards.count {
                    ZStack {
                        CardView(card: cards[currentCardIndex], isFlipped: $isFlipped)
                            .padding()
                            .id(currentCardIndex) // Reset view on index change
                        
                        // Reactions overlay
                        ReactionsOverlay(reactions: viewModel.reactions)
                    }
                }
                
                Spacer()
                
                // My Progress (Bottom)
                VStack(spacing: 15) {
                    HStack {
                        // Emoji Reactions
                        HStack(spacing: 15) {
                            EmojiButton(emoji: "🔥") { viewModel.sendReaction("🔥") }
                            EmojiButton(emoji: "🤯") { viewModel.sendReaction("🤯") }
                            EmojiButton(emoji: "💀") { viewModel.sendReaction("💀") }
                        }
                        
                        Spacer()
                        
                        // Done Button
                        Button(action: {
                            nextCard()
                        }) {
                            Text("NEXT CARD")
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Theme.cyanAccent)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                        .disabled(!isFlipped)
                        .opacity(isFlipped ? 1.0 : 0.5)
                    }
                    
                    ProgressView(value: viewModel.myProgress)
                        .tint(Theme.cyanAccent)
                        .scaleEffect(y: 3, anchor: .center)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            
            // Winner Overlay
            if viewModel.duelState == .finished {
                WinnerOverlay(winner: viewModel.winnerName ?? "Unknown") {
                    dismiss()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func nextCard() {
        withAnimation {
            isFlipped = false
            currentCardIndex += 1
            let progress = Double(currentCardIndex) / Double(cards.count)
            viewModel.updateProgress(progress: progress)
        }
    }
}

struct EmojiButton: View {
    let emoji: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.title2)
                .padding(10)
                .background(.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

struct ReactionsOverlay: View {
    let reactions: [String]
    
    var body: some View {
        HStack {
            ForEach(Array(reactions.enumerated()), id: \.offset) { _, reaction in
                Text(reaction)
                    .font(.system(size: 50))
                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
            }
        }
    }
}

struct WinnerOverlay: View {
    let winner: String
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("BATTLE ENDED")
                    .cyberpunkFont(size: 32)
                    .foregroundColor(.white)
                
                Text(winner.uppercased() + " WINS")
                    .cyberpunkFont(size: 40)
                    .foregroundColor(Theme.cyberYellow)
                    .shadow(color: Theme.cyberYellow, radius: 15)
                
                Button("RETURN TO BASE") {
                    onClose()
                }
                .foregroundColor(.black)
                .padding()
                .background(Theme.cyberYellow)
                .cornerRadius(12)
            }
        }
    }
}
