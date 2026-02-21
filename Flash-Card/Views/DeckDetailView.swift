import SwiftUI

struct DeckDetailView: View {
    let deck: DeckModel
    let isOwned: Bool
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isAcquiring = false
    @State private var acquireError: String?
    @State private var hasAcquired = false // local override after purchase
    @State private var showingCardEditor = false
    
    // Stats for UI before API hookup
    let averageRating: Double = 4.8
    let reviewCount: Int = 124
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.cyberDark.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header Image / Gradient
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(Color(hex: deck.colorHex).opacity(0.8))
                            .frame(height: 250)
                            .overlay(
                                LinearGradient(colors: [.clear, Theme.cyberDark], startPoint: .top, endPoint: .bottom)
                            )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(deck.title)
                                .cyberpunkFont(size: 32)
                                .foregroundColor(Theme.textPrimary)
                                .shadow(color: .black, radius: 10)
                            
                            HStack {
                                Image(systemName: "person.crop.circle.fill")
                                Text("Creator: \(deck.creatorName)")
                                    .font(.subheadline)
                            }
                            .foregroundColor(Theme.textSecondary)
                        }
                        .padding()
                    }
                    
                    // Stats Row
                    HStack(spacing: 30) {
                        VStack {
                            Text("\(deck.cardCount)")
                                .cyberpunkFont(size: 24)
                                .foregroundColor(Theme.neonPink)
                            Text("Cards")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        VStack {
                            HStack(spacing: 4) {
                                Text("\(String(format: "%.1f", averageRating))")
                                    .cyberpunkFont(size: 24)
                                    .foregroundColor(Theme.cyberYellow)
                                Image(systemName: "star.fill")
                                    .foregroundColor(Theme.cyberYellow)
                                    .font(.system(size: 14))
                            }
                            Text("(\(reviewCount) Reviews)")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .padding(.vertical, 24)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About this Deck")
                            .cyberpunkFont(size: 20)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(deck.description ?? "No description provided for this deck.")
                            .font(.body)
                            .foregroundColor(Theme.textPrimary.opacity(0.8))
                            .lineSpacing(6)
                            
                        if let error = acquireError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 10)
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 100)
                }
            }
            
            // Back Button Overlay
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 10)
            
            // Bottom Action Bar
            VStack {
                Spacer()
                VStack {
                    if isOwned || hasAcquired {
                        HStack(spacing: 16) {
                            Button(action: {
                                showingCardEditor = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Theme.cyberYellow)
                                    .padding()
                                    .background(Theme.cyberCard)
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cyberYellow.opacity(0.3), lineWidth: 1))
                            }
                            
                            Button(action: {
                                // In a real flow, this could set the Global Current Deck ID
                                // and jump back to the Study Tab
                                print("Start Studying Deck!")
                            }) {
                                Text("STUDY DECK")
                                    .cyberpunkFont(size: 20)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.neonGradient)
                                    .cornerRadius(16)
                                    .shadow(color: Theme.neonPink.opacity(0.5), radius: 10, y: 5)
                            }
                        }
                    } else {
                        Button(action: {
                            Task { await handleAcquire() }
                        }) {
                            HStack {
                                if isAcquiring {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Text("UNLOCK FOR \(deck.price)")
                                        .cyberpunkFont(size: 18)
                                    Image(systemName: "bitcoinsign.circle.fill")
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.cyberYellow)
                            .cornerRadius(16)
                            .shadow(color: Theme.cyberYellow.opacity(0.4), radius: 10, y: 5)
                        }
                        .disabled(isAcquiring)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .padding(.top, 20)
                .background(
                    LinearGradient(colors: [Theme.cyberDark.opacity(0.0), Theme.cyberDark], startPoint: .top, endPoint: .bottom)
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCardEditor) {
            if let targetId = deck.backendId {
                CardEditorView(deckId: targetId)
            } else {
                // Fallback for mocked decks without ID
                Text("Error: Deck ID missing. Cannot add cards.")
                    .foregroundColor(Theme.neonPink)
                    .background(Theme.cyberDark)
            }
        }
    }
    
    private func handleAcquire() async {
        guard let token = try? KeychainStore.shared.getString(forKey: "accessToken"),
              let backendId = deck.backendId else {
            acquireError = "You must be logged in to construct a deck."
            return
        }
        
        isAcquiring = true
        acquireError = nil
        
        do {
            try await DeckAPI.shared.acquireDeck(token: token, deckId: backendId)
            hasAcquired = true // Flip UI state immediately
        } catch {
            acquireError = error.localizedDescription
        }
        
        isAcquiring = false
    }
}

struct DeckDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DeckDetailView(
            deck: DeckModel(
                backendId: nil,
                title: "Cyber Security 101",
                creatorName: "Hak0r",
                cardCount: 200,
                price: 500,
                colorHex: "FF0080",
                description: nil
            ),
            isOwned: false
        )
    }
}
