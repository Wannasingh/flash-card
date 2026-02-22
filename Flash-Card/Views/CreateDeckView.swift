import SwiftUI

struct CreateDeckView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    
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
            themeManager.currentTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                            .padding(12)
                            .background(themeManager.currentTheme.surface)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("CREATE NEW DECK")
                        .cyberpunkFont(size: 20)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    
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
                                .foregroundColor(themeManager.currentTheme.primaryAccent)
                            
                            TextField("e.g. JLPT N4 Grammar", text: $title)
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                                .padding()
                                .background(themeManager.currentTheme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeManager.currentTheme.textSecondary.opacity(0.3), lineWidth: 1))
                        }
                        
                        // Description Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIPTION")
                                .font(.caption.bold())
                                .foregroundColor(themeManager.currentTheme.primaryAccent)
                            
                            TextEditor(text: $description)
                                .frame(height: 100)
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                                .padding(8)
                                .background(themeManager.currentTheme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeManager.currentTheme.textSecondary.opacity(0.3), lineWidth: 1))
                            // Hack to hide deafult TextEditor background color in SwiftUI
                                .scrollContentBackground(.hidden)
                        }
                        
                        // Brain Dump (AI) Entry Point
                        Button(action: {
                            showBrainDump = true
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(themeManager.currentTheme.warning)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AI BRAIN DUMP")
                                        .cyberpunkFont(size: 16)
                                        .foregroundColor(themeManager.currentTheme.textPrimary)
                                    Text("Paste your notes and let AI generate cards instantly.")
                                        .font(.caption2)
                                        .foregroundColor(themeManager.currentTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeManager.currentTheme.warning.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.top, -8)
                        
                        // Color Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("THEME COLOR")
                                .font(.caption.bold())
                                .foregroundColor(themeManager.currentTheme.primaryAccent)
                            
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
                                .foregroundColor(themeManager.currentTheme.primaryAccent)
                            
                            Toggle(isOn: $isPublic) {
                                VStack(alignment: .leading) {
                                    Text("List on Creator Market")
                                        .font(.headline)
                                        .foregroundColor(themeManager.currentTheme.textPrimary)
                                    Text("Allow other users to discover and purchase your deck.")
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.textSecondary)
                                }
                            }
                            .tint(themeManager.currentTheme.primaryAccent)
                            
                            if isPublic {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("PRICE (COINS)")
                                        .font(.caption.bold())
                                        .foregroundColor(themeManager.currentTheme.textSecondary)
                                    
                                    HStack {
                                        Image(systemName: "bitcoinsign.circle.fill")
                                            .foregroundColor(themeManager.currentTheme.warning)
                                        
                                        TextField("0 = Free", text: $price)
                                            .keyboardType(.numberPad)
                                            .foregroundColor(themeManager.currentTheme.warning)
                                            .font(.headline)
                                    }
                                    .padding()
                                    .background(themeManager.currentTheme.surface)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeManager.currentTheme.warning.opacity(0.3), lineWidth: 1))
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding()
                        .background(themeManager.currentTheme.surface.opacity(0.5))
                        .cornerRadius(16)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                    }
                    .padding()
                    .padding(.bottom, 60) // Safe Area for Bottom Tab
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
                                themeManager.currentTheme.textSecondary
                            } else {
                                themeManager.currentTheme.mainGradient
                            }
                        }
                    )
                    .cornerRadius(16)
                    .shadow(color: title.isEmpty ? .clear : themeManager.currentTheme.primaryAccent.opacity(0.5), radius: 10, y: 5)
                }
                .disabled(title.isEmpty || isSubmitting)
                .padding(.horizontal, 24)
                .padding(.bottom, 30) // Adjusted for tab bar
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
