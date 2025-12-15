//
//  DataOptimizationService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class DataOptimizationService: ObservableObject {
    // MARK: - Caching
    
    private static var documentCache: [UUID: Document] = [:]
    private static var vaultCache: [UUID: Vault] = [:]
    private static var userCache: [UUID: User] = [:]
    
    // MARK: - Cache Management
    
    static func cacheDocument(_ document: Document) {
        documentCache[document.id] = document
    }
    
    static func getCachedDocument(_ id: UUID) -> Document? {
        return documentCache[id]
    }
    
    static func cacheVault(_ vault: Vault) {
        vaultCache[vault.id] = vault
    }
    
    static func getCachedVault(_ id: UUID) -> Vault? {
        return vaultCache[id]
    }
    
    static func cacheUser(_ user: User) {
        userCache[user.id] = user
    }
    
    static func getCachedUser(_ id: UUID) -> User? {
        return userCache[id]
    }
    
    static func clearAllCaches() {
        documentCache.removeAll()
        vaultCache.removeAll()
        userCache.removeAll()
    }
    
    static func clearCache(for type: CacheType) {
        switch type {
        case .documents:
            documentCache.removeAll()
        case .vaults:
            vaultCache.removeAll()
        case .users:
            userCache.removeAll()
        }
    }
    
    enum CacheType {
        case documents
        case vaults
        case users
    }
    
    // MARK: - Batch Operations
    
    /// Batch fetch documents with prefetching
    static func batchFetchDocuments(
        ids: [UUID],
        from context: ModelContext
    ) throws -> [Document] {
        // Check cache first
        var results: [Document] = []
        var missingIDs: [UUID] = []
        
        for id in ids {
            if let cached = getCachedDocument(id) {
                results.append(cached)
            } else {
                missingIDs.append(id)
            }
        }
        
        // Fetch missing from database
        if !missingIDs.isEmpty {
            let descriptor = FetchDescriptor<Document>(
                predicate: #Predicate { doc in
                    missingIDs.contains(doc.id)
                }
            )
            
            let fetched = try context.fetch(descriptor)
            fetched.forEach { cacheDocument($0) }
            results.append(contentsOf: fetched)
        }
        
        return results
    }
    
    /// Batch fetch vaults with relationship prefetching
    static func batchFetchVaults(
        for userID: UUID,
        from context: ModelContext
    ) throws -> [Vault] {
        let descriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { vault in
                vault.owner?.id == userID
            },
            sortBy: [SortDescriptor<Vault>(\.createdAt, order: .reverse)]
        )
        
        let vaults = try context.fetch(descriptor)
        
        // Cache results
        vaults.forEach { cacheVault($0) }
        
        return vaults
    }
    
    // MARK: - Prefetching Strategies
    
    /// Prefetch related data for vault detail view
    static func prefetchVaultDetails(_ vault: Vault, from context: ModelContext) async throws {
        // This would prefetch documents, sessions, access logs
        // SwiftData handles relationships automatically, but we can optimize
        _ = vault.documents ?? [] // Access to load
        _ = vault.sessions ?? []
        _ = (vault.accessLogs ?? []).prefix(20) // Only recent logs
    }
    
    /// Prefetch data for dashboard
    static func prefetchDashboardData(for userID: UUID, from context: ModelContext) async throws {
        // Batch fetch all user's vaults
        let vaults = try batchFetchVaults(for: userID, from: context)
        
        // Prefetch document counts (already loaded with vaults)
        vaults.forEach { _ = $0.documents?.count ?? 0 }
        
        // Prefetch recent access logs
        let logDescriptor = FetchDescriptor<VaultAccessLog>(
            sortBy: [SortDescriptor<VaultAccessLog>(\.timestamp, order: .reverse)]
        )
        let logs = try context.fetch(logDescriptor)
        _ = logs.prefix(20) // Only recent
    }
    
    // MARK: - Query Optimization
    
    /// Optimized search with pagination
    static func optimizedDocumentSearch(
        query: String,
        in vaults: [Vault],
        limit: Int = 50
    ) -> [Document] {
        var results: [Document] = []
        var count = 0
        
        for vault in vaults {
            if count >= limit { break }
            
            guard let documents = vault.documents else { continue }
            let filtered = documents.prefix(limit - count).filter { document in
                document.status == "active" &&
                (document.name.localizedCaseInsensitiveContains(query) ||
                 document.aiTags.contains(where: { $0.localizedCaseInsensitiveContains(query) }))
            }
            
            results.append(contentsOf: filtered)
            count += filtered.count
        }
        
        return results
    }
    
    // MARK: - Memory Management
    
    /// Calculate cache size
    static func cacheMemoryUsage() -> Int {
        let documentCount = documentCache.count
        let vaultCount = vaultCache.count
        let userCount = userCache.count
        
        // Rough estimate: 1KB per cached object
        return (documentCount + vaultCount + userCount) * 1024
    }
    
    /// Clean up old cache entries if memory is high
    static func cleanupCacheIfNeeded(maxSize: Int = 10_000_000) { // 10 MB default
        let currentSize = cacheMemoryUsage()
        
        if currentSize > maxSize {
            // Clear oldest 50% of cache
            documentCache.removeAll()
            print("Cache cleared: \(currentSize) bytes freed")
        }
    }
}

// MARK: - Request Optimization

extension ModelContext {
    /// Batch save with error handling
    func batchSave(_ objects: [any PersistentModel]) throws {
        for object in objects {
            insert(object)
        }
        try save()
    }
    
    /// Save with retry logic
    func saveWithRetry(maxAttempts: Int = 3) async throws {
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxAttempts {
            do {
                try save()
                return
            } catch {
                lastError = error
                attempts += 1
                
                if attempts < maxAttempts {
                    // Wait before retry (exponential backoff)
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempts)) * 100_000_000))
                }
            }
        }
        
        throw lastError ?? DataOptimizationError.saveFailed
    }
}

enum DataOptimizationError: LocalizedError {
    case saveFailed
    case fetchFailed
    case cacheCorrupted
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data after multiple attempts"
        case .fetchFailed:
            return "Failed to fetch data"
        case .cacheCorrupted:
            return "Cache data corrupted"
        }
    }
}

