//
//  PhoneNumber.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation
import Contacts
import ContactsUI

/// Simple struct that contains information about a phone number.
struct PhoneNumber {

    /// The phone number that is matched
    let phoneNumber: String

    /// The type of the phone number.
    let type: String?

    /// The identifier for the contact store.
    let contactIdentifier: String

    /// The name that of the contact that can be shown in the UI.
    let callerName: String?
}

extension PhoneNumber {

    /// Custom initializer.
    ///
    /// - Parameters:
    ///   - number: CNLabeledValue of the CNPhoneNumber
    ///   - contact: The CNContact where the phonenumber belongs to.
    init(number:  CNLabeledValue<CNPhoneNumber>, contact: CNContact) {
        phoneNumber = PhoneNumberUtils.removePrefix(fromPhoneNumber: number.value.stringValue)
        if let label = number.label {
            type = CNLabeledValue<NSString>.localizedString(forLabel: label)
        } else {
            type = nil
        }
        callerName = CNContactFormatter.string(from: contact, style: .fullName)
        contactIdentifier = contact.identifier
    }
}
