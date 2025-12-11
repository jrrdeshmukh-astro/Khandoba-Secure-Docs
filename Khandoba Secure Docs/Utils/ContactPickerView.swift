//
//  ContactPickerView.swift
//  Khandoba Secure Docs
//
//  Contact picker for iMessage sharing

import SwiftUI
import Contacts
import ContactsUI
import MessageUI
import Combine

struct ContactPickerView: UIViewControllerRepresentable {
    let vault: Vault
    let onContactsSelected: ([CNContact]) -> Void
    let onDismiss: () -> Void
    let contactDiscovery: ContactDiscoveryService?
    
    init(
        vault: Vault,
        onContactsSelected: @escaping ([CNContact]) -> Void,
        onDismiss: @escaping () -> Void,
        contactDiscovery: ContactDiscoveryService? = nil
    ) {
        self.vault = vault
        self.onContactsSelected = onContactsSelected
        self.onDismiss = onDismiss
        self.contactDiscovery = contactDiscovery
    }
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        // Request all properties we need to access
        picker.displayedPropertyKeys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey
        ]
        // Allow contacts with either phone or email
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0 OR emailAddresses.@count > 0")
        // Enable multiple selection
        picker.predicateForSelectionOfContact = NSPredicate(value: true) // Allow all contacts to be selected
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerView
        
        init(_ parent: ContactPickerView) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            // The picker will dismiss itself automatically
            // We need to delay the callback slightly to ensure the picker dismisses first
            // but the parent sheet (UnifiedAddNomineeView) stays open
            
            // Use the contacts directly from the picker - they already have the needed properties
            // Only try to fetch full details if we're missing critical information
            var fullContacts: [CNContact] = []
            let store = CNContactStore()
            
            for contact in contacts {
                // Check if we already have the needed properties
                let hasName = !contact.givenName.isEmpty || !contact.familyName.isEmpty
                let hasPhoneOrEmail = !contact.phoneNumbers.isEmpty || !contact.emailAddresses.isEmpty
                
                if hasName && hasPhoneOrEmail {
                    // We have enough info, use the contact as-is
                    fullContacts.append(contact)
                } else {
                    // Try to fetch full details, but don't fail if it doesn't work
                    do {
                        let keysToFetch: [CNKeyDescriptor] = [
                            CNContactGivenNameKey,
                            CNContactFamilyNameKey,
                            CNContactPhoneNumbersKey,
                            CNContactEmailAddressesKey
                        ] as [CNKeyDescriptor]
                        
                        // Only fetch if we have a valid identifier
                        if !contact.identifier.isEmpty {
                            let fullContact = try store.unifiedContact(
                                withIdentifier: contact.identifier,
                                keysToFetch: keysToFetch
                            )
                            fullContacts.append(fullContact)
                        } else {
                            // No identifier, use contact as-is
                            fullContacts.append(contact)
                        }
                    } catch {
                        // Contact might have been deleted or identifier is invalid
                        // Use the contact we have - it should still have basic info
                        print("⚠️ Could not fetch full contact details (contact may have been deleted): \(error.localizedDescription)")
                        print("   Using contact as-is with available properties")
                        fullContacts.append(contact)
                    }
                }
            }
            
            // Check which contacts are registered in Khandoba (on main actor)
            let contactsToCheck = fullContacts
            Task { @MainActor in
                let parent = self.parent
                if let discovery = parent.contactDiscovery {
                    let registeredContacts = contactsToCheck.filter { contact in
                        discovery.isContactRegistered(contact)
                    }
                    
                    if !registeredContacts.isEmpty {
                        print("✅ Found \(registeredContacts.count) contact(s) already on Khandoba:")
                        for contact in registeredContacts {
                            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                            print("   - \(name)")
                        }
                    }
                }
            }
            
            // Callback immediately - the contact picker dismisses itself
            // The parent form (UnifiedAddNomineeView) will stay open with populated fields
            // User can then click "Create Nominee & Share" button
            self.parent.onContactsSelected(fullContacts)
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            // Handle single contact selection (legacy method - should use didSelect contacts instead)
            // Use the contact directly - it should already have the needed properties
            let hasName = !contact.givenName.isEmpty || !contact.familyName.isEmpty
            let hasPhoneOrEmail = !contact.phoneNumbers.isEmpty || !contact.emailAddresses.isEmpty
            
            if hasName && hasPhoneOrEmail {
                // We have enough info, use the contact as-is
                self.parent.onContactsSelected([contact])
            } else {
                // Try to fetch full details only if needed
                let store = CNContactStore()
                do {
                    let keysToFetch: [CNKeyDescriptor] = [
                        CNContactGivenNameKey,
                        CNContactFamilyNameKey,
                        CNContactPhoneNumbersKey,
                        CNContactEmailAddressesKey
                    ] as [CNKeyDescriptor]
                    
                    // Only fetch if we have a valid identifier
                    if !contact.identifier.isEmpty {
                        let fullContact = try store.unifiedContact(
                            withIdentifier: contact.identifier,
                            keysToFetch: keysToFetch
                        )
                        self.parent.onContactsSelected([fullContact])
                    } else {
                        // No identifier, use contact as-is
                        self.parent.onContactsSelected([contact])
                    }
                } catch {
                    print("⚠️ Could not fetch full contact details (contact may have been deleted): \(error.localizedDescription)")
                    print("   Using contact as-is with available properties")
                    // Fallback: use the contact as-is
                    self.parent.onContactsSelected([contact])
                }
            }
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.onDismiss()
        }
    }
}

// Helper to request contacts permission
class ContactsPermissionManager: ObservableObject {
    @Published var hasPermission = false
    @Published var permissionStatus: CNAuthorizationStatus = .notDetermined
    
    init() {
        checkPermission()
    }
    
    func checkPermission() {
        permissionStatus = CNContactStore.authorizationStatus(for: .contacts)
        hasPermission = (permissionStatus == .authorized)
    }
    
    func requestPermission() async -> Bool {
        let store = CNContactStore()
        
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                hasPermission = granted
                checkPermission()
            }
            return granted
        } catch {
            print("Contacts permission error: \(error)")
            return false
        }
    }
}

// Message composer for sending via iMessage
struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let message: String
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = context.coordinator
        composer.recipients = recipients
        composer.body = message
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposeView
        
        init(_ parent: MessageComposeView) {
            self.parent = parent
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            parent.onDismiss()
        }
    }
}

