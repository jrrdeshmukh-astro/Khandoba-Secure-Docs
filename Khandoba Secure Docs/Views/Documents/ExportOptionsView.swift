//
//  ExportOptionsView.swift
//  Khandoba Secure Docs
//
//  Export options configuration view
//

import SwiftUI

struct ExportOptionsView: View {
    let documents: [Document]
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var exportService = ExportService.shared
    
    @State private var options = ExportOptions()
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                Form {
                    Section("Export Options") {
                        Toggle("Include Documents", isOn: $options.includeDocuments)
                        Toggle("Include Metadata", isOn: $options.includeMetadata)
                        Toggle("Include Audit Logs", isOn: $options.includeAuditLogs)
                        Toggle("Include Compliance Reports", isOn: $options.includeComplianceReports)
                    }
                    
                    Section("Format") {
                        Picker("Format", selection: $options.format) {
                            Text("ZIP").tag(ExportOptions.ExportFormat.zip)
                            Text("PDF").tag(ExportOptions.ExportFormat.pdf)
                            Text("JSON").tag(ExportOptions.ExportFormat.json)
                        }
                    }
                    
                    Section {
                        Button {
                            Task {
                                await performExport()
                            }
                        } label: {
                            HStack {
                                if isExporting {
                                    ProgressView()
                                } else {
                                    Text("Export")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isExporting)
                    }
                }
                .navigationTitle("Export Options")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ExportShareSheet(items: [url])
            }
        }
        .onAppear {
            exportService.configure(
                modelContext: modelContext,
                complianceEngineService: ComplianceEngineService.shared
            )
        }
    }
    
    private func performExport() async {
        isExporting = true
        defer { isExporting = false }
        
        do {
            let url = try await exportService.exportDocuments(documents: documents, options: options)
            exportURL = url
            showShareSheet = true
        } catch {
            print("Export failed: \(error)")
        }
    }
}

private struct ExportShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

