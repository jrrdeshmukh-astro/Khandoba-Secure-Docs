//
//  ABTestingService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class ABTestingService: ObservableObject {
    static let shared = ABTestingService()
    
    @Published var activeTests: [ABTest] = []
    @Published var userVariants: [String: String] = [:] // testID: variantID
    
    private let userDefaults = UserDefaults.standard
    private let variantsKey = "ab_test_variants"
    private let eventsKey = "ab_test_events"
    
    init() {
        loadUserVariants()
        setupDefaultTests()
    }
    
    // MARK: - Test Setup
    
    private func setupDefaultTests() {
        // Test 1: Subscription Pricing Display
        let pricingTest = ABTest(
            id: "pricing_display_v1",
            name: "Subscription Pricing Display",
            variants: [
                ABVariant(id: "control", name: "Monthly First", weight: 0.5),
                ABVariant(id: "variant_a", name: "Yearly First", weight: 0.5)
            ],
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        )
        
        // Test 2: Threat Alert Style
        let alertTest = ABTest(
            id: "threat_alert_style_v1",
            name: "Threat Alert Display Style",
            variants: [
                ABVariant(id: "control", name: "Banner Style", weight: 0.33),
                ABVariant(id: "variant_a", name: "Modal Style", weight: 0.33),
                ABVariant(id: "variant_b", name: "Inline Style", weight: 0.34)
            ],
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        )
        
        // Test 3: Voice Report CTA
        let voiceReportTest = ABTest(
            id: "voice_report_cta_v1",
            name: "Voice Report Call-to-Action",
            variants: [
                ABVariant(id: "control", name: "Generate Report", weight: 0.5),
                ABVariant(id: "variant_a", name: "Get AI Analysis", weight: 0.5)
            ],
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        )
        
        activeTests = [pricingTest, alertTest, voiceReportTest]
    }
    
    // MARK: - Variant Assignment
    
    /// Get variant for a test (automatically assigns if not already assigned)
    func getVariant(for testID: String) -> String {
        // Check if user already has a variant
        if let existingVariant = userVariants[testID] {
            return existingVariant
        }
        
        // Find test
        guard let test = activeTests.first(where: { $0.id == testID }),
              test.isActive else {
            return "control"
        }
        
        // Assign new variant based on weights
        let variant = assignVariant(for: test)
        userVariants[testID] = variant.id
        saveUserVariants()
        
        // Track assignment event
        trackEvent("test_assigned", properties: [
            "test_id": testID,
            "variant_id": variant.id
        ])
        
        print("🧪 A/B Test: \(testID) → \(variant.id)")
        
        return variant.id
    }
    
    private func assignVariant(for test: ABTest) -> ABVariant {
        let random = Double.random(in: 0..<1)
        var cumulativeWeight = 0.0
        
        for variant in test.variants {
            cumulativeWeight += variant.weight
            if random < cumulativeWeight {
                return variant
            }
        }
        
        return test.variants.first!
    }
    
    // MARK: - Event Tracking
    
    func trackEvent(_ eventName: String, properties: [String: Any] = [:]) {
        var events = loadEvents()
        
        let event = ABEvent(
            name: eventName,
            properties: properties,
            timestamp: Date()
        )
        
        events.append(event)
        saveEvents(events)
        
        print("📊 Event: \(eventName)")
    }
    
    /// Track conversion event with test context
    func trackConversion(_ conversionName: String, testID: String? = nil) {
        var properties: [String: Any] = ["conversion": conversionName]
        
        if let testID = testID,
           let variant = userVariants[testID] {
            properties["test_id"] = testID
            properties["variant_id"] = variant
        }
        
        // Add all active test variants to conversion
        for (testId, variantId) in userVariants {
            properties["test_\(testId)"] = variantId
        }
        
        trackEvent("conversion", properties: properties)
    }
    
    // MARK: - Test-Specific Methods
    
    /// Check if should show yearly plan first in subscription view
    func shouldShowYearlyFirst() -> Bool {
        getVariant(for: "pricing_display_v1") == "variant_a"
    }
    
    /// Get threat alert style
    func getThreatAlertStyle() -> ThreatAlertStyle {
        let variant = getVariant(for: "threat_alert_style_v1")
        switch variant {
        case "variant_a": return .modal
        case "variant_b": return .inline
        default: return .banner
        }
    }
    
    /// Get voice report CTA text
    func getVoiceReportCTAText() -> String {
        let variant = getVariant(for: "voice_report_cta_v1")
        return variant == "variant_a" ? "Get AI Analysis" : "Generate Report"
    }
    
    // MARK: - Analytics
    
    func getTestResults(for testID: String) -> ABTestResults? {
        guard let test = activeTests.first(where: { $0.id == testID }) else {
            return nil
        }
        
        let events = loadEvents()
        var variantStats: [String: ABVariantStats] = [:]
        
        for variant in test.variants {
            let assigned = events.filter {
                $0.name == "test_assigned" &&
                $0.properties["test_id"] as? String == testID &&
                $0.properties["variant_id"] as? String == variant.id
            }.count
            
            let conversions = events.filter {
                $0.name == "conversion" &&
                $0.properties["test_\(testID)"] as? String == variant.id
            }.count
            
            let conversionRate = assigned > 0 ? Double(conversions) / Double(assigned) : 0.0
            
            variantStats[variant.id] = ABVariantStats(
                variantID: variant.id,
                assignments: assigned,
                conversions: conversions,
                conversionRate: conversionRate
            )
        }
        
        return ABTestResults(
            testID: testID,
            testName: test.name,
            variantStats: variantStats,
            startDate: test.startDate,
            endDate: test.endDate
        )
    }
    
    // MARK: - Persistence
    
    private func loadUserVariants() {
        if let data = userDefaults.data(forKey: variantsKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            userVariants = decoded
        }
    }
    
    private func saveUserVariants() {
        if let encoded = try? JSONEncoder().encode(userVariants) {
            userDefaults.set(encoded, forKey: variantsKey)
        }
    }
    
    private func loadEvents() -> [ABEvent] {
        if let data = userDefaults.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([ABEvent].self, from: data) {
            return decoded
        }
        return []
    }
    
    private func saveEvents(_ events: [ABEvent]) {
        // Keep only last 1000 events
        let trimmedEvents = Array(events.suffix(1000))
        if let encoded = try? JSONEncoder().encode(trimmedEvents) {
            userDefaults.set(encoded, forKey: eventsKey)
        }
    }
}

// MARK: - Models

struct ABTest: Identifiable {
    let id: String
    let name: String
    let variants: [ABVariant]
    let startDate: Date
    let endDate: Date
    
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
}

struct ABVariant {
    let id: String
    let name: String
    let weight: Double // 0.0 to 1.0
}

struct ABEvent: Codable {
    let name: String
    let properties: [String: String]
    let timestamp: Date
    
    init(name: String, properties: [String: Any], timestamp: Date) {
        self.name = name
        self.timestamp = timestamp
        
        // Convert properties to String dictionary
        var stringProps: [String: String] = [:]
        for (key, value) in properties {
            stringProps[key] = "\(value)"
        }
        self.properties = stringProps
    }
}

struct ABTestResults {
    let testID: String
    let testName: String
    let variantStats: [String: ABVariantStats]
    let startDate: Date
    let endDate: Date
    
    var winningVariant: String? {
        variantStats.max(by: { $0.value.conversionRate < $1.value.conversionRate })?.key
    }
}

struct ABVariantStats {
    let variantID: String
    let assignments: Int
    let conversions: Int
    let conversionRate: Double
}

enum ThreatAlertStyle {
    case banner
    case modal
    case inline
}

// MARK: - View Helpers

extension View {
    /// Apply A/B test variant styling
    func abTestVariant<T: View>(
        testID: String,
        control: () -> T,
        variant: () -> T
    ) -> some View {
        let abService = ABTestingService.shared
        let userVariant = abService.getVariant(for: testID)
        
        return Group {
            if userVariant == "control" {
                control()
            } else {
                variant()
            }
        }
    }
}

// MARK: - Analytics Dashboard View

struct ABTestDashboardView: View {
    @StateObject private var abService = ABTestingService.shared
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            List {
                ForEach(abService.activeTests) { test in
                    Section(test.name) {
                        if let results = abService.getTestResults(for: test.id) {
                            ForEach(test.variants, id: \.id) { variant in
                                if let stats = results.variantStats[variant.id] {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(variant.name)
                                                .font(.headline)
                                            
                                            Spacer()
                                            
                                            if results.winningVariant == variant.id {
                                                Text("🏆 Winner")
                                                    .font(.caption)
                                                    .foregroundColor(colors.success)
                                            }
                                        }
                                        
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("Assignments")
                                                    .font(.caption)
                                                    .foregroundColor(colors.textSecondary)
                                                Text("\(stats.assignments)")
                                                    .font(.title3)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .leading) {
                                                Text("Conversions")
                                                    .font(.caption)
                                                    .foregroundColor(colors.textSecondary)
                                                Text("\(stats.conversions)")
                                                    .font(.title3)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .leading) {
                                                Text("Rate")
                                                    .font(.caption)
                                                    .foregroundColor(colors.textSecondary)
                                                Text(String(format: "%.1f%%", stats.conversionRate * 100))
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(colors.success)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("A/B Tests")
        }
    }
}

