//
//  RecentCallManagerTests.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import XCTest
@testable import Vialer

class RecentCallManagerTests: XCTestCase {

    var coreDataStack: CoreDataStack!
    var sut: RecentCallManager!
    var webservice: WebserviceMock!

    let exampleDictionary: JSONDictionary = [
        "src_number": "+3150809000",
        "callerid": "VoIPGRID",
        "call_date": "2017-03-15T09:41:27",
        "direction": "inbound",
        "dst_number": "+31508009064",
        "dialed_number": "+31508009064",
        "atime": Int16(42),
        "id": Int64(123456789),
    ]

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(modelNamed: "Vialer", inMemory: true)
        webservice = WebserviceMock()
        sut = RecentCallManager(managedContext: coreDataStack.mainContext, webservice: webservice)
    }
    
    override func tearDown() {
        super.tearDown()
        coreDataStack = nil
    }

    func testWhenCreatedSUTIsNotReloading() {
        XCTAssertFalse(sut.reloading)
    }

    func testWhenCreatedThereIsNoError() {
        XCTAssertNil(sut.recentsFetchErrorCode)
        XCTAssertFalse(sut.recentsFetchFailed)
    }

    func testWhenGettingLatestCallsTwiceWillOnlyReloadOnce() {
        sut.getLatestRecentCalls { _ in }
        sut.getLatestRecentCalls { _ in }
        XCTAssertEqual(webservice.count, 1, "Should only fetch once")
    }

    func testGettingLatestCallsWillHaveDateOfLastMonth() {
        sut.getLatestRecentCalls { _ in }

        let resource = webservice.latestResource as! Resource<[JSONDictionary]>
        let date = resource.parameters!["call_date__gte"] as! String
        let aMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        XCTAssertTrue(date.date!.almostEqual(to: aMonthAgo), "Should have fetched with limit a month ago.")
    }

    func testGettingLatestCallsWillUseTheDateOfTheMostRecentCall() {
        let aDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        var dictionary = exampleDictionary
        dictionary["call_date"] = aDayAgo.apiFormatted24hCET
        _ = RecentCall.findOrCreate(for: dictionary, in: coreDataStack.mainContext)

        sut.getLatestRecentCalls { _ in }

        let resource = webservice.latestResource as! Resource<[JSONDictionary]>
        let date = resource.parameters!["call_date__gte"] as! String
        let aDayAndOneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: aDayAgo)!
        XCTAssertTrue(date.date!.almostEqual(to: aDayAndOneHourAgo), "Should have fetched with limit a day and one hour ago.")
    }

    func testGettingLatestCallsWithForbiddenErrorWillReturnError() {
        webservice.result = Result<[JSONDictionary]?>.failure(WebserviceError.forbidden)

        sut.getLatestRecentCalls { error in
            XCTAssertEqual(error, RecentCallManager.RecentCallManagerError.fetchNotAllowed, "Should have returned error.")
        }

        XCTAssertEqual(sut.recentsFetchErrorCode, RecentCallManager.RecentCallManagerError.fetchNotAllowed, "Should have set an error.")
        XCTAssertFalse(sut.recentsFetchFailed)
    }

    func testGettingLatestCallsWithOtherErrorWillReturnError() {
        webservice.result = Result<[JSONDictionary]?>.failure(WebserviceError.other("test"))

        sut.getLatestRecentCalls { error in
            XCTAssertEqual(error, RecentCallManager.RecentCallManagerError.fetchFailed, "Should have returned error.")
        }

        XCTAssertEqual(sut.recentsFetchErrorCode, RecentCallManager.RecentCallManagerError.fetchFailed, "Should have set an error.")
        XCTAssertFalse(sut.recentsFetchFailed)
    }

    func testGettingLatestCallsWillNotReturnAnError() {
        webservice.result = Result<[JSONDictionary]?>.success([exampleDictionary])

        sut.getLatestRecentCalls { error in
            XCTAssertNil(error, "There should be no error")
        }
    }

    func testGettingLatestCallsWillStoreCallInCoreData() {
        webservice.result = Result<[JSONDictionary]?>.success([exampleDictionary])

        sut.getLatestRecentCalls { _ in }

        let call = RecentCall.fetchLatest(in: coreDataStack.mainContext)

        XCTAssertNotNil(call)
        XCTAssertEqual(call?.callID, exampleDictionary["id"] as? Int64, "The correct call should have been stored.")
    }
}

final class WebserviceMock: WebserviceProtocol {
    var result: Any?
    var count = 0
    var latestResource: Any?
    func load<A>(resource: Resource<A>, completion: @escaping (Result<A?>) -> ()) {
        latestResource = resource
        count += 1
        if let result = result as? Result<A?> {
            completion(result)
        }
    }
}

extension Date {
    func almostEqual(to other: Date) -> Bool {
        return abs(self.timeIntervalSince(other)) < 2
    }
}
