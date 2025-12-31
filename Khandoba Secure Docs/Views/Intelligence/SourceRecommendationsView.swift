//
//  SourceRecommendationsView.swift
//  Khandoba Secure Docs
//
//  AI-suggested source recommendations view
//

import SwiftUI

struct SourceRecommendationsView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @StateObject private var learningAgent = LearningAgentService.shared
    
    @State private var recommendations: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.lg) {
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                Text("Recommended Sources")
                                    .font(theme.typography.headline)
                                
                                if isLoading {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                } else if recommendations.isEmpty {
                                    Text("No recommendations available")
                                        .font(theme.typography.body)
                                        .foregroundColor(colors.textSecondary)
                                } else {
                                    ForEach(recommendations, id: \.self) { source in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(colors.success)
                                            Text(source)
                                                .font(theme.typography.body)
                                            Spacer()
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        Button {
                            Task {
                                await loadRecommendations()
                            }
                        } label: {
                            Text("Refresh Recommendations")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isLoading)
                        .padding()
                    }
                    .padding()
                }
                .navigationTitle("Source Recommendations")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .onAppear {
            configureService()
            Task {
                await loadRecommendations()
            }
        }
    }
    
    private func configureService() {
        learningAgent.configure(
            modelContext: modelContext,
            formalLogicEngine: FormalLogicEngine(),
            inferenceEngine: InferenceEngine()
        )
    }
    
    private func loadRecommendations() async {
        isLoading = true
        defer { isLoading = false }
        
        recommendations = await learningAgent.getRecommendedSources(for: vault.id)
    }
}

