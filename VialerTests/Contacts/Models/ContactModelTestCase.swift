//
//  ContactModelTestCase.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import XCTest

@testable import Vialer

class ContactModelTestCase: XCTestCase {

    var contactModel: ContactModel!

    override func setUp() {
        super.setUp()
        contactModel = ContactModel()
    }

    func contactToTest() -> CNContact {
        let contact = CNMutableContact()
        contact.givenName = "John"
        contact.familyName = "Appleseed"
        return contact
    }

    func testFamilyNameIsBoldForContact() {
        let styledContact = contactModel.attributedString(for: contactToTest())!

        let fontAtFamilyName = styledContact.attribute(kCTFontAttributeName as NSAttributedStringKey, at: 6, effectiveRange:nil) as! UIFont

        XCTAssertEqual(fontAtFamilyName, UIFont.boldSystemFont(ofSize: 17.0))
    }

    func testGivenNameIsNotBoldForContact() {
        let styledContact = contactModel.attributedString(for: contactToTest())!

        XCTAssertNil(styledContact.attribute(kCTFontAttributeName as NSAttributedStringKey, at: 1, effectiveRange: nil) as? UIFont)
    }

    func testEmailAddressIsGivenWhenThereIsNoName() {
        let contact = CNMutableContact()
        contact.emailAddresses = [CNLabeledValue(label:nil, value: "info@test.com")]
        let styledContact = contactModel.attributedString(for:contact)

        XCTAssertEqual(styledContact!.string, "info@test.com")
    }
}
