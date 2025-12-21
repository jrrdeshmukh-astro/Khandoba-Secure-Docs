//
//  DocumentFidelityView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//

import SwiftUI
import SwiftData
import MapKit

#if os(iOS)
import UIKit
#endif

struct DocumentFidelityView: View {
    let document: Document
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fidelityService: DocumentFidelityService
    
    @State private var fidelityReport: FidelityReport?
    @State private var isLoading = false
    @State private var showTransferHistory = false
    @State private var showEditHistory = false
    @State private var showThreatDetails = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ScrollView {
            VStack(spacing: UnifiedTheme.Spacing.lg) {
                // Header
                VStack(spacing: UnifiedTheme.Spacing.sm) {
                    Text("Document Fidelity")
                        .font(theme.typography.title)
                        .foregroundColor(colors.textPrimary)
                    
                    Text(document.name)
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                }
                .padding(.top)
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let report = fidelityReport {
                    // Fidelity Score Card
                    StandardCard {
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            HStack {
                                Text("Fidelity Score")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                Spacer()
                                
                                // Score badge with color coding
                                ZStack {
                                    Circle()
                                        .fill(scoreColor(report.fidelityScore).opacity(0.2))
                                        .frame(width: 80, height: 80)
                                    
                                    VStack(spacing: 2) {
                                        Text("\(report.fidelityScore)")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(scoreColor(report.fidelityScore))
                                        
                                        Text("/100")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                }
                            }
                            
                            // Score interpretation
                            HStack {
                                Image(systemName: scoreIcon(report.fidelityScore))
                                    .foregroundColor(scoreColor(report.fidelityScore))
                                
                                Text(scoreDescription(report.fidelityScore))
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // Statistics
                    HStack(spacing: UnifiedTheme.Spacing.md) {
                        StatCard(
                            title: "Transfers",
                            value: "\(report.transferCount)",
                            icon: "arrow.triangle.2.circlepath",
                            color: colors.primary
                        )
                        
                        StatCard(
                            title: "Edits",
                            value: "\(report.editCount)",
                            icon: "pencil",
                            color: colors.secondary
                        )
                        
                        StatCard(
                            title: "Devices",
                            value: "\(report.uniqueDeviceCount)",
                            icon: "iphone",
                            color: colors.info
                        )
                    }
                    
                    // Threat Indicators
                    if !report.threatIndicators.isEmpty {
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(colors.warning)
                                    
                                    Text("Threat Indicators")
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Button {
                                        showThreatDetails = true
                                    } label: {
                                        Text("View All")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.primary)
                                    }
                                }
                                
                                ForEach(report.threatIndicators.prefix(3), id: \.detectedAt) { threat in
                                    ThreatIndicatorRow(threat: threat, colors: colors, theme: theme)
                                }
                                
                                if report.threatIndicators.count > 3 {
                                    Text("+ \(report.threatIndicators.count - 3) more")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                    
                    // Transfer History
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(colors.primary)
                                
                                Text("Transfer History")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                Spacer()
                                
                                if !report.transferHistory.isEmpty {
                                    Button {
                                        showTransferHistory = true
                                    } label: {
                                        Text("View All")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.primary)
                                    }
                                }
                            }
                            
                            if report.transferHistory.isEmpty {
                                Text("No transfers recorded")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textSecondary)
                                    .italic()
                            } else {
                                ForEach(report.transferHistory.prefix(3).reversed(), id: \.timestamp) { transfer in
                                    TransferHistoryRow(transfer: transfer, colors: colors, theme: theme)
                                }
                                
                                if report.transferHistory.count > 3 {
                                    Text("+ \(report.transferHistory.count - 3) more")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                    
                    // Edit History
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            HStack {
                                Image(systemName: "pencil")
                                    .foregroundColor(colors.primary)
                                
                                Text("Edit History")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                Spacer()
                                
                                if !report.editHistory.isEmpty {
                                    Button {
                                        showEditHistory = true
                                    } label: {
                                        Text("View All")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.primary)
                                    }
                                }
                            }
                            
                            if report.editHistory.isEmpty {
                                Text("No edits recorded")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textSecondary)
                                    .italic()
                            } else {
                                ForEach(report.editHistory.prefix(3).reversed(), id: \.timestamp) { edit in
                                    EditHistoryRow(edit: edit, colors: colors, theme: theme)
                                }
                                
                                if report.editHistory.count > 3 {
                                    Text("+ \(report.editHistory.count - 3) more")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                    
                    // Geographic Access Map (if locations available)
                    if report.transferHistory.contains(where: { $0.locationLatitude != nil }) ||
                       report.editHistory.contains(where: { $0.locationLatitude != nil }) {
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                HStack {
                                    Image(systemName: "map")
                                        .foregroundColor(colors.primary)
                                    
                                    Text("Access Locations")
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                }
                                
                                #if os(iOS)
                                FidelityMapView(
                                    transfers: report.transferHistory,
                                    edits: report.editHistory,
                                    colors: colors
                                )
                                .frame(height: 200)
                                .cornerRadius(UnifiedTheme.CornerRadius.md)
                                #else
                                // Map view not available on this platform
                                Text("Map view not available")
                                    .foregroundColor(colors.textSecondary)
                                    .frame(height: 200)
                                #endif
                            }
                        }
                    }
                } else {
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "No Fidelity Data",
                        message: "Fidelity tracking will begin when document is transferred or edited"
                    )
                }
            }
            .padding()
        }
        .background(colors.background)
        .navigationTitle("Document Fidelity")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await loadFidelityReport()
        }
        .sheet(isPresented: $showTransferHistory) {
            if let report = fidelityReport {
                TransferHistoryView(transfers: report.transferHistory)
            }
        }
        .sheet(isPresented: $showEditHistory) {
            if let report = fidelityReport {
                EditHistoryView(edits: report.editHistory)
            }
        }
        .sheet(isPresented: $showThreatDetails) {
            if let report = fidelityReport {
                ThreatDetailsView(threats: report.threatIndicators)
            }
        }
    }
    
    private func loadFidelityReport() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            fidelityReport = try await fidelityService.getFidelityReport(for: document)
        } catch {
            print("❌ Failed to load fidelity report: \(error.localizedDescription)")
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        if score < 50 {
            return .red
        } else if score < 70 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func scoreIcon(_ score: Int) -> String {
        if score < 50 {
            return "exclamationmark.triangle.fill"
        } else if score < 70 {
            return "exclamationmark.circle.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    private func scoreDescription(_ score: Int) -> String {
        if score < 50 {
            return "High risk - Multiple suspicious patterns detected"
        } else if score < 70 {
            return "Medium risk - Some unusual activity detected"
        } else {
            return "Low risk - Document appears authentic"
        }
    }
}

// MARK: - Supporting Views

struct ThreatIndicatorRow: View {
    let threat: ThreatIndicator
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.sm) {
            Image(systemName: severityIcon(threat.severity))
                .foregroundColor(severityColor(threat.severity))
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(threat.type.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                
                Text(threat.description)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(threat.severity.uppercased())
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(severityColor(threat.severity))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
    
    private func severityIcon(_ severity: String) -> String {
        switch severity {
        case "critical": return "exclamationmark.triangle.fill"
        case "high": return "exclamationmark.circle.fill"
        case "medium": return "info.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }
    
    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        default: return .green
        }
    }
}

struct TransferHistoryRow: View {
    let transfer: TransferEvent
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.sm) {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(colors.primary)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Transferred")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                
                Text(transfer.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                
                if let device = transfer.deviceInfo {
                    Text(device)
                        .font(theme.typography.caption2)
                        .foregroundColor(colors.textTertiary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EditHistoryRow: View {
    let edit: EditEvent
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.sm) {
            Image(systemName: "pencil.circle.fill")
                .foregroundColor(colors.primary)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Version \(edit.versionNumber)")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                
                if let change = edit.changeDescription {
                    Text(change)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(2)
                }
                
                Text(edit.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(theme.typography.caption2)
                    .foregroundColor(colors.textTertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#if os(iOS)
struct FidelityMapView: UIViewRepresentable {
    let transfers: [TransferEvent]
    let edits: [EditEvent]
    let colors: UnifiedTheme.Colors
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Add annotations for all locations
        var annotations: [MKAnnotation] = []
        var coordinates: [CLLocationCoordinate2D] = []
        
        for transfer in transfers {
            if let lat = transfer.locationLatitude, let lon = transfer.locationLongitude {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                coordinates.append(coordinate)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = "Transfer"
                annotation.subtitle = transfer.timestamp.formatted()
                annotations.append(annotation)
            }
        }
        
        for edit in edits {
            if let lat = edit.locationLatitude, let lon = edit.locationLongitude {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                coordinates.append(coordinate)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = "Edit v\(edit.versionNumber)"
                annotation.subtitle = edit.timestamp.formatted()
                annotations.append(annotation)
            }
        }
        
        mapView.addAnnotations(annotations)
        
        // Set region to show all locations
        if !coordinates.isEmpty {
            let region = MKCoordinateRegion(coordinates: coordinates)
            mapView.setRegion(region, animated: false)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "FidelityLocation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
    }
}
#endif

extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D]) {
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.01)
        )
        
        self.init(center: center, span: span)
    }
}

// MARK: - Detail Views

struct TransferHistoryView: View {
    let transfers: [TransferEvent]
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            List {
                ForEach(transfers.reversed(), id: \.timestamp) { transfer in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Transfer")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Spacer()
                            
                            Text(transfer.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        if let device = transfer.deviceInfo {
                            Text("Device: \(device)")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        if let reason = transfer.reason {
                            Text("Reason: \(reason)")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Transfer History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}

struct EditHistoryView: View {
    let edits: [EditEvent]
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            List {
                ForEach(edits.reversed(), id: \.timestamp) { edit in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Version \(edit.versionNumber)")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Spacer()
                            
                            Text(edit.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        if let change = edit.changeDescription {
                            Text(change)
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        if let device = edit.deviceInfo {
                            Text("Device: \(device)")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textTertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}

struct ThreatDetailsView: View {
    let threats: [ThreatIndicator]
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            List {
                ForEach(threats, id: \.detectedAt) { threat in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(threat.type.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Spacer()
                            
                            Text(threat.severity.uppercased())
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(severityColor(threat.severity))
                                .cornerRadius(4)
                        }
                        
                        Text(threat.description)
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                        
                        Text("Detected: \(threat.detectedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textTertiary)
                        
                        if let details = threat.details {
                            ForEach(Array(details.keys.sorted()), id: \.self) { key in
                                if let value = details[key] {
                                    Text("\(key): \(value)")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textTertiary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Threat Indicators")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
    
    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        default: return .green
        }
    }
}
