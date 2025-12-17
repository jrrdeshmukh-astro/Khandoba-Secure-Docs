//
//  ContactDiscoveryService.swift
//  Khandoba Secure Docs
//
//  Service to discover which contacts are using the Khandoba app
//  Similar to WhatsApp's "Contacts on WhatsApp" feature
//

import Foundation
import Contacts
import CloudKit
import SwiftData
import Combine

@MainActor
final class ContactDiscoveryService: ObservableObject {
    @Published var registeredContacts: Set<String> = [] // Set of phone numbers/emails that are registered
    @Published var isDiscovering = false
    @Published var discoveryProgress: Double = 0.0
    
    private var modelContext: ModelContext?
    private let container: CKContainer
    
    nonisolated init() {
        let containerID = AppConfig.cloudKitContainer
        self.container = CKContainer(identifier: containerID)
    }
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Check if a contact is registered in Khandoba
    /// Returns true if the contact's phone or email matches a registered user
    func isContactRegistered(_ contact: CNContact) -> Bool {
        // Check phone numbers
        for phoneNumber in contact.phoneNumbers {
            let phone = phoneNumber.value.stringValue
            let normalizedPhone = normalizePhoneNumber(phone)
            if registeredContacts.contains(normalizedPhone) {
                return true
            }
        }
        
        // Check email addresses
        for emailAddress in contact.emailAddresses {
            let email = emailAddress.value as String
            if registeredContacts.contains(email.lowercased()) {
                return true
            }
        }
        
        return false
    }
    
    /// Discover which contacts from the user's contact list are registered in Khandoba
    /// Uses CloudKit to query for users by phone/email
    func discoverRegisteredContacts() async {
        guard let modelContext = modelContext else {
            print("⚠️ ContactDiscoveryService: ModelContext not configured")
            return
        }
        
        await MainActor.run {
            isDiscovering = true
            discoveryProgress = 0.0
        }
        
        do {
            // Get all contacts from the user's contact list
            // Move contact enumeration to background thread to avoid blocking main thread
            let contacts = try await Task.detached(priority: .userInitiated) {
                let store = CNContactStore()
                let keysToFetch: [CNKeyDescriptor] = [
                    CNContactPhoneNumbersKey,
                    CNContactEmailAddressesKey
                ] as [CNKeyDescriptor]
                
                let request = CNContactFetchRequest(keysToFetch: keysToFetch)
                var fetchedContacts: [CNContact] = []
                
                try store.enumerateContacts(with: request) { contact, stop in
                    fetchedContacts.append(contact)
                    // Continue enumerating (don't stop)
                }
                
                return fetchedContacts
            }.value
            
            print("📱 ContactDiscoveryService: Found \(contacts.count) contacts to check")
            
            // Extract all phone numbers and emails
            var phoneNumbers: Set<String> = []
            var emails: Set<String> = []
            
            for contact in contacts {
                // Normalize and add phone numbers
                for phoneNumber in contact.phoneNumbers {
                    let normalized = normalizePhoneNumber(phoneNumber.value.stringValue)
                    if !normalized.isEmpty {
                        phoneNumbers.insert(normalized)
                    }
                }
                
                // Add email addresses
                for emailAddress in contact.emailAddresses {
                    let email = emailAddress.value as String
                    if !email.isEmpty {
                        emails.insert(email.lowercased())
                    }
                }
            }
            
            print("📱 ContactDiscoveryService: Checking \(phoneNumbers.count) phone numbers and \(emails.count) email addresses")
            
            // Query CloudKit for registered users
            let database = container.privateCloudDatabase
            var registeredIdentifiers: Set<String> = []
            
            // Query by email addresses
            if !emails.isEmpty {
                let emailArray = Array(emails)
                let emailPredicate = NSPredicate(format: "email IN %@", emailArray)
                let emailQuery = CKQuery(recordType: "CD_User", predicate: emailPredicate)
                
                do {
                    let (matchResults, _) = try await database.records(matching: emailQuery)
                    
                    for (_, result) in matchResults {
                        if case .success(let record) = result,
                           let email = record["email"] as? String {
                            registeredIdentifiers.insert(email.lowercased())
                        }
                    }
                } catch {
                    print("⚠️ ContactDiscoveryService: Error querying by email: \(error.localizedDescription)")
                }
            }
            
            // Query by phone numbers (if we store phone numbers in User model)
            // Note: Currently User model doesn't have phone numbers, but we can add this later
            // For now, we'll primarily use email matching
            
            // Also check local SwiftData users
            let localUsers = try modelContext.fetch(FetchDescriptor<User>())
            for user in localUsers {
                if let email = user.email {
                    registeredIdentifiers.insert(email.lowercased())
                }
            }
            
            await MainActor.run {
                registeredContacts = registeredIdentifiers
                isDiscovering = false
                discoveryProgress = 1.0
            }
            
            print("✅ ContactDiscoveryService: Found \(registeredIdentifiers.count) registered contacts")
        } catch {
            print("❌ ContactDiscoveryService: Error discovering contacts: \(error.localizedDescription)")
            await MainActor.run {
                isDiscovering = false
            }
        }
    }
    
    /// Normalize phone number for comparison
    /// Removes spaces, dashes, parentheses, and country codes
    private func normalizePhoneNumber(_ phone: String) -> String {
        // Remove all non-digit characters
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Remove leading country codes (common ones)
        // This is a simplified version - you might want to use a proper phone number library
        if digits.hasPrefix("1") && digits.count > 10 {
            // US/Canada country code
            return String(digits.dropFirst())
        } else if digits.hasPrefix("91") && digits.count > 10 {
            // India country code
            return String(digits.dropFirst(2))
        }
        
        // Return last 10 digits (standard phone number length)
        if digits.count >= 10 {
            return String(digits.suffix(10))
        }
        
        return digits
    }
    
    /// Quick check if a specific phone number or email is registered
    func checkIfRegistered(phone: String? = nil, email: String? = nil) -> Bool {
        if let phone = phone {
            let normalized = normalizePhoneNumber(phone)
            if registeredContacts.contains(normalized) {
                return true
            }
        }
        
        if let email = email {
            if registeredContacts.contains(email.lowercased()) {
                return true
            }
        }
        
        return false
    }
}

