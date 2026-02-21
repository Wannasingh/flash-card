import Foundation
import StoreKit
import Combine
import SwiftUI

@MainActor
class StoreKitManager: ObservableObject {
    @Published var coinProducts: [Product] = []
    @Published var subscriptionProducts: [Product] = []
    @Published var purchasedSubscription: Product?
    
    // Using simple mock IDs for our local StoreKit configuration.
    // In production, these map directly to App Store Connect Product IDs.
    private let coinProductIDs = ["com.genzflashcard.coins.100", "com.genzflashcard.coins.500"]
    private let subProductID = ["com.genzflashcard.sub.plus"]
    
    var updateListenerTask: Task<Void, Error>? = nil
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func requestProducts() async {
        do {
            let coins = try await Product.products(for: coinProductIDs)
            let subs = try await Product.products(for: subProductID)
            
            // Sort by price
            coinProducts = coins.sorted(by: { $0.price < $1.price })
            subscriptionProducts = subs
        } catch {
            print("Failed to fetch products from StoreKit: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            // Deliver the content to the user
            await updateCustomerProductStatus()
            
            // Inform App Store that product was delivered
            await transaction.finish()
            
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check if the Apple signed JWS passed validation
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // Call this inside `init` and whenever we receive a transaction
    func updateCustomerProductStatus() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productType == .autoRenewable {
                    if let sub = subscriptionProducts.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscription = sub
                    }
                }
            } catch {
                print("Transaction failed verification")
            }
        }
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    
                    // If coins (consumable), we can add to backend here.
                    // For now, we finish so it doesn't stay pending.
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
