//
//  IngestionConfigurationView.swift
//  Khandoba Secure Docs
//
//  Intelligent ingestion configuration view
//

import SwiftUI

struct IngestionConfigurationView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var ingestionService = IntelligentIngestionService.shared
    
    @State private var topicName: String = ""
    @State private var topicDescription: String = ""
    @State private var keywords: [String] = []
    @State private var newKeyword: String = ""
    @State private var selectedFrameworks: Set<ComplianceFramework> = []
    @State private var selectedSources: Set<String> = []
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                Form {
                    Section("Topic Configuration") {
                        TextField("Topic Name", text: $topicName)
                        TextField("Description", text: $topicDescription, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    
                    Section("Keywords") {
                        ForEach(keywords, id: \.self) { keyword in
                            HStack {
                                Text(keyword)
                                Spacer()
                                Button {
                                    keywords.removeAll { $0 == keyword }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(colors.error)
                                }
                            }
                        }
                        
                        HStack {
                            TextField("Add keyword", text: $newKeyword)
                            Button("Add") {
                                if !newKeyword.isEmpty {
                                    keywords.append(newKeyword)
                                    newKeyword = ""
                                }
                            }
                        }
                    }
                    
                    Section("Compliance Frameworks") {
                        ForEach(ComplianceFramework.allCases, id: \.self) { framework in
                            Toggle(framework.displayName, isOn: Binding(
                                get: { selectedFrameworks.contains(framework) },
                                set: { isOn in
                                    if isOn {
                                        selectedFrameworks.insert(framework)
                                    } else {
                                        selectedFrameworks.remove(framework)
                                    }
                                }
                            ))
                        }
                    }
                    
                    Section("Data Sources") {
                        // iCloud services - always available
                        Toggle("iCloud Drive", isOn: Binding(
                            get: { selectedSources.contains("icloud_drive") },
                            set: { isOn in
                                if isOn {
                                    selectedSources.insert("icloud_drive")
                                } else {
                                    selectedSources.remove("icloud_drive")
                                }
                            }
                        ))
                        
                        Toggle("iCloud Photos", isOn: Binding(
                            get: { selectedSources.contains("icloud_photos") },
                            set: { isOn in
                                if isOn {
                                    selectedSources.insert("icloud_photos")
                                } else {
                                    selectedSources.remove("icloud_photos")
                                }
                            }
                        ))
                        
                        Toggle("iCloud Mail", isOn: Binding(
                            get: { selectedSources.contains("icloud_mail") },
                            set: { isOn in
                                if isOn {
                                    selectedSources.insert("icloud_mail")
                                } else {
                                    selectedSources.remove("icloud_mail")
                                }
                            }
                        ))
                    }
                }
                .navigationTitle("Ingestion Configuration")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveConfiguration()
                            dismiss()
                        }
                        .disabled(topicName.isEmpty)
                    }
                }
            }
        }
        .onAppear {
            loadExistingConfiguration()
        }
    }
    
    private func loadExistingConfiguration() {
        if let topic = ingestionService.getTopic(for: vault.id) {
            topicName = topic.topicName
            topicDescription = topic.topicDescription ?? ""
            keywords = topic.keywords
            selectedFrameworks = Set(topic.complianceFrameworks.compactMap { ComplianceFramework(rawValue: $0) })
            selectedSources = Set(topic.dataSources)
        }
    }
    
    private func saveConfiguration() {
        try? ingestionService.configureTopic(
            vaultID: vault.id,
            topicName: topicName,
            topicDescription: topicDescription.isEmpty ? nil : topicDescription,
            keywords: keywords,
            categories: [], // Would be configured separately
            complianceFrameworks: Array(selectedFrameworks),
            dataSources: Array(selectedSources)
        )
    }
}

