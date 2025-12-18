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
    // MARK: - LRU Cache Implementation
    
    /// LRU Cache entry with timestamp
    private struct CacheEntry<T> {
        let value: T
        var lastAccessed: Date
        var accessCount: Int
    }
    
    /// LRU Cache with size limits
    private class LRUCache<T> {
        private var cache: [UUID: CacheEntry<T>] = [:]
        private let maxSize: Int
        private let maxMemoryBytes: Int
        
        init(maxSize: Int = 100, maxMemoryBytes: Int = 10_000_000) {
            self.maxSize = maxSize
            self.maxMemoryBytes = maxMemoryBytes
        }
        
        func get(_ key: UUID) -> T? {
            guard var entry = cache[key] else { return nil }
            entry.lastAccessed = Date()
            entry.accessCount += 1
            cache[key] = entry
            return entry.value
        }
        
        func set(_ key: UUID, value: T) {
            // Remove oldest entries if at capacity
            while cache.count >= maxSize {
                evictOldest()
            }
            
            cache[key] = CacheEntry(
                value: value,
                lastAccessed: Date(),
                accessCount: 1
            )
        }
        
        // Subscript support for cleaner syntax
        subscript(key: UUID) -> T? {
            get {
                return get(key)
            }
            set {
                if let value = newValue {
                    set(key, value: value)
                } else {
                    remove(key)
                }
            }
        }
        
        func remove(_ key: UUID) {
            cache.removeValue(forKey: key)
        }
        
        func removeAll() {
            cache.removeAll()
        }
        
        func invalidate(keys: [UUID]?) {
            if let keys = keys {
                for key in keys {
                    cache.removeValue(forKey: key)
                }
            } else {
                cache.removeAll()
            }
        }
        
        private func evictOldest() {
            guard let oldest = cache.min(by: { $0.value.lastAccessed < $1.value.lastAccessed }) else {
                return
            }
            cache.removeValue(forKey: oldest.key)
        }
        
        var count: Int { cache.count }
        var keys: [UUID] { Array(cache.keys) }
    }
    
    // MARK: - Caching
    
    private static var documentCache = LRUCache<Document>(maxSize: 200, maxMemoryBytes: 20_000_000)
    private static var vaultCache = LRUCache<Vault>(maxSize: 50, maxMemoryBytes: 5_000_000)
    private static var userCache = LRUCache<User>(maxSize: 20, maxMemoryBytes: 2_000_000)
    
    // Cache versioning for stale data detection
    private static var cacheVersion: Int = 1
    private static var cacheVersionKey = "cache_version"
    
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
        // Check cache first (LRU will update access times)
        var results: [Document] = []
        var missingIDs: [UUID] = []
        var cacheHits = 0
        
        for id in ids {
            if let cached = getCachedDocument(id) {
                results.append(cached)
                cacheHits += 1
            } else {
                missingIDs.append(id)
            }
        }
        
        if cacheHits > 0 {
            print("📊 Cache hit rate: \(cacheHits)/\(ids.count) (\(Int(Double(cacheHits) / Double(ids.count) * 100))%)")
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
            // Clear 50% of least recently used entries
            let documentKeys = documentCache.keys
            let keysToRemove = Array(documentKeys.prefix(documentKeys.count / 2))
            for key in keysToRemove {
                documentCache.remove(key)
            }
            print("🧹 Cache cleaned: \(currentSize) → \(cacheMemoryUsage()) bytes")
        }
    }
    
    /// Handle memory pressure warning
    static func handleMemoryPressure() {
        print("⚠️ Memory pressure detected - clearing caches")
        clearAllCaches()
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

