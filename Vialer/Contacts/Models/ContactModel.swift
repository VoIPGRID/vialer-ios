//
//  ContactModel.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import Foundation


@objc class ContactModel: NSObject {
    
    // MARK: - Properties
    
    /**
     Notification that is posted when reloading contacts is done.
    */
    @objc static let ContactsUpdated = Notification.Name(rawValue: "ContactModel.ContactsUpdated")
    
    @objc let concurrentContactQueue = DispatchQueue(label: "com.vialer.contactQueue", attributes: .concurrent)
    
    /**
     Singleton instance of ContactModel.
    */
    @objc static let defaultModel: ContactModel = {
        let model = ContactModel()
        let concurrentContactQueue = DispatchQueue(label: "com.vialer.contactQueue", attributes: .concurrent)
        
        concurrentContactQueue.async(flags: .barrier) {
            model.refreshContacts()
        }
        return model
    }()
    
    /**
     The section titles of all contacts.
    */
    @objc var sectionTitles: [String]?
    
    /**
     Current status of the access rights to the Contacts of the user.
    */
    @objc var authorizationStatus: CNAuthorizationStatus = .notDetermined
    
    /**
     The contact store that is used within this model.
    */
    @objc let contactStore = CNContactStore()
    
    /**
     The search results in one Array.
    */
    @objc var searchResult = [CNContact]()
    
    /**
     All the contacts fetched from the Store.
    */
    @objc var allContacts: [CNContact] {
        get {
            var allContacts = [CNContact]()
            for (_, contact) in contacts {
                allContacts += contact
            }
            return allContacts
        }
    }
    
    // Dictionary with phone numbers as keys and info about phonenumbers as value.
    var phoneNumbersToContacts = [String: PhoneNumber]()
    
    /**
     The sort order of the users contacts.
    */
    private lazy var sortOrder: CNContactSortOrder = {
        let comparator = CNContact.comparator(forNameSortOrder: .userDefault)
        let contact0 = CNMutableContact()
        contact0.givenName = "A"
        contact0.familyName = "Z"
        let contact1 = CNMutableContact()
        contact1.givenName = "Z"
        contact1.familyName = "A"
        let result = comparator(contact0, contact1)
        if result == .orderedAscending {
            return .givenName
        } else {
            return .familyName
        }
    }()
    
    private let keysToFetch: [CNKeyDescriptor] = [
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
        CNContactViewController.descriptorForRequiredKeys()
    ]
    
    /**
     Dictionary with First characters as keys and CNContacts arrays as values
    */
    private var contacts = [String: [CNContact]]()
    
    // MARK: - lifecycle
    
    override init() {
        super.init()
        // Listen to changes in contacts, and refresh if there was a change.
        NotificationCenter.default.addObserver(forName: Notification.Name.CNContactStoreDidChange, object: nil, queue: nil) { _ in
            self.concurrentContactQueue.async(flags: .barrier) {
                self.refreshContacts()
            }
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.CNContactStoreDidChange, object: nil)
    }
    
    
    // MARK: - Functions
    
    /**
     Return all the contacts at a section.
    */
    @objc func contactsAt(section: Int) -> [CNContact] {
        return contacts[sectionTitles![section]]!
    }
    
    /**
     Return the contact given the section and index.
    */
    @objc func contactAt(section: Int, index: Int) -> CNContact {
        return contactsAt(section: section)[index]
    }
    
    /**
     Will check if there is authorization to access the contacts.
     Will store the status in `authorizationStatus`.
    */
    @objc func hasContactAccess() -> Bool {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        switch authorizationStatus {
        case .authorized:
            return true
        case .notDetermined:
            return false
        case .denied:
            return false
        case .restricted:
            return false
        }
    }
    
    /**
     Will request contact access if not given and will load the contacts when given.
    */
    @objc func requestContactAccess() {
        contactStore.requestAccess(for: .contacts) { granted, error in
            if granted {
                self.concurrentContactQueue.async(flags: .barrier) {
                    self.refreshContacts()
                }
            }
        }
    }
    
    /**
     Creates an attributed string for the given contact.
     Based on the sort order of the users Contacts, the correct portion of the name will be made bold
     - parameters:
        - for: CNContact
     - returns: NSAttributed string with bolded name
    */
    @objc func attributedString(for contact: CNContact) -> NSAttributedString? {
        guard let attributedName = CNContactFormatter.attributedString(from: contact, style: .fullName, defaultAttributes: nil) else {
            if let fullName = CNContactFormatter.string(from: contact, style: .fullName) {
                return NSAttributedString(string: fullName)
            }
            if contact.emailAddresses.count > 0 {
                return NSAttributedString(string: contact.emailAddresses[0].value as String)
            }
            return nil
        }
        
        let keyToHighlight: String
        if contact.contactType == .person {
            keyToHighlight = sortOrder == .familyName ? CNContactFamilyNameKey : CNContactGivenNameKey
        } else {
            keyToHighlight = CNContactOrganizationNameKey
        }
        
        let highlightedName = attributedName.mutableCopy() as! NSMutableAttributedString
        highlightedName.enumerateAttributes(in: NSMakeRange(0, highlightedName.length), options: [], using: { (attrs, range, stop) in
            if let property = attrs[NSAttributedString.Key.init(CNContactPropertyAttribute)] as? String, property == keyToHighlight {
                let boldAttributes = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)]
                highlightedName.addAttributes(boldAttributes, range: range)
            }
        })
        return highlightedName
    }
    
    @objc func displayName(for contact: CNContact) -> String? {
        return attributedString(for: contact)?.string
    }
    
    // MARK: - Search
    
    @objc func searchContacts(for searchText: String) -> Bool {
        searchResult.removeAll()
        if searchText == "" {
            return false
        }
        if !hasContactAccess() {
            return false
        }
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        fetchRequest.sortOrder = sortOrder
        fetchRequest.predicate = CNContact.predicateForContacts(matchingName: searchText)
        do {
            try contactStore.enumerateContacts(with: fetchRequest) { contact, stop in
                self.searchResult.append(contact)
            }
        } catch let error {
            VialerLogError("Contact search error: \(error)")
            return false
        }
        return true
    }
    
    func getContact(for identifier: String) -> CNContact? {
        if !hasContactAccess() {
            return nil
        }
        return try? contactStore.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch)
    }
    
    // MARK: - Helper (private) functions
    
    /**
     Reload the contacts from the CNContactStore.
    */
    private func refreshContacts() {
        if !hasContactAccess() {
            return
        }

        // Clear current dictionary
        phoneNumbersToContacts.removeAll()

        var newContacts = [String: [CNContact]]()
        do {
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            request.sortOrder = sortOrder
            try contactStore.enumerateContacts(with: request) { contact, stop in
                let firstChar = self.getFirstChar(for: contact)
                var contactList: [CNContact]
                if newContacts[firstChar] != nil {
                    contactList = newContacts[firstChar]!
                } else {
                    contactList = [CNContact]()
                }
                contactList.append(contact)
                newContacts[firstChar] = contactList
                
                // Add every phone number to search dictionary.
                for number in contact.phoneNumbers {
                    let newNumber = PhoneNumber(number: number, contact: contact)
                    // Do not save contacts' phonenumbers which are less than 3 digits long
                    if (newNumber.phoneNumber.count > 2) {
                        self.phoneNumbersToContacts[newNumber.phoneNumber] = newNumber
                    }
                }
            }
            contacts = newContacts
            sectionTitles = Array(contacts.keys).sorted()
            if sectionTitles?.first == "#" {
                sectionTitles?.remove(at: 0)
                sectionTitles?.append("#")
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: ContactModel.ContactsUpdated, object: nil)
            }
        } catch let error {
            VialerLogError("Contact refresh error: \(error)")
        }
    }
    
    /**
     Returns the first character of the name of the contact.
     Gets the character based on the contact type and sort order of the user contacts.
     - parameters:
        - for: CNContact
     - returns: Optional String with the first character
    */
    private func getFirstChar(for contact: CNContact) -> String {
        var firstChar: Character?
        switch contact.contactType {
        case .organization:
            if let char = contact.organizationName.uppercased().replacingOccurrences(of: "(", with: "").first {
                firstChar = char
            } else {
                fallthrough
            }
        case .person:
            switch sortOrder {
            case .familyName:
                if let char = contact.familyName.uppercased().replacingOccurrences(of: "(", with: "").first {
                    firstChar = char
                } else {
                    fallthrough
                }
            default:
                if let char = contact.givenName.uppercased().replacingOccurrences(of: "(", with: "").first {
                    firstChar = char
                } else if let char = contact.familyName.uppercased().replacingOccurrences(of: "(", with: "").first {
                    firstChar = char
                } else if let char = contact.emailAddresses.first?.value.uppercased.first {
                    firstChar = char
                }
            }
        }
        if let char = firstChar, char >= "A" && char <= "Z" {
            return String(char)
        } else {
            return "#"
        }
    }
}
