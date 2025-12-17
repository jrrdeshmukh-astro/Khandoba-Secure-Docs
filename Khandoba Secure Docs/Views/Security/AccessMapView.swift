//
//  AccessMapView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import MapKit
import SwiftData

struct AccessMapView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var supabaseService: SupabaseService
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var annotations: [AccessAnnotation] = []
    @State private var selectedAnnotation: AccessAnnotation?
    @State private var eventTypeFilter: EventFilter = .all
    @State private var isLoading = false
    
    // Supabase mode: Store loaded data
    @State private var loadedAccessLogs: [VaultAccessLog] = []
    @State private var loadedDocuments: [Document] = []
    @State private var loadedDualKeyRequests: [DualKeyRequest] = []
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: UnifiedTheme.Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading access map data...")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                }
            } else {
                VStack(spacing: 0) {
                // Summary Stats & Filter
                if !annotations.isEmpty {
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                    HStack(spacing: UnifiedTheme.Spacing.md) {
                        StatBadge(
                            icon: "mappin.circle.fill",
                                value: "\(filteredAnnotations.count)",
                                label: "Events",
                            color: colors.primary
                        )
                        
                        StatBadge(
                            icon: "location.fill",
                                value: "\(Set(filteredAnnotations.map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" }).count)",
                            label: "Locations",
                            color: colors.secondary
                        )
                    }
                        
                        // Event Type Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: UnifiedTheme.Spacing.sm) {
                                ForEach(EventFilter.allCases, id: \.self) { filter in
                                    FilterChip(
                                        label: filter.rawValue,
                                        icon: filter.icon,
                                        isSelected: eventTypeFilter == filter,
                                        count: countForFilter(filter)
                                    ) {
                                        eventTypeFilter = filter
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(colors.surface)
                }
                
                // Map with Enhanced Annotations
                // Note: Using deprecated Map API for compatibility - will update to MapContentBuilder in future
                Map(coordinateRegion: $region, annotationItems: filteredAnnotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        Button {
                            selectedAnnotation = annotation
                        } label: {
                            VStack(spacing: 4) {
                                // Icon with access type
                                ZStack {
                                    Circle()
                                        .fill(colorForAccessType(annotation.accessType))
                                        .frame(width: 36, height: 36)
                                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: iconForAccessType(annotation.accessType))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                // Time label
                                Text(annotation.timestamp, style: .time)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(colors.textPrimary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(colors.surface)
                                    .cornerRadius(4)
                                    .shadow(color: .black.opacity(0.2), radius: 2)
                                
                                // Selection indicator
                                if selectedAnnotation?.id == annotation.id {
                                    Image(systemName: "chevron.up.circle.fill")
                                        .foregroundColor(colors.primary)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Metadata Summary
                VStack(spacing: 0) {
                    HStack(spacing: UnifiedTheme.Spacing.lg) {
                        MetadataItem(
                            icon: "mappin.circle.fill",
                            value: "\(annotations.count)",
                            label: "Total Events",
                            color: colors.primary
                        )
                        
                        MetadataItem(
                            icon: "location.fill",
                            value: "\(Set(annotations.map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" }).count)",
                            label: "Locations",
                            color: colors.info
                        )
                        
                        if let latest = annotations.first {
                            MetadataItem(
                                icon: "clock.fill",
                                value: timeAgo(latest.timestamp),
                                label: "Latest",
                                color: colors.secondary
                            )
                        }
                    }
                    .padding()
                    .background(colors.surface.opacity(0.95))
                }
                
                // Selected Annotation Detail or Access Log List
                if let selected = selectedAnnotation {
                    // Detail view for selected annotation
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Access Event Details")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Spacer()
                            
                            Button {
                                selectedAnnotation = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(colors.textTertiary)
                            }
                        }
                        .padding()
                        .background(colors.surface)
                        
                        // Details
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            DetailRow(
                                icon: iconForAccessType(selected.accessType),
                                iconColor: colorForAccessType(selected.accessType),
                                label: "Event Type",
                                value: selected.accessType.capitalized
                            )
                            
                            DetailRow(
                                icon: "clock.fill",
                                iconColor: colors.secondary,
                                label: "Time",
                                value: selected.timestamp.formatted(date: .abbreviated, time: .standard)
                            )
                            
                            DetailRow(
                                icon: "location.fill",
                                iconColor: colors.primary,
                                label: "Coordinates",
                                value: String(format: "%.4f, %.4f", selected.coordinate.latitude, selected.coordinate.longitude)
                            )
                        }
                        .padding()
                    }
                    .frame(height: 200)
                    .background(colors.surface)
                } else {
                    // Access Log List
                    ScrollView {
                        LazyVStack(spacing: UnifiedTheme.Spacing.sm) {
                            HStack {
                                Text("Recent Access Events")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                Spacer()
                                Text("\(annotations.count) total")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                            .padding(.horizontal)
                            
                            // In Supabase mode, use loadedAccessLogs; otherwise use vault.accessLogs
                            let logs: [VaultAccessLog] = AppConfig.useSupabase ? loadedAccessLogs : (vault.accessLogs ?? [])
                            ForEach(Array(logs.prefix(20))) { log in
                                if log.locationLatitude != nil && log.locationLongitude != nil {
                                    Button {
                                        // Find and select corresponding annotation
                                        if let annotation = annotations.first(where: { $0.id == log.id }) {
                                            selectedAnnotation = annotation
                                            // Pan map to this location
                                            withAnimation {
                                                region.center = annotation.coordinate
                                            }
                                        }
                                    } label: {
                                        AccessLogMapRow(log: log)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .frame(height: 200)
                    .background(colors.surface)
                }
            }
            }
        }
        .navigationTitle("Access Map")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Ensure location permissions are granted
            let locationService = LocationService()
            await locationService.requestLocationPermission()
            
            // Load data from Supabase if in Supabase mode
            if AppConfig.useSupabase {
                await loadDataFromSupabase()
            }
            
            // Load access points after permission check
            loadAccessPoints()
        }
    }
    
    private var filteredAnnotations: [AccessAnnotation] {
        if eventTypeFilter == .all {
            return annotations
        }
        // Map filter to event categories
        let category: String
        switch eventTypeFilter {
        case .access: category = "Access"
        case .document: category = "Document"
        case .dualKey: category = "Dual-Key"
        case .upload: category = "Upload"
        case .report: category = "Report"
        default: category = eventTypeFilter.rawValue
        }
        return annotations.filter { $0.eventCategory == category }
    }
    
    private func countForFilter(_ filter: EventFilter) -> Int {
        if filter == .all {
            return annotations.count
        }
        return annotations.filter { $0.eventCategory == filter.rawValue }.count
    }
    
    /// Load data from Supabase for access map
    private func loadDataFromSupabase() async {
        guard AppConfig.useSupabase else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("🗺️ Loading access map data from Supabase for vault: \(vault.id)")
            
            // 1. Load access logs
            let supabaseLogs: [SupabaseVaultAccessLog] = try await supabaseService.fetchAll(
                "vault_access_logs",
                filters: ["vault_id": vault.id.uuidString]
            )
            
            print("   Found \(supabaseLogs.count) access logs")
            
            // Convert to VaultAccessLog models
            await MainActor.run {
                loadedAccessLogs = supabaseLogs.map { supabaseLog in
                    let log = VaultAccessLog(
                        id: supabaseLog.id,
                        timestamp: supabaseLog.timestamp,
                        accessType: supabaseLog.accessType,
                        userID: supabaseLog.userID,
                        userName: supabaseLog.userName,
                        deviceInfo: supabaseLog.deviceInfo
                    )
                    log.locationLatitude = supabaseLog.locationLatitude
                    log.locationLongitude = supabaseLog.locationLongitude
                    log.ipAddress = supabaseLog.ipAddress
                    log.documentID = supabaseLog.documentID
                    log.documentName = supabaseLog.documentName
                    log.vault = vault
                    return log
                }
            }
            
            // 2. Load documents (for upload events)
            let supabaseDocs: [SupabaseDocument] = try await supabaseService.fetchAll(
                "documents",
                filters: ["vault_id": vault.id.uuidString, "status": "active"]
            )
            
            print("   Found \(supabaseDocs.count) documents")
            
            // Convert to Document models
            await MainActor.run {
                loadedDocuments = supabaseDocs.map { supabaseDoc in
                    let document = Document(
                        name: supabaseDoc.name,
                        fileExtension: supabaseDoc.fileExtension,
                        mimeType: supabaseDoc.mimeType,
                        fileSize: supabaseDoc.fileSize,
                        documentType: supabaseDoc.documentType,
                        isEncrypted: supabaseDoc.isEncrypted,
                        isArchived: supabaseDoc.isArchived,
                        isRedacted: supabaseDoc.isRedacted,
                        status: supabaseDoc.status,
                        aiTags: supabaseDoc.aiTags
                    )
                    document.id = supabaseDoc.id
                    document.createdAt = supabaseDoc.createdAt
                    document.uploadedAt = supabaseDoc.uploadedAt
                    document.lastModifiedAt = supabaseDoc.lastModifiedAt
                    document.vault = vault
                    return document
                }
            }
            
            // 3. Load dual-key requests (if table exists)
            // Note: Dual-key requests might not be migrated yet, so we'll skip for now
            // TODO: Add dual-key requests loading when table is available
            
            print("✅ Loaded access map data from Supabase")
        } catch {
            print("❌ Failed to load access map data from Supabase: \(error.localizedDescription)")
        }
    }
    
    private func loadAccessPoints() {
        var allAnnotations: [AccessAnnotation] = []
        
        // OPTIMIZATION: Limit to recent events to prevent hanging
        let maxEvents = 50
        
        // 1. VAULT ACCESS LOGS (opening, closing, viewing)
        print("MAP: Loading vault events (limit: \(maxEvents))...")
        // In Supabase mode, use loadedAccessLogs; otherwise use vault.accessLogs
        let logs: [VaultAccessLog] = AppConfig.useSupabase ? loadedAccessLogs : (vault.accessLogs ?? [])
        print("MAP: Found \(logs.count) access logs total")
        
        // Only process most recent logs
        let recentLogs = logs.sorted { $0.timestamp > $1.timestamp }.prefix(maxEvents)
        
        var logAnnotations: [AccessAnnotation] = []
        for log in recentLogs {
            if let lat = log.locationLatitude, let lon = log.locationLongitude {
                let annotation = AccessAnnotation(
                id: log.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                accessType: log.accessType,
                    timestamp: log.timestamp,
                    eventCategory: "Access",
                    details: log.userName ?? "Unknown User"
                )
                logAnnotations.append(annotation)
            }
        }
        
        allAnnotations.append(contentsOf: logAnnotations)
        print("MAP: Loaded \(logAnnotations.count) access events")
        
        // 2. DUAL-KEY REQUESTS
        // Note: Dual-key requests use location from the access log at request time
        // In Supabase mode, use loadedDualKeyRequests; otherwise use vault.dualKeyRequests
        let dualKeyRequests: [DualKeyRequest] = AppConfig.useSupabase ? loadedDualKeyRequests : (vault.dualKeyRequests ?? [])
        var requestAnnotations: [AccessAnnotation] = []
        
        for request in dualKeyRequests {
            // Find the access log that corresponds to this request (same timestamp)
            if let matchingLog = logs.first(where: { 
                abs($0.timestamp.timeIntervalSince(request.requestedAt)) < 5.0 
            }), let lat = matchingLog.locationLatitude,
               let lon = matchingLog.locationLongitude {
                
                let status = request.status
                let accessType = status == "approved" ? "dual_key_approved" : 
                               status == "denied" ? "dual_key_denied" : "dual_key_pending"
                
                let annotation = AccessAnnotation(
                    id: request.id,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    accessType: accessType,
                    timestamp: request.requestedAt,
                    eventCategory: "Dual-Key",
                    details: request.reason ?? "Access request"
                )
                requestAnnotations.append(annotation)
            }
        }
        
        allAnnotations.append(contentsOf: requestAnnotations)
        print("    Loaded \(requestAnnotations.count) dual-key requests")
        
        // 3. DOCUMENT ACTIONS (preview, edit, rename, redact)
        var documentActionAnnotations: [AccessAnnotation] = []
        for log in recentLogs {
            if log.documentID != nil,
               let lat = log.locationLatitude,
               let lon = log.locationLongitude,
               (log.accessType == "previewed" || log.accessType == "edited" || 
                log.accessType == "renamed" || log.accessType == "redacted") {
                
                let annotation = AccessAnnotation(
                    id: log.id,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    accessType: log.accessType,
                    timestamp: log.timestamp,
                    eventCategory: "Document",
                    details: log.documentName ?? "Document"
                )
                documentActionAnnotations.append(annotation)
            }
        }
        allAnnotations.append(contentsOf: documentActionAnnotations)
        print("MAP: Loaded \(documentActionAnnotations.count) document action events")
        
        // 4. DOCUMENT UPLOADS
        // OPTIMIZATION: Only show recent uploads
        // In Supabase mode, use loadedDocuments; otherwise use vault.documents
        let documents: [Document] = AppConfig.useSupabase ? loadedDocuments : (vault.documents ?? [])
        let recentDocuments = documents.sorted { $0.uploadedAt > $1.uploadedAt }.prefix(20)
        var uploadAnnotations: [AccessAnnotation] = []
        
        for document in recentDocuments {
            // Find access log near upload time
            if let matchingLog = logs.first(where: { 
                abs($0.timestamp.timeIntervalSince(document.uploadedAt)) < 300 // Within 5 minutes
            }), let lat = matchingLog.locationLatitude,
               let lon = matchingLog.locationLongitude {
                
                let annotation = AccessAnnotation(
                    id: document.id,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    accessType: "upload",
                    timestamp: document.uploadedAt,
                    eventCategory: "Upload",
                    details: document.name
                )
                uploadAnnotations.append(annotation)
            }
        }
        
        allAnnotations.append(contentsOf: uploadAnnotations)
        print("MAP: Loaded \(uploadAnnotations.count) upload events")
        
        // 5. REPORT GENERATION EVENTS
        // Track when intel reports are generated (stored in vault access logs)
        var reportAnnotations: [AccessAnnotation] = []
        for log in logs where log.accessType == "report_generated" {
            if let lat = log.locationLatitude, let lon = log.locationLongitude {
                let annotation = AccessAnnotation(
                    id: log.id,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    accessType: "report_generated",
                    timestamp: log.timestamp,
                    eventCategory: "Report",
                    details: "Intel report generated"
                )
                reportAnnotations.append(annotation)
            }
        }
        allAnnotations.append(contentsOf: reportAnnotations)
        print("MAP: Loaded \(reportAnnotations.count) report generation events")
        
        // Sort by timestamp (most recent first)
        annotations = allAnnotations.sorted { $0.timestamp > $1.timestamp }
        
        print("MAP SUMMARY: Total events on map: \(annotations.count)")
        print("   Access: \(logAnnotations.count)")
        print("   Document Actions: \(documentActionAnnotations.count)")
        print("   Dual-Key: \(requestAnnotations.count)")
        print("   Uploads: \(uploadAnnotations.count)")
        print("   Reports: \(reportAnnotations.count)")
        
        // Debug: Print first few coordinates
        for (index, annotation) in annotations.prefix(3).enumerated() {
            print("   Event \(index + 1): \(annotation.accessType) at \(annotation.coordinate.latitude), \(annotation.coordinate.longitude)")
        }
        
        // Calculate region from all access points
        calculateMapRegion()
    }
    
    private func calculateMapRegion() {
        let coordinates = annotations.map { $0.coordinate }
        
        guard !coordinates.isEmpty else {
            // No access logs with location data - use default
            return
        }
        
        if coordinates.count == 1 {
            // Single location - center on it with tight zoom
            region = MKCoordinateRegion(
                center: coordinates[0],
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            return
        }
        
        // Multiple locations - calculate bounding box
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Add 50% padding to ensure all points are visible
        let latDelta = max((maxLat - minLat) * 1.5, 0.01)
        let lonDelta = max((maxLon - minLon) * 1.5, 0.01)
        
        region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
    
    private func iconForAccessType(_ type: String) -> String {
        switch type {
        // Access events
        case "opened": return "lock.open.fill"
        case "closed": return "lock.fill"
        case "viewed": return "eye.fill"
        case "modified": return "pencil.circle.fill"
        case "deleted": return "trash.fill"
        
        // Document actions
        case "previewed": return "eye.circle.fill"
        case "edited": return "pencil.and.outline"
        case "renamed": return "textformat"
        case "redacted": return "eye.slash.fill"
        
        // Dual-key events
        case "dual_key_approved": return "checkmark.shield.fill"
        case "dual_key_denied": return "xmark.shield.fill"
        case "dual_key_pending": return "clock.badge.questionmark.fill"
        
        // Upload events
        case "upload": return "arrow.up.doc.fill"
        
        // Report events
        case "report_generated": return "chart.bar.doc.horizontal.fill"
        
        default: return "circle.fill"
        }
    }
    
    private func colorForAccessType(_ type: String) -> Color {
        let colors = theme.colors(for: colorScheme)
        switch type {
        // Access events
        case "opened": return colors.success
        case "closed": return colors.textTertiary
        case "viewed": return colors.info
        case "modified": return colors.warning
        case "deleted": return colors.error
        
        // Document actions
        case "previewed": return colors.info
        case "edited": return colors.warning
        case "renamed": return colors.secondary
        case "redacted": return colors.error
        
        // Dual-key events
        case "dual_key_approved": return colors.success
        case "dual_key_denied": return colors.error
        case "dual_key_pending": return colors.warning
        
        // Upload events
        case "upload": return colors.primary
        
        // Report events
        case "report_generated": return Color.purple
        
        default: return colors.textTertiary
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let mins = Int(interval / 60)
            return "\(mins)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

struct MetadataItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(value)
                    .font(theme.typography.title2)
                    .foregroundColor(theme.colors(for: colorScheme).textPrimary)
                    .fontWeight(.bold)
            }
            
            Text(label)
                .font(theme.typography.caption2)
                .foregroundColor(theme.colors(for: colorScheme).textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Event Filter
enum EventFilter: String, CaseIterable {
    case all = "All"
    case access = "Access"
    case document = "Document"
    case dualKey = "Dual-Key"
    case upload = "Upload"
    case report = "Report"
    
    var icon: String {
        switch self {
        case .all: return "circle.grid.3x3.fill"
        case .access: return "lock.open.fill"
        case .document: return "doc.fill"
        case .dualKey: return "key.fill"
        case .upload: return "arrow.up.doc.fill"
        case .report: return "chart.bar.doc.horizontal.fill"
        }
    }
}

struct FilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(theme.typography.caption)
                if count > 0 {
                    Text("(\(count))")
                        .font(theme.typography.caption2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? colors.primary : colors.surface)
            .foregroundColor(isSelected ? .white : colors.textPrimary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : colors.textTertiary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct AccessAnnotation: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let accessType: String
    let timestamp: Date
    let eventCategory: String  // "Access", "Dual-Key", "Upload", "Report"
    let details: String
}

struct AccessLogMapRow: View {
    let log: VaultAccessLog
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                // Icon
                Image(systemName: iconForType(log.accessType))
                    .font(.title3)
                    .foregroundColor(colorForType(log.accessType))
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.accessType.capitalized)
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                    
                    if let lat = log.locationLatitude, let lon = log.locationLongitude {
                        Text(String(format: "%.4f, %.4f", lat, lon))
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Text(log.timestamp, style: .relative)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(colors.textTertiary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "opened": return "lock.open.fill"
        case "closed": return "lock.fill"
        case "viewed": return "eye.fill"
        case "modified": return "pencil.circle.fill"
        case "deleted": return "trash.fill"
        default: return "circle.fill"
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        let colors = theme.colors(for: colorScheme)
        switch type {
        case "opened": return colors.success
        case "closed": return colors.textTertiary
        case "viewed": return colors.info
        case "modified": return colors.warning
        case "deleted": return colors.error
        default: return colors.textTertiary
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(theme.typography.title2)
                    .foregroundColor(theme.colors(for: colorScheme).textPrimary)
                    .fontWeight(.bold)
                
                Text(label)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors(for: colorScheme).textSecondary)
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors(for: colorScheme).textSecondary)
                
                Text(value)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors(for: colorScheme).textPrimary)
            }
            
            Spacer()
        }
    }
}
