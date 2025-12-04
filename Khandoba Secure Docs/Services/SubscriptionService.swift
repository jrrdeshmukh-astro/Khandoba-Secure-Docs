//
//  SubscriptionService.swift
//  Khandoba Secure Docs
//
//  Premium Subscription Management
//

import Foundation
import StoreKit
import SwiftData
import Combine
import UIKit

@MainActor
final class SubscriptionService: ObservableObject {
    @Published var isSubscribed = false
    @Published var subscriptionStatus: Product.SubscriptionInfo.Status?
    @Published var availableSubscriptions: [Product] = []
    @Published var isLoading = false
    
    private let productID = "com.khandoba.premium.monthly"
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // Load subscription products
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let products = try await Product.products(for: [productID])
            availableSubscriptions = products
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // Purchase subscription
    func purchase() async throws {
        guard let product = availableSubscriptions.first else {
            throw SubscriptionError.productNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // We are already on the main actor here
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
            
        case .userCancelled:
            throw SubscriptionError.userCancelled
            
        case .pending:
            throw SubscriptionError.pending
            
        @unknown default:
            throw SubscriptionError.unknown
        }
    }
    
    // Restore purchases
    func restore() async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    // Update subscription status
    func updateSubscriptionStatus() async {
        guard let product = availableSubscriptions.first else { return }
        guard let statuses = try? await product.subscription?.status else {
            isSubscribed = false
            return
        }
        
        for status in statuses {
            switch status.state {
            case .subscribed, .inGracePeriod:
                isSubscribed = true
                subscriptionStatus = status
                return
                
            case .expired, .revoked:
                isSubscribed = false
                
            case .inBillingRetryPeriod:
                isSubscribed = true
                
            default:
                isSubscribed = false
            }
        }
    }
    
    // Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error>? {
        if #available(iOS 15.0, *) {
            return Task.detached { [weak self] in
                guard let self else { return }
                for await result in StoreKit.Transaction.updates {
                    do {
                        // Verification can be done off the main actor safely if desired.
                        // However, since checkVerified is main-actor isolated, hop to main actor to use it.
                        let transaction = try await MainActor.run {
                            try self.checkVerified(result)
                        }
                        await transaction.finish()
                        // Hop back to main actor for state updates
                        await MainActor.run {
                            Task { await self.updateSubscriptionStatus() }
                        }
                    } catch {
                        print("Transaction failed verification: \(error)")
                    }
                }
            }
        } else {
            return nil
        }
    }
    
    // Verify transaction (main-actor isolated as part of the service)
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // Manage subscriptions (opens system sheet)
    func manageSubscriptions() async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                print("Failed to show manage subscriptions: \(error)")
            }
        }
    }
}

enum SubscriptionError: LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case failedVerification
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not found"
        case .userCancelled:
            return "Purchase cancelled"
        case .pending:
            return "Purchase is pending"
        case .failedVerification:
            return "Transaction verification failed"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

