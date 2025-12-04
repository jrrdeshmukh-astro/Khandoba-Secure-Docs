//
//  DocumentVersionHistoryView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct DocumentVersionHistoryView: View {
    let document: Document
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @State private var showRestoreConfirm = false
    @State private var selectedVersion: DocumentVersion?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let versions = document.versions ?? []
        let currentVersionNumber = versions.count + 1
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            if versions.isEmpty {
                // When there are no previous versions
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "No Version History",
                    message: "This is the first version of this document"
                )
            } else {
                List {
                    // Current Version
                    Section("Current Version") {
                        VersionRow(
                            versionNumber: currentVersionNumber,
                            date: document.lastModifiedAt ?? document.uploadedAt,
                            fileSize: document.fileSize,
                            isCurrent: true,
                            changes: "Current version"
                        )
                    }
                    
                    // Previous Versions
                    Section("Previous Versions") {
                        ForEach(versions.sorted { $0.versionNumber > $1.versionNumber }) { version in
                            Button {
                                selectedVersion = version
                                showRestoreConfirm = true
                            } label: {
                                VersionRow(
                                    versionNumber: version.versionNumber,
                                    date: version.createdAt,
                                    fileSize: version.fileSize,
                                    isCurrent: false,
                                    changes: version.changes ?? "No changes recorded"
                                )
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(colors.background)
            }
        }
        .navigationTitle("Version History")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Restore Version", isPresented: $showRestoreConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Restore") {
                restoreVersion()
            }
        } message: {
            if let version = selectedVersion {
                Text("Restore version \(version.versionNumber)? This will create a new version with the old content.")
            } else {
                Text("") // Provide a fallback to satisfy ViewBuilder
            }
        }
    }
    
    private func restoreVersion() {
        guard let version = selectedVersion else { return }
        
        // Create new version from current
        let newVersion = DocumentVersion(
            versionNumber: (document.versions ?? []).count + 1,
            fileSize: document.fileSize,
            changes: "Restored from version \(version.versionNumber)"
        )
        newVersion.encryptedFileData = document.encryptedFileData
        newVersion.document = document
        
        // Restore old version data to current
        document.encryptedFileData = version.encryptedFileData
        document.fileSize = version.fileSize
        document.lastModifiedAt = Date()
        
        modelContext.insert(newVersion)
        try? modelContext.save()
    }
}

struct VersionRow: View {
    let versionNumber: Int
    let date: Date
    let fileSize: Int64
    let isCurrent: Bool
    let changes: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack(spacing: UnifiedTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(isCurrent ? colors.success.opacity(0.2) : colors.textTertiary.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text("v\(versionNumber)")
                    .font(theme.typography.caption)
                    .foregroundColor(isCurrent ? colors.success : colors.textSecondary)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Version \(versionNumber)")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                    
                    if isCurrent {
                        Text("CURRENT")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(colors.success)
                            .cornerRadius(4)
                    }
                }
                
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                
                Text(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                    .font(theme.typography.caption2)
                    .foregroundColor(colors.textTertiary)
                
                if !changes.isEmpty {
                    Text(changes)
                        .font(theme.typography.caption2)
                        .foregroundColor(colors.textSecondary)
                        .italic()
                }
            }
            
            Spacer()
            
            if !isCurrent {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(colors.primary)
            }
        }
        .padding(.vertical, UnifiedTheme.Spacing.xs)
    }
}
