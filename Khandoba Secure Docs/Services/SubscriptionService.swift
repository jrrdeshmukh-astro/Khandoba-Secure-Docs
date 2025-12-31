//
//  SubscriptionService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import Foundation
import Combine
import StoreKit
import SwiftData

@MainActor
final class SubscriptionService: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    private var updateListenerTask: Task<Void, Error>?
    
    // In-app purchases removed - app is now a paid app (one-time purchase)
    // No product IDs needed
    private let productIDs: [String] = []
    
    init() {
        updateListenerTask = listenForTransactions()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            products = try await Product.products(for: productIDs)
            print(" Loaded \(products.count) subscription products")
            
            for product in products {
                print("   - \(product.displayName): \(product.displayPrice)")
            }
        } catch {
            print(" Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> PurchaseResult {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            // Update user subscription status
            await updateSubscriptionStatus(transaction: transaction)
            
            // Finish transaction
            await transaction.finish()
            
            return .success
            
        case .userCancelled:
            return .cancelled
            
        case .pending:
            return .pending
            
        @unknown default:
            return .failed
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await AppStore.sync()
        
        await updatePurchasedProducts()
    }
    
    // MARK: - Check Subscription Status
    
    func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.revocationDate == nil {
                purchasedIDs.insert(transaction.productID)
                
                // Update subscription status in database
                await updateSubscriptionStatus(transaction: transaction)
            }
        }
        
        self.purchasedProductIDs = purchasedIDs
        
        // Update overall status
        if purchasedIDs.isEmpty {
            subscriptionStatus = .notSubscribed
        } else {
            subscriptionStatus = .active
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }
                
                await self.updateSubscriptionStatus(transaction: transaction)
                await transaction.finish()
            }
        }
    }
    
    // MARK: - Update User Subscription
    
    private func updateSubscriptionStatus(transaction: Transaction) async {
        guard let modelContext = modelContext else { return }
        
        // Fetch current user
        let userDescriptor = FetchDescriptor<User>()
        guard let users = try? modelContext.fetch(userDescriptor),
              let currentUser = users.first else {
            return
        }
        
        // Update user subscription status
        currentUser.isPremiumSubscriber = true
        
        // Calculate expiry date
        if let expirationDate = transaction.expirationDate {
            currentUser.subscriptionExpiryDate = expirationDate
        } else {
            // No expiry = lifetime or non-renewing
            currentUser.subscriptionExpiryDate = Date.distantFuture
        }
        
        try? modelContext.save()
        
        print("✅ Subscription updated: \(transaction.productID)")
        print("   User isPremiumSubscriber: \(currentUser.isPremiumSubscriber)")
        print("   Subscription expiry: \(currentUser.subscriptionExpiryDate?.description ?? "none")")
        
        // Notify that subscription status changed
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Subscription Info
    
    func getActiveSubscription() async -> Product? {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.revocationDate == nil {
                return products.first { $0.id == transaction.productID }
            }
        }
        
        return nil
    }
}

// MARK: - Models

enum SubscriptionStatus {
    case unknown
    case notSubscribed
    case active
    case expired
    case inGracePeriod
}

enum PurchaseResult {
    case success
    case cancelled
    case pending
    case failed
}

enum SubscriptionError: LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Failed to verify purchase with App Store"
        case .productNotFound:
            return "Subscription product not found"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .userCancelled:
            return "Purchase was cancelled"
        }
    }
}
