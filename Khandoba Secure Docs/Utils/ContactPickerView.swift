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
            
            // Fetch full contact details for all selected contacts
            let store = CNContactStore()
            var fullContacts: [CNContact] = []
            
            for contact in contacts {
                do {
                    // Fetch the full contact with all needed properties
                    let keysToFetch: [CNKeyDescriptor] = [
                        CNContactGivenNameKey,
                        CNContactFamilyNameKey,
                        CNContactPhoneNumbersKey,
                        CNContactEmailAddressesKey
                    ] as [CNKeyDescriptor]
                    
                    let fullContact = try store.unifiedContact(
                        withIdentifier: contact.identifier,
                        keysToFetch: keysToFetch
                    )
                    fullContacts.append(fullContact)
                } catch {
                    print("⚠️ Failed to fetch full contact details: \(error.localizedDescription)")
                    // Fallback: use the contact as-is (may have limited properties)
                    fullContacts.append(contact)
                }
            }
            
            // Check which contacts are registered in Khandoba (on main actor)
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let discovery = self.parent.contactDiscovery {
                    let registeredContacts = fullContacts.filter { contact in
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
            
            // Delay callback slightly to let the contact picker dismiss first
            // This prevents the parent sheet from also dismissing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.parent.onContactsSelected(fullContacts)
            }
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            // Handle single contact selection
            // Delay callback slightly to let the contact picker dismiss first
            let store = CNContactStore()
            
            do {
                // Fetch the full contact with all needed properties
                let keysToFetch: [CNKeyDescriptor] = [
                    CNContactGivenNameKey,
                    CNContactFamilyNameKey,
                    CNContactPhoneNumbersKey,
                    CNContactEmailAddressesKey
                ] as [CNKeyDescriptor]
                
                let fullContact = try store.unifiedContact(
                    withIdentifier: contact.identifier,
                    keysToFetch: keysToFetch
                )
                
                // Delay callback to prevent parent sheet from dismissing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.parent.onContactsSelected([fullContact])
                }
            } catch {
                print("⚠️ Failed to fetch full contact details: \(error.localizedDescription)")
                // Fallback: use the contact as-is
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.parent.onContactsSelected([contact])
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

