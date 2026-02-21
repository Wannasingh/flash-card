import SwiftUI

struct BrainDumpReviewView: View {
    @Binding var cards: [BrainDumpCardDto]
    var onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.clear.liquidGlassBackground()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            if cards.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "square.dashed")
                                        .font(.system(size: 50))
                                        .foregroundColor(Theme.textSecondary)
                                    Text("NO CARDS GENERATED")
                                        .cyberpunkFont(size: 18)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .padding(.top, 100)
                            } else {
                                ForEach(cards) { card in
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text("FRONT")
                                                .font(.caption.bold())
                                                .foregroundColor(Theme.neonPink)
                                            Spacer()
                                            Button(action: {
                                                cards.removeAll(where: { $0.id == card.id })
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        
                                        Text(card.frontText)
                                            .foregroundColor(Theme.textPrimary)
                                            .font(.headline)
                                        
                                        Divider().background(Theme.textSecondary.opacity(0.3))
                                        
                                        Text("BACK")
                                            .font(.caption.bold())
                                            .foregroundColor(Theme.neonPink)
                                        
                                        Text(card.backText)
                                            .foregroundColor(Theme.textPrimary)
                                        
                                        if !card.aiMnemonic.isEmpty {
                                            HStack(alignment: .top) {
                                                Image(systemName: "lightbulb.fill")
                                                    .foregroundColor(Theme.cyberYellow)
                                                    .font(.caption)
                                                Text(card.aiMnemonic)
                                                    .font(.caption)
                                                    .italic()
                                                    .foregroundColor(Theme.textSecondary)
                                            }
                                            .padding(.top, 4)
                                        }
                                    }
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                }
                            }
                        }
                        .padding()
                    }
                    
                    if !cards.isEmpty {
                        Button(action: {
                            onComplete()
                        }) {
                            Text("IMPORT \(cards.count) CARDS")
                                .cyberpunkFont(size: 18)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.neonGradient)
                                .cornerRadius(16)
                                .shadow(color: Theme.neonPink.opacity(0.5), radius: 10)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    } else {
                        Button(action: {
                            onComplete()
                        }) {
                            Text("GO BACK")
                                .cyberpunkFont(size: 18)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.textSecondary)
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("REVIEW CARDS")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
