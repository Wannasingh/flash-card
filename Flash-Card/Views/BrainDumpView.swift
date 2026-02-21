import SwiftUI

struct BrainDumpView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var generatedCards: [BrainDumpCardDto]
    
    @State private var rawText: String = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showReview = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.clear.liquidGlassBackground()
                
                VStack(spacing: 20) {
                    Text("PASTE YOUR NOTES")
                        .cyberpunkFont(size: 24)
                        .foregroundColor(Theme.textPrimary)
                        .padding(.top)
                    
                    Text("AI will scan your text and extract key facts as ready-to-use flashcards.")
                        .font(.body)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    TextEditor(text: $rawText)
                        .frame(maxHeight: .infinity)
                        .font(.body)
                        .foregroundColor(Theme.textPrimary)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cyberYellow.opacity(0.3), lineWidth: 1))
                        .padding(.horizontal)
                        .scrollContentBackground(.hidden)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        Task { await generateCards() }
                    }) {
                        HStack {
                            if isGenerating {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("ANALYZING...")
                            } else {
                                Text("GENERATE FLASHCARDS")
                                Image(systemName: "sparkles")
                            }
                        }
                        .cyberpunkFont(size: 18)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Group {
                                if rawText.count < 20 {
                                    Color.gray
                                } else {
                                    Theme.neonGradient
                                }
                            }
                        )
                        .cornerRadius(16)
                        .shadow(color: rawText.count < 20 ? .clear : Theme.neonPink.opacity(0.5), radius: 10)
                    }
                    .disabled(rawText.count < 20 || isGenerating)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.textPrimary)
                }
            }
            .sheet(isPresented: $showReview) {
                BrainDumpReviewView(cards: $generatedCards) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func generateCards() async {
        guard let token = try? KeychainStore.shared.getString(forKey: "accessToken") else {
            errorMessage = "Authentication error."
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        do {
            let cards = try await DeckAPI.shared.brainDump(token: token, text: rawText)
            generatedCards = cards
            isGenerating = false
            showReview = true
        } catch {
            errorMessage = error.localizedDescription
            isGenerating = false
        }
    }
}
