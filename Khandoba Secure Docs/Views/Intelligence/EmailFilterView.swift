//
//  EmailFilterView.swift
//  Khandoba Secure Docs
//
//  Email filtering view
//

import SwiftUI

struct EmailFilterView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Binding var filter: EmailFilter
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFolders: Set<String> = []
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var sender: String = ""
    @State private var subject: String = ""
    @State private var hasAttachments: Bool?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                Form {
                    Section("Folders") {
                        // Folder selection would be provider-specific
                        Text("Folder selection")
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Section("Date Range") {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                    
                    Section("Filters") {
                        TextField("Sender", text: $sender)
                        TextField("Subject", text: $subject)
                        
                        Toggle("Has Attachments", isOn: Binding(
                            get: { hasAttachments == true },
                            set: { hasAttachments = $0 ? true : nil }
                        ))
                    }
                }
                .navigationTitle("Email Filter")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Apply") {
                            applyFilter()
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            loadFilter()
        }
    }
    
    private func loadFilter() {
        selectedFolders = Set(filter.folders)
        if let dateRange = filter.dateRange {
            startDate = dateRange.start
            endDate = dateRange.end
        }
        sender = filter.sender ?? ""
        subject = filter.subject ?? ""
        hasAttachments = filter.hasAttachments
    }
    
    private func applyFilter() {
        filter.folders = Array(selectedFolders)
        filter.dateRange = EmailFilter.DateRange(start: startDate, end: endDate)
        filter.sender = sender.isEmpty ? nil : sender
        filter.subject = subject.isEmpty ? nil : subject
        filter.hasAttachments = hasAttachments
    }
}

