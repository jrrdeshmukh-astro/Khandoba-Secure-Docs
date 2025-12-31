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
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var annotations: [AccessAnnotation] = []
    @State private var selectedAnnotation: AccessAnnotation?
    @State private var eventTypeFilter: EventFilter = .all
    @State private var isLoading = false
    
    // iOS-ONLY: Using SwiftData/CloudKit exclusively - data loaded from vault relationships
    
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
                // swiftlint:disable:next deprecated_member_use
                Map(coordinateRegion: $region, annotationItems: filteredAnnotations) { annotation in
                    // swiftlint:disable:next deprecated_member_use
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
                            
                            // iOS-ONLY: Using SwiftData/CloudKit exclusively
                            let logs: [VaultAccessLog] = vault.accessLogs ?? []
                            // Show ALL logs with location data (sorted by most recent first)
                            let logsWithLocation = logs.filter { $0.locationLatitude != nil && $0.locationLongitude != nil }
                                .sorted { $0.timestamp > $1.timestamp }
                            ForEach(Array(logsWithLocation)) { log in
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
                        .padding(.vertical)
                    }
                    .frame(height: 200)
                    .background(colors.surface)
                }
            }
            }
        }
        .navigationTitle("Access Map")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            // Ensure location permissions are granted
            let locationService = LocationService()
            await locationService.requestLocationPermission()
            
            // iOS-ONLY: Using SwiftData/CloudKit exclusively - load access points
            await MainActor.run {
                loadAccessPoints()
            }
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
    
    private func loadAccessPoints() {
        var allAnnotations: [AccessAnnotation] = []
        
        // Include ALL events - no limit
        print("MAP: Loading ALL vault events...")
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        let logs: [VaultAccessLog] = vault.accessLogs ?? []
        print("MAP: Found \(logs.count) access logs total")
        
        // Process ALL logs with location data (sorted by most recent first for display)
        let sortedLogs = logs.sorted { $0.timestamp > $1.timestamp }
        
        var logAnnotations: [AccessAnnotation] = []
        for log in sortedLogs {
            if let lat = log.locationLatitude, let lon = log.locationLongitude {
                // Determine event category based on access type
                let category = categorizeEventType(log.accessType)
                
                let annotation = AccessAnnotation(
                    id: log.id,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    accessType: log.accessType,
                    timestamp: log.timestamp,
                    eventCategory: category,
                    details: log.documentName ?? log.userName ?? "Event"
                )
                logAnnotations.append(annotation)
            }
        }
        
        allAnnotations.append(contentsOf: logAnnotations)
        print("MAP: Loaded \(logAnnotations.count) access events")
        
        // 2. DUAL-KEY REQUESTS
        // Note: Dual-key requests use location from the access log at request time
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        let dualKeyRequests: [DualKeyRequest] = vault.dualKeyRequests ?? []
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
        
        // 3. DOCUMENT ACTIONS (all document-related events are already included in logAnnotations above)
        // No need to duplicate - document actions are part of access logs
        print("MAP: Document actions included in access logs above")
        
        // 4. DOCUMENT UPLOADS
        // Include ALL uploads (not just recent)
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        let documents: [Document] = vault.documents ?? []
        let sortedDocuments = documents.sorted { $0.uploadedAt > $1.uploadedAt }
        var uploadAnnotations: [AccessAnnotation] = []
        
        for document in sortedDocuments {
            // Find access log near upload time
            if let matchingLog = sortedLogs.first(where: { 
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
        // Report events are already included in logAnnotations above (they're access logs with accessType "report_generated")
        print("MAP: Report generation events included in access logs above")
        
        // Sort by timestamp (most recent first) and update on main actor
        let sortedAnnotations = allAnnotations.sorted { $0.timestamp > $1.timestamp }
        
        // Update annotations on main actor to trigger UI update
        Task { @MainActor in
            annotations = sortedAnnotations
        }
        
        print("MAP SUMMARY: Total events on map: \(sortedAnnotations.count)")
        print("   Access Logs: \(logAnnotations.count)")
        print("   Dual-Key: \(requestAnnotations.count)")
        print("   Uploads: \(uploadAnnotations.count)")
        
        // Count by category for summary
        let categoryCounts = Dictionary(grouping: sortedAnnotations, by: { $0.eventCategory })
        for (category, events) in categoryCounts {
            print("   \(category): \(events.count)")
        }
        
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
    
    /// Categorize event type for filtering
    private func categorizeEventType(_ type: String) -> String {
        switch type.lowercased() {
        // Access events
        case "opened", "closed", "viewed", "modified", "deleted":
            return "Access"
        // Document actions
        case "previewed", "edited", "renamed", "redacted", "downloaded", "shared":
            return "Document"
        // Dual-key events
        case "dual_key_approved", "dual_key_denied", "dual_key_pending":
            return "Dual-Key"
        // Upload events
        case "upload", "uploaded":
            return "Upload"
        // Report events
        case "report_generated", "report_created":
            return "Report"
        // Session events
        case "session_started", "session_ended", "session_extended":
            return "Access"
        // Default to Access category
        default:
            return "Access"
        }
    }
    
    private func iconForAccessType(_ type: String) -> String {
        switch type.lowercased() {
        // Access events
        case "opened": return "lock.open.fill"
        case "closed": return "lock.fill"
        case "viewed": return "eye.fill"
        case "modified": return "pencil.circle.fill"
        case "deleted": return "trash.fill"
        case "session_started": return "play.circle.fill"
        case "session_ended": return "stop.circle.fill"
        case "session_extended": return "arrow.clockwise.circle.fill"
        
        // Document actions
        case "previewed": return "eye.circle.fill"
        case "edited": return "pencil.and.outline"
        case "renamed": return "textformat"
        case "redacted": return "eye.slash.fill"
        case "downloaded": return "arrow.down.doc.fill"
        case "shared": return "square.and.arrow.up.fill"
        
        // Dual-key events
        case "dual_key_approved": return "checkmark.shield.fill"
        case "dual_key_denied": return "xmark.shield.fill"
        case "dual_key_pending": return "clock.badge.questionmark.fill"
        
        // Upload events
        case "upload", "uploaded": return "arrow.up.doc.fill"
        
        // Report events
        case "report_generated", "report_created": return "chart.bar.doc.horizontal.fill"
        
        default: return "circle.fill"
        }
    }
    
    private func colorForAccessType(_ type: String) -> Color {
        let colors = theme.colors(for: colorScheme)
        switch type.lowercased() {
        // Access events
        case "opened", "session_started": return colors.success
        case "closed", "session_ended": return colors.textTertiary
        case "viewed": return colors.info
        case "modified": return colors.warning
        case "deleted": return colors.error
        case "session_extended": return colors.secondary
        
        // Document actions
        case "previewed": return colors.info
        case "edited": return colors.warning
        case "renamed": return colors.secondary
        case "redacted": return colors.error
        case "downloaded": return colors.primary
        case "shared": return colors.info
        
        // Dual-key events
        case "dual_key_approved": return colors.success
        case "dual_key_denied": return colors.error
        case "dual_key_pending": return colors.warning
        
        // Upload events
        case "upload", "uploaded": return colors.primary
        
        // Report events
        case "report_generated", "report_created": return Color.purple
        
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
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
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
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
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
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
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
        switch type.lowercased() {
        case "opened", "session_started": return "lock.open.fill"
        case "closed", "session_ended": return "lock.fill"
        case "viewed": return "eye.fill"
        case "modified": return "pencil.circle.fill"
        case "deleted": return "trash.fill"
        case "previewed": return "eye.circle.fill"
        case "edited": return "pencil.and.outline"
        case "renamed": return "textformat"
        case "redacted": return "eye.slash.fill"
        case "downloaded": return "arrow.down.doc.fill"
        case "shared": return "square.and.arrow.up.fill"
        case "upload", "uploaded": return "arrow.up.doc.fill"
        case "dual_key_approved": return "checkmark.shield.fill"
        case "dual_key_denied": return "xmark.shield.fill"
        case "dual_key_pending": return "clock.badge.questionmark.fill"
        case "report_generated", "report_created": return "chart.bar.doc.horizontal.fill"
        case "session_extended": return "arrow.clockwise.circle.fill"
        default: return "circle.fill"
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        let colors = theme.colors(for: colorScheme)
        switch type.lowercased() {
        case "opened", "session_started": return colors.success
        case "closed", "session_ended": return colors.textTertiary
        case "viewed", "previewed": return colors.info
        case "modified", "edited": return colors.warning
        case "deleted", "redacted", "dual_key_denied": return colors.error
        case "renamed", "session_extended": return colors.secondary
        case "downloaded", "shared": return colors.primary
        case "upload", "uploaded": return colors.primary
        case "dual_key_approved": return colors.success
        case "dual_key_pending": return colors.warning
        case "report_generated", "report_created": return Color.purple
        default: return colors.textTertiary
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
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
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
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
