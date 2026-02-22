import SwiftUI

struct SearchView: View {
    @EnvironmentObject var dataStore: AppDataStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    
    var filteredDecks: [DeckModel] {
        if searchText.isEmpty {
            return dataStore.marketplaceDecks
        } else {
            return dataStore.marketplaceDecks.filter { $0.title.localizedCaseInsensitiveContains(searchText) || ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false) }
        }
    }
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.background.ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Text("DISCOVER")
                        .cyberpunkFont(size: 28)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    Spacer()
                }
                .padding()
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    
                    TextField("Search Decks...", text: $searchText)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding()
                .background(themeManager.currentTheme.surface.opacity(0.5))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeManager.currentTheme.primaryAccent.opacity(0.3), lineWidth: 1))
                .padding(.horizontal)
                
                // Content
                if filteredDecks.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "square.stack.3d.up.slash")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        Text("No matching signal found.")
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredDecks) { deck in
                                NavigationLink(destination: DeckDetailView(deck: deck, isOwned: false)) {
                                    SearchDeckRow(deck: deck)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
                }
            }
        }
        .task {
            if dataStore.marketplaceDecks.isEmpty {
                await dataStore.refreshMarketplace()
            }
        }
    }
}

struct SearchDeckRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let deck: DeckModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Mini Cover
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: deck.colorHex))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(deck.title.prefix(1)))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.title)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                
                Text(deck.creatorName)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.primaryAccent)
                
                HStack {
                    Label("\(deck.cardCount)", systemImage: "rectangle.stack")
                    Spacer()
                    Text("\(deck.price) Coins")
                        .foregroundColor(themeManager.currentTheme.warning)
                }
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .font(.system(size: 14))
        }
        .padding()
        .background(themeManager.currentTheme.surface.opacity(0.3))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
