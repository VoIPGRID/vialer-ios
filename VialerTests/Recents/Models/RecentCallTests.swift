//
//  RecentCallTests.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import XCTest
@testable import Vialer

class RecentCallTests: XCTestCase {

    let exampleDictionary: JSONDictionary = ["src_number": "+3150809000",
                                            "callerid": "VoIPGRID",
                                            "call_date": "2017-03-15T09:41:27",
                                            "direction": "inbound",
                                            "dst_number": "+31508009064",
                                            "dialed_number": "+31508009064",
                                            "atime": Int16(42),
                                            "id": Int64(123456789)]
    var coreDataStack: CoreDataStack!
    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(modelNamed: "Vialer", inMemory: true)
    }
    
    override func tearDown() {
        super.tearDown()
        coreDataStack = nil
    }

    func testRecentInboundCallIsSuppressed() {
        var dictionary = exampleDictionary
        dictionary["src_number"] = "xxxxxxx"
        let call = RecentCall.findOrCreate(for: dictionary, in: coreDataStack.mainContext)!

        XCTAssertTrue(call.suppressed, "Call should be suppressed")
    }

    func testRecentInboundCallIsNotSuppressed() {
        let call = RecentCall.findOrCreate(for: exampleDictionary, in: coreDataStack.mainContext)!

        XCTAssertFalse(call.suppressed, "Call should not be suppressed")
    }

    func testOutboundCallIsNeverSuppressed() {
        var dictionary = exampleDictionary
        dictionary["src_number"] = "xxxxxxx"
        dictionary["direction"] = "outbound"
        let call = RecentCall.findOrCreate(for: dictionary, in: coreDataStack.mainContext)!

        XCTAssertFalse(call.suppressed, "Call should not be suppressed")
    }

    func testOutboundCallIsNotSuppressed() {
        var dictionary = exampleDictionary
        dictionary["direction"] = "outbound"
        let call = RecentCall.findOrCreate(for: dictionary, in: coreDataStack.mainContext)!

        XCTAssertFalse(call.suppressed, "Call should not be suppressed")
    }

    func testNoDuplicateCallsWillBeCreated() {
        let call = RecentCall.findOrCreate(for: exampleDictionary, in: coreDataStack.mainContext)!
        let secondCall = RecentCall.findOrCreate(for: exampleDictionary, in: coreDataStack.mainContext)!

        XCTAssertEqual(call, secondCall, "Only one RecentCall should have been created.")
    }
}
