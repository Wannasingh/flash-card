import SwiftUI

// Mock model for Phase 5 UI before hooking up APIs
struct DeckModel: Identifiable {
    let id = UUID()
    let title: String
    let creatorName: String
    let cardCount: Int
    let price: Int // 0 if free/owned
    let colorHex: String
}

struct DeckLibraryView: View {
    @State private var ownedDecks: [DeckModel] = [
        DeckModel(title: "Japanese N5 Vocab", creatorName: "Sensei Cyber", cardCount: 150, price: 0, colorHex: "00E5FF"),
        DeckModel(title: "React Native Basics", creatorName: "DevMaster", cardCount: 45, price: 0, colorHex: "FF0080"),
        DeckModel(title: "Historical Dates (World War 2)", creatorName: "HistoryGeek", cardCount: 88, price: 0, colorHex: "FFE600")
    ]
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.cyberDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // User Stats Header
                        HStack {
                            Text("Your Arsenal")
                                .cyberpunkFont(size: 28)
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("\(ownedDecks.count) Decks")
                                .font(.headline)
                                .foregroundColor(Theme.cyanAccent)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Grid of Decks
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(ownedDecks) { deck in
                                DeckCardView(deck: deck, isOwned: true)
                            }
                            
                            // "Create New" Button Placeholder
                            Button(action: {
                                print("Create new deck tapped")
                            }) {
                                VStack {
                                    Image(systemName: "plus.app.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.neonPink)
                                    Text("New Deck")
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                        .padding(.top, 8)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Theme.cyberCard)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                        .foregroundColor(Theme.neonPink.opacity(0.5))
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Library")
            .navigationBarHidden(true)
        }
    }
}

struct DeckCardView: View {
    let deck: DeckModel
    let isOwned: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            // Cover Image Placeholder (Gradient based on hex)
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: deck.colorHex).opacity(0.8))
                    .frame(height: 120)
                
                if !isOwned {
                    HStack {
                        Spacer()
                        VStack {
                            HStack(spacing: 4) {
                                Text("\(deck.price)")
                                    .fontWeight(.bold)
                                Image(systemName: "bitcoinsign.circle.fill")
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                            .foregroundColor(Theme.cyberYellow)
                            .padding(8)
                        }
                    }
                }
            }
            
            // Text Info
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.title)
                    .cyberpunkFont(size: 16)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)
                
                Text("by \(deck.creatorName)")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                
                HStack {
                    Image(systemName: "square.stack.3d.up.fill")
                        .foregroundColor(Theme.cyanAccent)
                    Text("\(deck.cardCount) cards")
                        .font(.caption2.bold())
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .background(Theme.cyberCard)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1))
        .shadow(color: Color(hex: deck.colorHex).opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// Helper for Color Hex (Used in mocking covers)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct DeckLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        DeckLibraryView()
    }
}
