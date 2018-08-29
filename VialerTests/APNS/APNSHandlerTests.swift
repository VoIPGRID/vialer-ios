//
//  APNSTests.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import XCTest
@testable import Vialer

class APNSHandlerTests: XCTestCase {

    var apnsHandler: APNSHandler = APNSHandler.shared

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func test_MiddlewareGetter() {
        /// Test if the Middleware has been created.
        XCTAssert(apnsHandler.middleware .isKind(of: Middleware.self))
    }
}
