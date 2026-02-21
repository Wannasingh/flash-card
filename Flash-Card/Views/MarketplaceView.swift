import SwiftUI

struct MarketplaceView: View {
    @State private var trendingDecks: [DeckModel] = [
        DeckModel(title: "Cyber Security 101", creatorName: "Hak0r", cardCount: 200, price: 500, colorHex: "FF0080"),
        DeckModel(title: "Anatomy of the Heart", creatorName: "Dr. MedSchool", cardCount: 75, price: 300, colorHex: "0063FF"),
        DeckModel(title: "Mastering Python", creatorName: "CodeNinja", cardCount: 150, price: 800, colorHex: "FFE600"),
        DeckModel(title: "JLPT N4 Grammar", creatorName: "Sensei Cyber", cardCount: 120, price: 400, colorHex: "00E5FF")
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
                        
                        // Header Banner
                        ZStack(alignment: .leading) {
                            Theme.neonGradient
                                .cornerRadius(20)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Creator Market")
                                        .cyberpunkFont(size: 24)
                                        .foregroundColor(Theme.textPrimary)
                                    Text("Discover top decks from the community. Spend coins to unlock.")
                                        .font(.caption)
                                        .foregroundColor(Theme.textPrimary.opacity(0.8))
                                }
                                Spacer()
                                Image(systemName: "cart.fill.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .padding()
                        }
                        .frame(height: 120)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Section Title
                        HStack {
                            Text("Trending Now 🔥")
                                .cyberpunkFont(size: 22)
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Button("See All") { }
                                .font(.caption.bold())
                                .foregroundColor(Theme.neonPink)
                        }
                        .padding(.horizontal)
                        
                        // Discover Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(trendingDecks) { deck in
                                DeckCardView(deck: deck, isOwned: false)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarHidden(true)
        }
    }
}

struct MarketplaceView_Previews: PreviewProvider {
    static var previews: some View {
        MarketplaceView()
    }
}
