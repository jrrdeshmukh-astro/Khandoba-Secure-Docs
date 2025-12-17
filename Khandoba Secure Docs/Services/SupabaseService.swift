//
//  SupabaseService.swift
//  Khandoba Secure Docs
//
//  Created for Supabase Migration
//

import Foundation
import Combine
import Supabase

@MainActor
final class SupabaseService: ObservableObject {
    @Published var isConnected = false
    @Published var currentSession: Session?
    @Published var error: Error?
    
    private var supabaseClient: SupabaseClient?
    private var realtimeChannels: [RealtimeChannel] = []
    
    nonisolated init() {}
    
    // MARK: - Initialization
    
    func configure() async throws {
        let config = SupabaseConfig.currentEnvironment
        
        // Configure AuthClient to use new session behavior (suppresses warning)
        // The default storage (UserDefaults) will be used automatically
        let client = SupabaseClient(
            supabaseURL: URL(string: config.supabaseURL)!,
            supabaseKey: config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
        
        self.supabaseClient = client
        
        // Check connection by testing a simple database query (doesn't require auth)
        do {
            // Test connection with a simple query that doesn't require authentication
            // This verifies the Supabase URL and key are correct
            let _: [SupabaseUser] = try await client.database
                .from("users")
                .select()
                .limit(0)
                .execute()
                .value
            
            self.isConnected = true
            self.currentSession = try? await client.auth.session
            print("✅ Supabase client initialized and connected")
            print("   URL: \(config.supabaseURL)")
            print("   Connection verified via database query")
        } catch {
            // If query fails, check if it's an auth error (expected) or connection error
            if let urlError = error as? URLError {
                self.isConnected = false
                self.error = error
                print("❌ Supabase connection failed: \(urlError.localizedDescription)")
                print("   Check your internet connection and Supabase URL")
            } else {
                // Auth errors are expected when not signed in - connection is still OK
                self.isConnected = true
                self.currentSession = try? await client.auth.session
                print("✅ Supabase client initialized")
                print("   URL: \(config.supabaseURL)")
                print("   Note: No active session (user not signed in)")
            }
        }
        
        // Setup real-time subscriptions if enabled and user is authenticated
        // Note: Realtime subscriptions require authentication, so we'll set them up after sign-in
        // Don't set up here to avoid WebSocket errors when not authenticated
    }
    
    // MARK: - Authentication
    
    func signInWithApple(idToken: String, nonce: String) async throws -> Session {
        guard let client = supabaseClient else {
            throw SupabaseError.clientNotInitialized
        }
        
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            
            self.currentSession = session
            self.isConnected = true
            
            // Setup real-time subscriptions after successful authentication
            if SupabaseConfig.enableRealtime {
                setupRealtimeSubscriptions()
            }
            
            return session
        } catch {
            self.error = error
            throw error
        }
    }
    
    func signOut() async throws {
        guard let client = supabaseClient else {
            throw SupabaseError.clientNotInitialized
        }
        
        try await client.auth.signOut()
        self.currentSession = nil
        self.isConnected = false
        
        // Unsubscribe from realtime when signing out
        unsubscribeAll()
    }
    
    func getCurrentUser() async throws -> Supabase.User? {
        guard let client = supabaseClient else {
            throw SupabaseError.clientNotInitialized
        }
        
        return try await client.auth.user()
    }
    
    // MARK: - Database Queries
    
    func query(_ table: String) -> PostgrestQueryBuilder {
        guard let client = supabaseClient else {
            fatalError("Supabase client not initialized. Call configure() first.")
        }
        
        return client.database.from(table)
    }
    
    func insert<T: Codable>(_ table: String, values: T) async throws -> T {
        guard let client = supabaseClient else {
            throw SupabaseError.clientNotInitialized
        }
        
        let response: T = try await client.database
            .from(table)
            .insert(values)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func update<T: Codable>(_ table: String, id: UUID, values: T) async throws -> T {
        guard let client = supabaseClient else {
            throw SupabaseError.clientNotInitialized
        }
        
        let response: T = try await client.database
            .from(table)
            .update(values)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func delete(_ table: String, id: UUID) async throws {
        guard let client = supabaseClient else {
            throw SupabaseError.clientNotInitialized
        }
        
        try await client.database
            .from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func fetch<T: Codable>(_ table: String, id: UUID) async throws -> T {
        guard let client = supabaseClient else {
            throw SupabaseError.clientNotInitialized
        }
        
        let response: T = try await client.database
            .from(table)
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        return response
    }
    
    func fetchAll<T: Codable>(
        _ table: String,
        filters: [String: Any]? = nil,
        limit: Int? = nil,
        orderBy: String? = nil,
        ascending: Bool = true
    ) async throws -> [T] {
        guard let client = supabaseClient else {
            throw SupabaseError.clientNotInitialized
        }
        
        // Build query with filters
        var filterQuery = client.database.from(table).select()
        
        // Apply filters
        if let filters = filters {
            for (key, value) in filters {
                // Convert value to PostgrestFilterValue-compatible type
                if let stringValue = value as? String {
                    filterQuery = filterQuery.eq(key, value: stringValue)
                } else if let uuidValue = value as? UUID {
                    filterQuery = filterQuery.eq(key, value: uuidValue.uuidString)
                } else if let intValue = value as? Int {
                    filterQuery = filterQuery.eq(key, value: intValue)
                } else if let boolValue = value as? Bool {
                    filterQuery = filterQuery.eq(key, value: boolValue)
                } else {
                    // Fallback: convert to string
                    filterQuery = filterQuery.eq(key, value: String(describing: value))
                }
            }
        }
        
        // Build final query with ordering and limit
        // Note: order() and limit() return PostgrestTransformBuilder
        // We need to apply order() first to get a transform builder, then we can apply limit()
        let response: [T]
        if let orderBy = orderBy {
            // Apply order first to get PostgrestTransformBuilder
            let transformQuery = filterQuery.order(orderBy, ascending: ascending)
            if let limit = limit {
                // Both order and limit
                response = try await transformQuery.limit(limit).execute().value
            } else {
                // Only order
                response = try await transformQuery.execute().value
            }
        } else if let limit = limit {
            // Only limit - apply a default order first to get transform builder
            // Using a common column that should exist in most tables
            let transformQuery = filterQuery.order("created_at", ascending: false)
            response = try await transformQuery.limit(limit).execute().value
        } else {
            // No order or limit - execute filter query directly
            response = try await filterQuery.execute().value
        }
        return response
    }
    
    // MARK: - Storage
    
    func uploadFile(
        bucket: String,
        path: String,
        data: Data,
        options: FileOptions? = nil
    ) async throws -> String {
        guard let client = supabaseClient else {
            throw SupabaseError.clientNotInitialized
        }
        
        // Use default options if none provided
        let uploadOptions = options ?? FileOptions(
            cacheControl: "3600",
            contentType: "application/octet-stream",
            upsert: false
        )
        
        try await client.storage.from(bucket).upload(
            path: path,
            file: data,
            options: uploadOptions
        )
        
        return path
    }
    
    func downloadFile(bucket: String, path: String) async throws -> Data {
        guard let client = supabaseClient else {
            throw SupabaseError.clientNotInitialized
        }
        
        let data = try await client.storage.from(bucket).download(path: path)
        return data
    }
    
    func deleteFile(bucket: String, path: String) async throws {
        guard let client = supabaseClient else {
            throw SupabaseError.clientNotInitialized
        }
        
        try await client.storage.from(bucket).remove(paths: [path])
    }
    
    // MARK: - Real-time
    
    private func setupRealtimeSubscriptions() {
        guard let client = supabaseClient else {
            print("⚠️ Cannot setup realtime: Supabase client not initialized")
            return
        }
        
        // Only setup realtime if user is authenticated
        guard currentSession != nil else {
            print("⚠️ Cannot setup realtime: User not authenticated")
            return
        }
        
        Task {
            do {
                for channelName in SupabaseConfig.realtimeChannels {
                    let channel = client.realtime.channel("\(channelName)-changes")
                    realtimeChannels.append(channel)
                    
                    // Subscribe to INSERT events
                    channel.on("postgres_changes", filter: ChannelFilter(
                        event: "INSERT",
                        schema: "public",
                        table: channelName
                    )) { [weak self] message in
                        Task { @MainActor in
                            print("📡 Real-time INSERT on \(channelName)")
                            NotificationCenter.default.post(
                                name: .supabaseRealtimeUpdate,
                                object: nil,
                                userInfo: [
                                    "channel": channelName,
                                    "event": "INSERT",
                                    "payload": message.payload
                                ]
                            )
                        }
                    }
                    
                    // Subscribe to UPDATE events
                    channel.on("postgres_changes", filter: ChannelFilter(
                        event: "UPDATE",
                        schema: "public",
                        table: channelName
                    )) { [weak self] message in
                        Task { @MainActor in
                            print("📡 Real-time UPDATE on \(channelName)")
                            NotificationCenter.default.post(
                                name: .supabaseRealtimeUpdate,
                                object: nil,
                                userInfo: [
                                    "channel": channelName,
                                    "event": "UPDATE",
                                    "payload": message.payload
                                ]
                            )
                        }
                    }
                    
                    // Subscribe to DELETE events
                    channel.on("postgres_changes", filter: ChannelFilter(
                        event: "DELETE",
                        schema: "public",
                        table: channelName
                    )) { [weak self] message in
                        Task { @MainActor in
                            print("📡 Real-time DELETE on \(channelName)")
                            NotificationCenter.default.post(
                                name: .supabaseRealtimeUpdate,
                                object: nil,
                                userInfo: [
                                    "channel": channelName,
                                    "event": "DELETE",
                                    "payload": message.payload
                                ]
                            )
                        }
                    }
                    
                    // Subscribe to the channel with error handling
                    do {
                        await channel.subscribe()
                        print("✅ Subscribed to realtime channel: \(channelName)")
                    } catch {
                        print("⚠️ Failed to subscribe to channel \(channelName): \(error.localizedDescription)")
                        // Continue with other channels even if one fails
                    }
                }
                
                await MainActor.run {
                    print("✅ Real-time subscriptions setup for \(SupabaseConfig.realtimeChannels.count) channels")
                }
            } catch {
                await MainActor.run {
                    print("⚠️ Error setting up realtime subscriptions: \(error.localizedDescription)")
                    print("   This is normal if Realtime isn't enabled in Supabase or tables aren't in publication")
                }
            }
        }
    }
    
    func unsubscribeAll() {
        for channel in realtimeChannels {
            channel.unsubscribe()
        }
        realtimeChannels.removeAll()
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case clientNotInitialized
    case invalidResponse
    case networkError(Error)
    case authenticationFailed
    case storageError(String)
    
    var errorDescription: String? {
        switch self {
        case .clientNotInitialized:
            return "Supabase client not initialized. Call configure() first."
        case .invalidResponse:
            return "Invalid response from Supabase"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationFailed:
            return "Authentication failed"
        case .storageError(let message):
            return "Storage error: \(message)"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let supabaseRealtimeUpdate = Notification.Name("supabaseRealtimeUpdate")
}
