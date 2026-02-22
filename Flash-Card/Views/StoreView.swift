import SwiftUI

struct StoreView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sessionStore: SessionStore
    @State private var items: [StoreItem] = []
    @State private var ownedItemCodes: Set<String> = []
    @State private var isLoading = true
    @State private var selectedItem: StoreItem?
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.cyberDark.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(Theme.cyanAccent)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {
                            // Header
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("AURA STORE")
                                        .font(.system(size: 32, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("Customize your status")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                CoinBadge(count: sessionStore.userProfile?.coins ?? 0)
                            }
                            .padding(.horizontal)
                            
                            // Items Grid
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(items) { item in
                                    StoreItemCard(item: item, isOwned: isOwned(item))
                                        .onTapGesture {
                                            selectedItem = item
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .task {
            await loadData()
        }
        .sheet(item: $selectedItem) { item in
            StoreItemDetailView(item: item, isOwned: isOwned(item)) {
                await loadData()
            }
        }
    }
    
    @MainActor
    private func loadData() async {
        do {
            async let itemsTask = StoreAPI.shared.getItems()
            async let inventoryTask = StoreAPI.shared.getInventory()
            
            let (fetchedItems, inventory) = try await (itemsTask, inventoryTask)
            
            self.items = fetchedItems
            self.ownedItemCodes = Set(inventory.map { $0.code })
            isLoading = false
        } catch {
            print("Failed to load store: \(error)")
            isLoading = false
        }
    }
    
    private func isOwned(_ item: StoreItem) -> Bool {
        return ownedItemCodes.contains(item.code)
    }
}

struct StoreItemCard: View {
    let item: StoreItem
    let isOwned: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 120)
                
                if item.type == .aura {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .aura(item.code)
                } else {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.cyanAccent)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    if isOwned {
                        Text("OWNED")
                            .font(.caption.bold())
                            .foregroundColor(Theme.cyanAccent)
                    } else {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                        Text("\(item.price)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct StoreItemDetailView: View {
    let item: StoreItem
    let isOwned: Bool
    let onAction: () async -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sessionStore: SessionStore
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            Theme.cyberDark.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Preview
                VStack(spacing: 15) {
                    Text("PREVIEW")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    
                    if item.type == .aura {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .aura(item.code)
                    } else {
                        // Card skin preview
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Theme.cyanAccent.opacity(0.2))
                            .frame(width: 120, height: 180)
                            .overlay(
                                Text("SKIN")
                                    .fontWeight(.black)
                                    .foregroundColor(Theme.cyanAccent)
                            )
                    }
                }
                .padding(.top, 40)
                
                VStack(spacing: 10) {
                    Text(item.name)
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text(item.type == .aura ? "Profile Aura Effect" : "Study Card Skin")
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isOwned {
                    Button(action: { 
                        Task {
                            try? await StoreAPI.shared.equipItem(code: item.code)
                            await onAction()
                            dismiss()
                        }
                    }) {
                        Text("EQUIP ITEM")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.cyanAccent)
                            .foregroundColor(.black)
                            .cornerRadius(15)
                    }
                } else {
                    Button(action: {
                        Task {
                            isProcessing = true
                            try? await StoreAPI.shared.purchaseItem(code: item.code)
                            await onAction()
                            isProcessing = false
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.yellow)
                            Text("BUY FOR \(item.price) COINS")
                        }
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.cyanAccent)
                        .foregroundColor(.black)
                        .cornerRadius(15)
                    }
                    .disabled(isProcessing || (sessionStore.userProfile?.coins ?? 0) < item.price)
                    .opacity((sessionStore.userProfile?.coins ?? 0) < item.price ? 0.5 : 1)
                }
            }
            .padding(30)
        }
    }
}
