import SwiftUI

struct CardEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Core Card Data
    let deckId: Int
    @State private var frontText: String = ""
    @State private var backText: String = ""
    
    // Future Multimedia & AI Fields
    @State private var frontImageUrl: String = ""
    @State private var backImageUrl: String = ""
    @State private var aiMnemonic: String = ""
    
    // UI State
    @State private var isSubmitting = false
    @State private var isGeneratingMnemonic = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        ZStack {
            Theme.cyberDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .padding(10)
                            .background(Theme.cyberCard)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("ADD FLASHCARD")
                        .cyberpunkFont(size: 20)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    // Invisible view for balanced spacing
                    Image(systemName: "xmark").opacity(0).padding(10)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // FRONT END OF CARD
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("FRONT SIDE")
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.cyberYellow)
                                Spacer()
                                Image(systemName: "eye.fill")
                                    .foregroundColor(Theme.textSecondary)
                            }
                            
                            TextEditor(text: $frontText)
                                .frame(height: 120)
                                .font(.body)
                                .foregroundColor(Theme.textPrimary)
                                .padding(8)
                                .background(Theme.cyberCard)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.cyberYellow.opacity(0.3), lineWidth: 1))
                                .scrollContentBackground(.hidden)
                            
                            TextField("Optional Image URL", text: $frontImageUrl)
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .padding(12)
                                .background(Theme.cyberCard.opacity(0.5))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Theme.cyberCard.opacity(0.3))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cyberYellow.opacity(0.1), lineWidth: 1))
                        
                        // AI MNEMONIC SHIELD
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("AI MNEMONIC")
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.electricBlue)
                                Spacer()
                                Button(action: {
                                    Task { await generateMnemonic() }
                                }) {
                                    if isGeneratingMnemonic {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                                    } else {
                                        Image(systemName: "wand.and.stars")
                                            .foregroundColor(Theme.cyberDark)
                                            .padding(8)
                                            .background(Theme.electricBlue)
                                            .clipShape(Circle())
                                    }
                                }
                                .disabled(frontText.isEmpty || isGeneratingMnemonic)
                            }
                            
                            if !aiMnemonic.isEmpty {
                                TextEditor(text: $aiMnemonic)
                                    .frame(height: 80)
                                    .font(.body)
                                    .foregroundColor(Theme.textPrimary)
                                    .padding(8)
                                    .background(Theme.cyberCard)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.electricBlue.opacity(0.3), lineWidth: 1))
                                    .scrollContentBackground(.hidden)
                            } else {
                                Text("Enter FRONT text and tap the wand to generate a memory hook!")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .padding()
                        .background(Theme.cyberCard.opacity(0.3))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.electricBlue.opacity(0.1), lineWidth: 1))
                        
                        
                        // BACK END OF CARD
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("BACK SIDE (ANSWER)")
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.neonPink)
                                Spacer()
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(Theme.textSecondary)
                            }
                            
                            TextEditor(text: $backText)
                                .frame(height: 120)
                                .font(.body)
                                .foregroundColor(Theme.textPrimary)
                                .padding(8)
                                .background(Theme.cyberCard)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.neonPink.opacity(0.3), lineWidth: 1))
                                .scrollContentBackground(.hidden)
                            
                            TextField("Optional Image/Video URL", text: $backImageUrl)
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .padding(12)
                                .background(Theme.cyberCard.opacity(0.5))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Theme.cyberCard.opacity(0.3))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.neonPink.opacity(0.1), lineWidth: 1))
                        
                        
                        // Feedback Messages
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        if let success = successMessage {
                            Text(success)
                                .font(.caption)
                                .foregroundColor(Theme.matrixGreen)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding()
                }
                
                // Submit Button
                Button(action: {
                    Task { await addCard() }
                }) {
                    HStack {
                        if isSubmitting {
                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("SAVE CARD")
                                .cyberpunkFont(size: 20)
                            Image(systemName: "square.and.arrow.down.fill")
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Group {
                            if frontText.isEmpty || backText.isEmpty {
                                Theme.textSecondary
                            } else {
                                Theme.neonGradient
                            }
                        }
                    )
                    .cornerRadius(16)
                    .shadow(color: frontText.isEmpty || backText.isEmpty ? .clear : Theme.neonPink.opacity(0.5), radius: 10, y: 5)
                }
                .disabled(frontText.isEmpty || backText.isEmpty || isSubmitting)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .padding(.top, 10)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func addCard() async {
        guard let token = try? KeychainStore.shared.getString(forKey: "accessToken") else {
            errorMessage = "Authentication token missing."
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await DeckAPI.shared.addCardToDeck(
                token: token,
                deckId: deckId,
                frontContent: frontText,
                backContent: backText,
                frontMediaUrl: frontImageUrl.isEmpty ? nil : frontImageUrl,
                backMediaUrl: backImageUrl.isEmpty ? nil : backImageUrl,
                aiMnemonic: aiMnemonic.isEmpty ? nil : aiMnemonic
            )
            
            successMessage = "Card added successfully!"
            
            // Clear form for next card
            frontText = ""
            backText = ""
            frontImageUrl = ""
            backImageUrl = ""
            aiMnemonic = ""
            
            // Haptic feedback for success
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } catch {
            errorMessage = error.localizedDescription
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        
        isSubmitting = false
    }
    
    private func generateMnemonic() async {
        guard let token = try? KeychainStore.shared.getString(forKey: "accessToken") else {
            errorMessage = "Authentication token missing."
            return
        }
        
        isGeneratingMnemonic = true
        errorMessage = nil
        
        do {
            let generated = try await DeckAPI.shared.generateAiMnemonic(token: token, frontText: frontText)
            aiMnemonic = generated
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        
        isGeneratingMnemonic = false
    }
}

struct CardEditorView_Previews: PreviewProvider {
    static var previews: some View {
        CardEditorView(deckId: 1)
    }
}
