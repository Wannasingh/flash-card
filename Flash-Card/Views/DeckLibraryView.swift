import SwiftUI


struct DeckLibraryView: View {
    @EnvironmentObject var dataStore: AppDataStore
    @EnvironmentObject var themeManager: ThemeManager
    
    // Vertical Paging for owned decks
    var body: some View {
        ZStack {
            // Background
            themeManager.currentTheme.background.ignoresSafeArea()
            
            if dataStore.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.primaryAccent))
                    Text("Loading Arsenal...")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .padding(.top, 10)
                }
            } else if let errorMessage = dataStore.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.currentTheme.warning)
                    Text(errorMessage)
                        .padding()
                        .multilineTextAlignment(.center)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    Button("Retry") {
                        Task { await dataStore.refreshLibrary() }
                    }
                    .padding()
                    .background(themeManager.currentTheme.primaryAccent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else if dataStore.libraryDecks.isEmpty {
                // Empty State
                VStack(spacing: 20) {
                    Image(systemName: "square.stack.3d.up.slash.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    Text("Your Arsenal is Empty")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    Text("Go to the Market to find decks or create your own.")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    NavigationLink(destination: CreateDeckView()) {
                        Text("Create New Deck")
                            .fontWeight(.bold)
                            .padding()
                            .background(themeManager.currentTheme.primaryAccent)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            } else {
                // Bookshelf Layout
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 20)], spacing: 30) {
                        ForEach(dataStore.libraryDecks) { deck in
                            NavigationLink(destination: DeckDetailView(deck: deck, isOwned: true)) {
                                LibraryBookView(deck: deck)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Add New Deck Book Placeholder
                        NavigationLink(destination: CreateDeckView()) {
                            CreateNewBookView()
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(20)
                    .padding(.bottom, 80) // Space for bottom tab bar
                }
                
                // Overlay connectivity status
                ConnectivityBanner()
            }
        }
        .task {
            if dataStore.libraryDecks.isEmpty {
                await dataStore.refreshLibrary()
            }
        }
    }
    
}

// Book-like UI for a Deck
struct LibraryBookView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let deck: DeckModel
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Book cover
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: deck.colorHex), themeManager.currentTheme.background]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    if let imageUrlStr = deck.coverImageUrl, let imageUrl = URL(string: imageUrlStr) {
                        AsyncImage(url: imageUrl) { phase in
                            if let image = phase.image {
                                image.resizable()
                                     .scaledToFill()
                                     .overlay(Color.black.opacity(0.4))
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.5), radius: 5, x: 4, y: 4)
            
            // Text Content on Book
            VStack(alignment: .leading, spacing: 5) {
                Text(deck.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 10)
                
                Spacer()
                
                Text("\(deck.cardCount) Cards")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Divider().background(Color.white.opacity(0.3))
                
                Text(deck.creatorName)
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.highlight)
                    .lineLimit(1)
            }
            .padding(10)
            
            // Book Spine effect
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 5)
                .padding(.leading, 8)
        }
        .frame(height: 160) // Book aspect ratio roughly 2:3 (110x160)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// Add New Book Placeholder
struct CreateNewBookView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .frame(height: 160)
            
            VStack {
                Image(systemName: "plus")
                    .font(.largeTitle)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                Text("New Deck")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .padding(.top, 5)
            }
        }
    }
}
