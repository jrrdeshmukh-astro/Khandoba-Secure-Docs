//
//  SecurityReviewScheduler.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import Foundation
import Combine
import EventKit
import SwiftUI

@MainActor
final class SecurityReviewScheduler: ObservableObject {
    @Published var hasCalendarAccess = false
    @Published var scheduledReviews: [SecurityReview] = []
    
    private let eventStore = EKEventStore()
    private let calendar: EKCalendar?
    
    init() {
        self.calendar = findOrCreateSecurityCalendar()
        checkCalendarAccess()
    }
    
    // MARK: - Calendar Access
    
    func checkCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        hasCalendarAccess = (status == .authorized)
    }
    
    func requestCalendarAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestAccess(to: .event)
            await MainActor.run {
                hasCalendarAccess = granted
            }
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }
    
    // MARK: - Calendar Setup
    
    private func findOrCreateSecurityCalendar() -> EKCalendar? {
        // Try to find existing Khandoba calendar
        let calendars = eventStore.calendars(for: .event)
        if let existing = calendars.first(where: { $0.title == "Khandoba Security" }) {
            return existing
        }
        
        // Create new calendar
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = "Khandoba Security"
        newCalendar.cgColor = UIColor.red.cgColor
        
        if let source = eventStore.defaultCalendarForNewEvents?.source {
            newCalendar.source = source
            
            do {
                try eventStore.saveCalendar(newCalendar, commit: true)
                return newCalendar
            } catch {
                print("Error creating calendar: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    // MARK: - Schedule Reviews
    
    /// Schedule a security review
    func scheduleReview(
        for vault: Vault,
        frequency: ReviewFrequency,
        startDate: Date = Date()
    ) throws {
        guard hasCalendarAccess, let calendar = calendar else {
            throw SchedulerError.noCalendarAccess
        }
        
        let review = SecurityReview(
            id: UUID(),
            vaultID: vault.id,
            vaultName: vault.name,
            frequency: frequency,
            nextReview: calculateNextReviewDate(from: startDate, frequency: frequency)
        )
        
        // Create calendar event
        try createCalendarEvent(for: review)
        
        // Save to local storage
        scheduledReviews.append(review)
        saveScheduledReviews()
        
        print("✅ Scheduled \(frequency.rawValue) review for: \(vault.name)")
    }
    
    /// Schedule review based on threat level
    func scheduleAutomaticReview(for vault: Vault, threatLevel: ThreatLevel) throws {
        let frequency: ReviewFrequency
        
        switch threatLevel {
        case .critical:
            frequency = .daily
        case .high:
            frequency = .weekly
        case .medium:
            frequency = .biweekly
        case .low:
            frequency = .monthly
        }
        
        try scheduleReview(for: vault, frequency: frequency)
    }
    
    private func createCalendarEvent(for review: SecurityReview) throws {
        let event = EKEvent(eventStore: eventStore)
        event.title = "🔐 Security Review: \(review.vaultName)"
        event.notes = """
        Scheduled security review for \(review.vaultName) vault.
        
        Actions to perform:
        1. Review access logs
        2. Check for anomalies
        3. Verify document integrity
        4. Update access permissions
        5. Generate AI voice report
        
        Tap to open Khandoba and run analysis.
        """
        event.startDate = review.nextReview
        event.endDate = review.nextReview.addingTimeInterval(30 * 60) // 30 minutes
        event.calendar = calendar
        
        // Add alarm 15 minutes before
        let alarm = EKAlarm(relativeOffset: -15 * 60)
        event.addAlarm(alarm)
        
        // Set recurrence based on frequency
        let recurrenceRule: EKRecurrenceRule
        switch review.frequency {
        case .daily:
            recurrenceRule = EKRecurrenceRule(
                recurrenceWith: .daily,
                interval: 1,
                end: nil
            )
        case .weekly:
            recurrenceRule = EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 1,
                end: nil
            )
        case .biweekly:
            recurrenceRule = EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 2,
                end: nil
            )
        case .monthly:
            recurrenceRule = EKRecurrenceRule(
                recurrenceWith: .monthly,
                interval: 1,
                end: nil
            )
        case .quarterly:
            recurrenceRule = EKRecurrenceRule(
                recurrenceWith: .monthly,
                interval: 3,
                end: nil
            )
        }
        
        event.addRecurrenceRule(recurrenceRule)
        
        try eventStore.save(event, span: .futureEvents)
    }
    
    // MARK: - Calculate Dates
    
    private func calculateNextReviewDate(from date: Date, frequency: ReviewFrequency) -> Date {
        let calendar = Calendar.current
        
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        }
    }
    
    // MARK: - Persistence
    
    private func saveScheduledReviews() {
        if let encoded = try? JSONEncoder().encode(scheduledReviews) {
            UserDefaults.standard.set(encoded, forKey: "scheduled_reviews")
        }
    }
    
    private func loadScheduledReviews() {
        if let data = UserDefaults.standard.data(forKey: "scheduled_reviews"),
           let decoded = try? JSONDecoder().decode([SecurityReview].self, from: data) {
            scheduledReviews = decoded
        }
    }
    
    // MARK: - Manage Reviews
    
    func cancelReview(for vaultID: UUID) {
        scheduledReviews.removeAll { $0.vaultID == vaultID }
        saveScheduledReviews()
    }
    
    func updateReviewFrequency(for vaultID: UUID, newFrequency: ReviewFrequency) throws {
        guard let index = scheduledReviews.firstIndex(where: { $0.vaultID == vaultID }) else {
            return
        }
        
        var review = scheduledReviews[index]
        review.frequency = newFrequency
        review.nextReview = calculateNextReviewDate(from: Date(), frequency: newFrequency)
        
        scheduledReviews[index] = review
        saveScheduledReviews()
    }
}

// MARK: - Models

struct SecurityReview: Identifiable, Codable {
    let id: UUID
    let vaultID: UUID
    let vaultName: String
    var frequency: ReviewFrequency
    var nextReview: Date
    
    var isOverdue: Bool {
        nextReview < Date()
    }
    
    var daysUntilReview: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextReview).day ?? 0
    }
}

enum ReviewFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    
    var description: String {
        switch self {
        case .daily: return "Review every day"
        case .weekly: return "Review every week"
        case .biweekly: return "Review every 2 weeks"
        case .monthly: return "Review every month"
        case .quarterly: return "Review every 3 months"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar"
        case .biweekly: return "calendar.badge.clock"
        case .monthly: return "calendar.circle"
        case .quarterly: return "calendar.badge.plus"
        }
    }
}

enum SchedulerError: LocalizedError {
    case noCalendarAccess
    case calendarNotFound
    case eventCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .noCalendarAccess:
            return "Calendar access denied. Please enable in Settings."
        case .calendarNotFound:
            return "Could not find or create security calendar."
        case .eventCreationFailed:
            return "Failed to create calendar event."
        }
    }
}

// MARK: - Schedule Review View

struct ScheduleReviewView: View {
    let vault: Vault
    @StateObject private var scheduler = SecurityReviewScheduler()
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFrequency: ReviewFrequency = .monthly
    @State private var startDate = Date()
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            Form {
                Section("Review Frequency") {
                    ForEach(ReviewFrequency.allCases, id: \.self) { frequency in
                        Button {
                            selectedFrequency = frequency
                        } label: {
                            HStack {
                                Image(systemName: frequency.icon)
                                    .foregroundColor(colors.primary)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading) {
                                    Text(frequency.rawValue)
                                        .foregroundColor(colors.textPrimary)
                                    Text(frequency.description)
                                        .font(.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                if selectedFrequency == frequency {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(colors.success)
                                }
                            }
                        }
                    }
                }
                
                Section("Start Date") {
                    DatePicker("First Review", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    Button {
                        scheduleReview()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Schedule Review")
                            Spacer()
                        }
                    }
                    .buttonStyle(AnimatedButtonStyle(color: colors.primary))
                }
            }
            .navigationTitle("Schedule Security Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Security review scheduled successfully!")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func scheduleReview() {
        Task {
            if !scheduler.hasCalendarAccess {
                let granted = await scheduler.requestCalendarAccess()
                if !granted {
                    errorMessage = "Calendar access is required to schedule reviews."
                    showError = true
                    return
                }
            }
            
            do {
                try scheduler.scheduleReview(
                    for: vault,
                    frequency: selectedFrequency,
                    startDate: startDate
                )
                
                await MainActor.run {
                    showSuccess = true
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

