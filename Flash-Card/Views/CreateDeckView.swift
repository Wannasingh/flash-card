import SwiftUI

struct CreateDeckView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var price: String = "0"
    @State private var isPublic: Bool = false
    @State private var selectedColorHex: String = "00E5FF" // Default Cyan
    
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showBrainDump = false
    @State private var generatedCards: [BrainDumpCardDto] = []
    
    // Cyberpunk Color Palette for Selection
    let colorOptions = [
        "00E5FF", // Cyan
        "FF0080", // Neon Pink
        "FFE600", // Cyber Yellow
        "00FF00", // Matrix Green
        "8A2BE2", // Deep Purple
        "FF4500"  // Blaze Orange
    ]
    
    var body: some View {
        ZStack {
            Color.clear.liquidGlassBackground()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .padding(12)
                            .background(Theme.cyberCard)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("CREATE NEW DECK")
                        .cyberpunkFont(size: 20)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    // Invisible view for balanced spacing
                    Image(systemName: "xmark").opacity(0).padding(12)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DECK TITLE")
                                .font(.caption.bold())
                                .foregroundColor(Theme.neonPink)
                            
                            TextField("e.g. JLPT N4 Grammar", text: $title)
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                                .padding()
                                .background(Theme.cyberCard)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.textSecondary.opacity(0.3), lineWidth: 1))
                        }
                        
                        // Description Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIPTION")
                                .font(.caption.bold())
                                .foregroundColor(Theme.neonPink)
                            
                            TextEditor(text: $description)
                                .frame(height: 100)
                                .font(.body)
                                .foregroundColor(Theme.textPrimary)
                                .padding(8)
                                .background(Theme.cyberCard)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.textSecondary.opacity(0.3), lineWidth: 1))
                            // Hack to hide deafult TextEditor background color in SwiftUI
                                .scrollContentBackground(.hidden)
                        }
                        
                        // Brain Dump (AI) Entry Point
                        Button(action: {
                            showBrainDump = true
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(Theme.cyberYellow)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AI BRAIN DUMP")
                                        .cyberpunkFont(size: 16)
                                        .foregroundColor(Theme.textPrimary)
                                    Text("Paste your notes and let AI generate cards instantly.")
                                        .font(.caption2)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.cyberYellow.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.top, -8)
                        
                        // Color Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("THEME COLOR")
                                .font(.caption.bold())
                                .foregroundColor(Theme.neonPink)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                                ForEach(colorOptions, id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColorHex == hex ? 3 : 0)
                                        )
                                        .shadow(color: Color(hex: hex).opacity(selectedColorHex == hex ? 0.8 : 0), radius: 10)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                selectedColorHex = hex
                                            }
                                        }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // Marketplace Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("MARKETPLACE SETTINGS")
                                .font(.caption.bold())
                                .foregroundColor(Theme.neonPink)
                            
                            Toggle(isOn: $isPublic) {
                                VStack(alignment: .leading) {
                                    Text("List on Creator Market")
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                    Text("Allow other users to discover and purchase your deck.")
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                            .tint(Theme.neonPink)
                            
                            if isPublic {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("PRICE (COINS)")
                                        .font(.caption.bold())
                                        .foregroundColor(Theme.textSecondary)
                                    
                                    HStack {
                                        Image(systemName: "bitcoinsign.circle.fill")
                                            .foregroundColor(Theme.cyberYellow)
                                        
                                        TextField("0 = Free", text: $price)
                                            .keyboardType(.numberPad)
                                            .foregroundColor(Theme.cyberYellow)
                                            .font(.headline)
                                    }
                                    .padding()
                                    .background(Theme.cyberCard)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.cyberYellow.opacity(0.3), lineWidth: 1))
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding()
                        .background(Theme.cyberCard.opacity(0.5))
                        .cornerRadius(16)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                    }
                    .padding()
                }
                
                // Submit Button
                Button(action: {
                    Task { await createDeck() }
                }) {
                    HStack {
                        if isSubmitting {
                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("CREATE DECK")
                                .cyberpunkFont(size: 20)
                            Image(systemName: "hammer.fill")
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Group {
                            if title.isEmpty {
                                Theme.textSecondary
                            } else {
                                Theme.neonGradient
                            }
                        }
                    )
                    .cornerRadius(16)
                    .shadow(color: title.isEmpty ? .clear : Theme.neonPink.opacity(0.5), radius: 10, y: 5)
                }
                .disabled(title.isEmpty || isSubmitting)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .padding(.top, 10)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showBrainDump) {
            BrainDumpView(generatedCards: $generatedCards)
        }
    }
    
    private func createDeck() async {
        guard let token = try? KeychainStore.shared.getString(forKey: "accessToken") else {
            errorMessage = "You must be logged in to create a deck."
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            let finalPrice = isPublic ? (Int(price) ?? 0) : 0
            _ = try await DeckAPI.shared.createDeck(
                token: token,
                title: title,
                description: description,
                customColorHex: selectedColorHex,
                priceCoins: finalPrice,
                isPublic: isPublic,
                cards: generatedCards.isEmpty ? nil : generatedCards
            )
            
            isSubmitting = false
            presentationMode.wrappedValue.dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
        }
    }
}

struct CreateDeckView_Previews: PreviewProvider {
    static var previews: some View {
        CreateDeckView()
    }
}
