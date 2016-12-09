//
//  PhoneNumberUtils.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import XCTest
@testable import Vialer

class PhoneNumberUtilsTestCase: XCTestCase {

    func testPhoneNumberWithExtraZeroIsProperlyCleaned() {
        let number = PhoneNumberUtils.cleanPhoneNumber("+31(0)508009000")

        XCTAssertEqual(number, "+31508009000")
    }
}
