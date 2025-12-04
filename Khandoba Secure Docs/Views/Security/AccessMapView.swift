//
//  AccessMapView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import MapKit

struct AccessMapView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var annotations: [AccessAnnotation] = []
    @State private var selectedAnnotation: AccessAnnotation?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Summary Stats
                if !annotations.isEmpty {
                    HStack(spacing: UnifiedTheme.Spacing.md) {
                        StatBadge(
                            icon: "mappin.circle.fill",
                            value: "\(annotations.count)",
                            label: "Access Points",
                            color: colors.primary
                        )
                        
                        StatBadge(
                            icon: "location.fill",
                            value: "\(Set(annotations.map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" }).count)",
                            label: "Locations",
                            color: colors.secondary
                        )
                    }
                    .padding()
                    .background(colors.surface)
                }
                
                // Map with Enhanced Annotations
                Map(coordinateRegion: $region, annotationItems: annotations) { annotation in
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
                            
                            let logs: [VaultAccessLog] = vault.accessLogs ?? []
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
        .navigationTitle("Access Map")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAccessPoints()
        }
    }
    
    private func loadAccessPoints() {
        let logs: [VaultAccessLog] = vault.accessLogs ?? []
        annotations = logs.compactMap { log in
            guard let lat = log.locationLatitude,
                  let lon = log.locationLongitude else { return nil }
            
            return AccessAnnotation(
                id: log.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                accessType: log.accessType,
                timestamp: log.timestamp
            )
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
        case "opened": return "lock.open.fill"
        case "closed": return "lock.fill"
        case "viewed": return "eye.fill"
        case "modified": return "pencil.circle.fill"
        case "deleted": return "trash.fill"
        default: return "circle.fill"
        }
    }
    
    private func colorForAccessType(_ type: String) -> Color {
        let colors = theme.colors(for: colorScheme)
        switch type {
        case "opened": return colors.primary
        case "closed": return colors.textTertiary
        case "viewed": return colors.secondary
        case "modified": return colors.warning
        case "deleted": return colors.error
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

struct AccessAnnotation: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let accessType: String
    let timestamp: Date
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
