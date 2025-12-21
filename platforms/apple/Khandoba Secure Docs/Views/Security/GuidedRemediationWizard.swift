//
//  GuidedRemediationWizard.swift
//  Khandoba Secure Docs
//
//  Interactive guided remediation flow with questions and actions
//

import SwiftUI
import SwiftData

struct GuidedRemediationWizard: View {
    @ObservedObject var triageService: AutomaticTriageService
    let onComplete: () -> Void
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    @State private var currentAnswer = ""
    @State private var isExecutingAction = false
    @State private var showActionConfirmation = false
    @State private var selectedAction: RemediationAction?
    
    private var currentFlow: RemediationFlow? {
        triageService.currentRemediationFlow
    }
    
    private var currentQuestion: String? {
        guard let flow = currentFlow,
              flow.currentStep < flow.triageResult.questions.count else { return nil }
        return flow.triageResult.questions[flow.currentStep]
    }
    
    private var hasMoreQuestions: Bool {
        guard let flow = currentFlow else { return false }
        return flow.currentStep < flow.triageResult.questions.count
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        if let flow = currentFlow {
                            // Threat Summary
                            ThreatSummaryCard(result: flow.triageResult)
                                .padding(.horizontal)
                            
                            // Progress Indicator
                            ProgressIndicator(
                                currentStep: flow.currentStep + 1,
                                totalSteps: flow.triageResult.questions.count + flow.recommendedActions.count
                            )
                            .padding(.horizontal)
                            
                            // Current Question
                            if let question = currentQuestion {
                                QuestionCard(
                                    question: question,
                                    answer: $currentAnswer,
                                    onAnswer: {
                                        submitAnswer(question)
                                    }
                                )
                                .padding(.horizontal)
                            } else {
                                // Show recommended actions
                                RecommendedActionsCard(
                                    actions: flow.recommendedActions,
                                    completedActions: flow.completedActions,
                                    onExecute: { action in
                                        selectedAction = action
                                        showActionConfirmation = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                            
                            // Completed Actions
                            if !flow.completedActions.isEmpty {
                                CompletedActionsCard(actions: flow.completedActions)
                                    .padding(.horizontal)
                            }
                        } else {
                            Text("No active remediation flow")
                                .foregroundColor(theme.colors(for: colorScheme).textSecondary)
                                .padding()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Guided Remediation")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button("Skip") {
                        dismiss()
                        onComplete()
                    }
                    .foregroundColor(colors.textSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                        onComplete()
                    }
                    .foregroundColor(colors.primary)
                    .disabled(hasMoreQuestions)
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Skip") {
                        dismiss()
                        onComplete()
                    }
                    .foregroundColor(colors.textSecondary)
                }
                
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                        onComplete()
                    }
                    .foregroundColor(colors.primary)
                    .disabled(hasMoreQuestions)
                }
                #endif
            }
            .alert("Execute Action", isPresented: $showActionConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Execute") {
                    if let action = selectedAction {
                        executeAction(action)
                    }
                }
            } message: {
                if let action = selectedAction {
                    Text(actionDescription(action))
                }
            }
        }
    }
    
    private func submitAnswer(_ question: String) {
        guard !currentAnswer.isEmpty, let flow = currentFlow else { return }
        
        Task {
            await triageService.answerQuestion(question, answer: currentAnswer, in: flow)
            currentAnswer = ""
            // Flow is automatically updated via @ObservedObject
        }
    }
    
    private func executeAction(_ action: RemediationAction) {
        guard let flow = currentFlow else { return }
        
        isExecutingAction = true
        
        Task {
            do {
                try await triageService.executeAction(action, in: flow)
                // Flow is automatically updated via @ObservedObject
                await MainActor.run {
                    isExecutingAction = false
                }
            } catch {
                print(" Failed to execute action: \(error.localizedDescription)")
                await MainActor.run {
                    isExecutingAction = false
                }
            }
        }
    }
    
    private func actionDescription(_ action: RemediationAction) -> String {
        switch action {
        case .closeAllVaults:
            return "This will immediately close all vaults and end all active sessions. Continue?"
        case .lockVault:
            return "This will lock the affected vault and end all active sessions. Continue?"
        case .revokeNominees:
            return "This will revoke access for the selected nominees. They will no longer be able to access the vault. Continue?"
        case .revokeAllNominees:
            return "This will revoke access for ALL nominees across all vaults. Continue?"
        case .revokeAllSessions:
            return "This will end all active vault sessions. Users will need to unlock vaults again. Continue?"
        case .redactDocuments:
            return "This will permanently redact sensitive information from the selected documents. This cannot be undone. Continue?"
        case .restrictDocumentAccess:
            return "This will archive the selected documents, restricting access. Continue?"
        case .changeVaultPassword:
            return "This will require you to set a new password for the vault. Continue?"
        case .changeAllPasswords:
            return "This will require you to set new passwords for all vaults. Continue?"
        case .recordMonitoringIP:
            return "This will record the monitoring IP address in the access logs. Continue?"
        case .reviewAccessLogs:
            return "This will navigate to the access logs view. Continue?"
        case .reviewDocumentSharing:
            return "This will navigate to document sharing settings. Continue?"
        case .enableDualKeyProtection:
            return "This will enable dual-key protection for all vaults, requiring two approvals for access. Continue?"
        case .enableEnhancedMonitoring:
            return "Enhanced monitoring is already enabled. Continue?"
        }
    }
}

// MARK: - Threat Summary Card

struct ThreatSummaryCard: View {
    let result: TriageResult
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: iconForType(result.type))
                        .foregroundColor(result.severity.color)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title)
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text(result.severity.rawValue)
                            .font(theme.typography.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(result.severity.color)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                Text(result.description)
                    .font(theme.typography.body)
                    .foregroundColor(colors.textPrimary)
                
                if let entities = result.affectedEntities, !entities.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Affected:")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                            .fontWeight(.semibold)
                        
                        ForEach(entities, id: \.self) { entity in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(colors.error)
                                Text(entity)
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textPrimary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                
                HStack {
                    Label("Vault: \(result.vaultName)", systemImage: "lock.shield.fill")
                        .font(theme.typography.caption2)
                        .foregroundColor(colors.textTertiary)
                    
                    Spacer()
                    
                    Text(result.detectedAt, style: .relative)
                        .font(theme.typography.caption2)
                        .foregroundColor(colors.textTertiary)
                }
            }
        }
    }
    
    private func iconForType(_ type: TriageResultType) -> String {
        switch type {
        case .screenMonitoring: return "eye.slash.fill"
        case .compromisedNominee: return "person.crop.circle.badge.xmark"
        case .sensitiveDocuments: return "doc.text.fill"
        case .dataLeak: return "arrow.up.doc.fill"
        case .bruteForce: return "bolt.shield.fill"
        case .unauthorizedAccess: return "lock.triangle.fill"
        case .suspiciousActivity: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Progress Indicator

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let progress = Double(currentStep) / Double(max(totalSteps, 1))
        
        VStack(spacing: UnifiedTheme.Spacing.xs) {
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.primary)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colors.surface.opacity(0.5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colors.primary)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Question Card

struct QuestionCard: View {
    let question: String
    @Binding var answer: String
    let onAnswer: () -> Void
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(colors.info)
                    
                    Text("Question")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                }
                
                Divider()
                
                Text(question)
                    .font(theme.typography.body)
                    .foregroundColor(colors.textPrimary)
                    .padding(.vertical, 4)
                
                TextField("Your answer...", text: $answer, axis: .vertical)
                    .font(theme.typography.body)
                    .lineLimit(2...5)
                    .padding()
                    .background(colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                
                Button {
                    onAnswer()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(answer.isEmpty)
            }
        }
    }
}

// MARK: - Recommended Actions Card

struct RecommendedActionsCard: View {
    let actions: [RemediationAction]
    let completedActions: [RemediationAction]
    let onExecute: (RemediationAction) -> Void
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(colors.success)
                    
                    Text("Recommended Actions")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                }
                
                Divider()
                
                if actions.isEmpty {
                    Text("All recommended actions have been completed.")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                        .padding(.vertical)
                } else {
                    ForEach(actions) { action in
                        if !completedActions.contains(action) {
                            ActionRow(
                                action: action,
                                onExecute: { onExecute(action) }
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Action Row

struct ActionRow: View {
    let action: RemediationAction
    let onExecute: () -> Void
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack {
            Image(systemName: iconForAction(action))
                .foregroundColor(actionColor(action))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(actionTitle(action))
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                    .fontWeight(.semibold)
                
                Text(actionDescription(action))
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button {
                onExecute()
            } label: {
                Text("Execute")
                    .font(theme.typography.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.vertical, 8)
    }
    
    private func iconForAction(_ action: RemediationAction) -> String {
        switch action {
        case .closeAllVaults, .lockVault: return "lock.fill"
        case .revokeNominees, .revokeAllNominees: return "person.crop.circle.badge.xmark"
        case .revokeAllSessions: return "xmark.circle.fill"
        case .redactDocuments: return "eye.slash.fill"
        case .restrictDocumentAccess: return "archivebox.fill"
        case .changeVaultPassword, .changeAllPasswords: return "key.fill"
        case .recordMonitoringIP: return "network"
        case .reviewAccessLogs: return "list.bullet.rectangle"
        case .reviewDocumentSharing: return "person.2.fill"
        case .enableDualKeyProtection: return "lock.shield.fill"
        case .enableEnhancedMonitoring: return "chart.bar.fill"
        }
    }
    
    private func actionColor(_ action: RemediationAction) -> Color {
        let colors = theme.colors(for: colorScheme)
        switch action {
        case .closeAllVaults, .lockVault, .revokeAllSessions:
            return colors.error
        case .revokeNominees, .revokeAllNominees:
            return colors.warning
        case .redactDocuments, .restrictDocumentAccess:
            return colors.info
        default:
            return colors.primary
        }
    }
    
    private func actionTitle(_ action: RemediationAction) -> String {
        switch action {
        case .closeAllVaults: return "Close All Vaults"
        case .lockVault: return "Lock Vault"
        case .revokeNominees: return "Revoke Nominees"
        case .revokeAllNominees: return "Revoke All Nominees"
        case .revokeAllSessions: return "Revoke All Sessions"
        case .redactDocuments: return "Redact Documents"
        case .restrictDocumentAccess: return "Restrict Document Access"
        case .changeVaultPassword: return "Change Vault Password"
        case .changeAllPasswords: return "Change All Passwords"
        case .recordMonitoringIP: return "Record Monitoring IP"
        case .reviewAccessLogs: return "Review Access Logs"
        case .reviewDocumentSharing: return "Review Document Sharing"
        case .enableDualKeyProtection: return "Enable Dual-Key Protection"
        case .enableEnhancedMonitoring: return "Enable Enhanced Monitoring"
        }
    }
    
    private func actionDescription(_ action: RemediationAction) -> String {
        switch action {
        case .closeAllVaults: return "Immediately close all vaults and end sessions"
        case .lockVault: return "Lock the affected vault"
        case .revokeNominees: return "Revoke access for compromised nominees"
        case .revokeAllNominees: return "Revoke access for all nominees"
        case .revokeAllSessions: return "End all active vault sessions"
        case .redactDocuments: return "Permanently redact sensitive information"
        case .restrictDocumentAccess: return "Archive documents to restrict access"
        case .changeVaultPassword: return "Set a new password for the vault"
        case .changeAllPasswords: return "Set new passwords for all vaults"
        case .recordMonitoringIP: return "Record IP address in access logs"
        case .reviewAccessLogs: return "Review recent access activity"
        case .reviewDocumentSharing: return "Review document sharing settings"
        case .enableDualKeyProtection: return "Require two approvals for access"
        case .enableEnhancedMonitoring: return "Enable advanced threat monitoring"
        }
    }
}

// MARK: - Completed Actions Card

struct CompletedActionsCard: View {
    let actions: [RemediationAction]
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(colors.success)
                    
                    Text("Completed Actions")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                }
                
                Divider()
                
                ForEach(actions) { action in
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(colors.success)
                        
                        Text(actionTitle(action))
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    private func actionTitle(_ action: RemediationAction) -> String {
        switch action {
        case .closeAllVaults: return "Closed all vaults"
        case .lockVault: return "Locked vault"
        case .revokeNominees: return "Revoked nominees"
        case .revokeAllNominees: return "Revoked all nominees"
        case .revokeAllSessions: return "Revoked all sessions"
        case .redactDocuments: return "Redacted documents"
        case .restrictDocumentAccess: return "Restricted document access"
        case .changeVaultPassword: return "Changed vault password"
        case .changeAllPasswords: return "Changed all passwords"
        case .recordMonitoringIP: return "Recorded monitoring IP"
        case .reviewAccessLogs: return "Reviewed access logs"
        case .reviewDocumentSharing: return "Reviewed document sharing"
        case .enableDualKeyProtection: return "Enabled dual-key protection"
        case .enableEnhancedMonitoring: return "Enabled enhanced monitoring"
        }
    }
}
