//
//  ReachabilityBasViewControllerTests.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation
import XCTest

@testable import Vialer

/// TEST NEEDS FIXING WHEN THE SYSTEMUSER HAS BEEN WRITTEN IN SWIFT!
class ReachabilityBarViewControllerTests: XCTestCase {

    /// Offline: Statusbar displays: "No connection, cannot call".
    func test_SipNotAllowedOffline() {
        let status : NetworkStatus = .notReachable
        let sipEnabled: Bool = false
        let statusBarIsHidden: Bool = false
        let twoStepButtonIsHidden: Bool = true

        let expectedInformationLabelText = NSLocalizedString("No connection, cannot call.", comment: "")

        performReachabilityBarUpdateLayoutTest(reachabilityStatus: status, sipEnabled: sipEnabled, expectedInformationLabelText: expectedInformationLabelText, twoStepButtonIsHidden: twoStepButtonIsHidden, statusBarIsHidden: statusBarIsHidden)
    }

    /// User is "allowed to SIP" but has disbaled VoIP in the settings:
    /// 3G+: Statusbar displays: "VoIP disabled, enable in settings".
    func test_SipAllowedButDisabled3GPlusConnection() {
        let status: NetworkStatus = .reachableVia3GPlus
        let sipEnabled: Bool = false
        let statusBarIsHidden: Bool = false
        let twoStepButtonIsHidden: Bool = true

        let expectedInformationLabelText = NSLocalizedString("VoIP disabled, enable in settings", comment: "")

         performReachabilityBarUpdateLayoutTest(reachabilityStatus: status, sipEnabled: sipEnabled, expectedInformationLabelText: expectedInformationLabelText, twoStepButtonIsHidden: twoStepButtonIsHidden, statusBarIsHidden: statusBarIsHidden)
    }

    /// User is "allowed to SIP" but has disbaled VoIP in the settings:
    /// 4G: Statusbar displays: "VoIP disabled, enable in settings".
    func test_SipAllowedButDisabled4GConnection() {
        let status: NetworkStatus = .reachableVia4G
        let sipEnabled: Bool = false
        let statusBarIsHidden: Bool = false
        let twoStepButtonIsHidden: Bool = true

        let expectedInformationLabelText = NSLocalizedString("VoIP disabled, enable in settings", comment: "")

        performReachabilityBarUpdateLayoutTest(reachabilityStatus: status, sipEnabled: sipEnabled, expectedInformationLabelText: expectedInformationLabelText, twoStepButtonIsHidden: twoStepButtonIsHidden, statusBarIsHidden: statusBarIsHidden)
    }

    /// User is "allowed to SIP" but has disbaled VoIP in the settings:
    /// WiFi: Statusbar displays: "VoIP disabled, enable in settings".
    func test_SipAllowedButDisabledWiFiConnection() {
        let status: NetworkStatus = .reachableViaWiFi
        let sipEnabled: Bool = false
        let statusBarIsHidden: Bool = false
        let twoStepButtonIsHidden: Bool = true

        let expectedInformationLabelText = NSLocalizedString("VoIP disabled, enable in settings", comment: "")

        performReachabilityBarUpdateLayoutTest(reachabilityStatus: status, sipEnabled: sipEnabled, expectedInformationLabelText: expectedInformationLabelText, twoStepButtonIsHidden: twoStepButtonIsHidden, statusBarIsHidden: statusBarIsHidden)
    }

    func test_SipAllowedButDisabledOffline() {
        let status: NetworkStatus = .notReachable
        let sipEnabled: Bool = false
        let statusBarIsHidden: Bool = false
        let twoStepButtonIsHidden: Bool = true

        let expectedInformationLabelText = NSLocalizedString("No connection, cannot call.", comment: "")

        performReachabilityBarUpdateLayoutTest(reachabilityStatus: status, sipEnabled: sipEnabled, expectedInformationLabelText: expectedInformationLabelText, twoStepButtonIsHidden: twoStepButtonIsHidden, statusBarIsHidden: statusBarIsHidden)
    }

    /// User is "allowed to SIP" and has enabled VoIP in the settings:
    /// 3G: Statusbar displays: "Poor connection, Two step calling enabled".
    func test_SipAllowedAndEnabledBut3GConnection() {
        let status: NetworkStatus = .reachableVia3G
        let sipEnabled: Bool = true
        let statusBarIsHidden: Bool = false
        let twoStepButtonIsHidden: Bool = false

        let expectedInformationLabelText = NSLocalizedString("Poor connection, Two step calling enabled.", comment: "")

        performReachabilityBarUpdateLayoutTest(reachabilityStatus: status, sipEnabled: sipEnabled, expectedInformationLabelText: expectedInformationLabelText, twoStepButtonIsHidden: twoStepButtonIsHidden, statusBarIsHidden: statusBarIsHidden)
    }

    /// User is "allowed to SIP" and has enabled VoIP in the settings:
    /// 2G: Statusbar displays: "Poor connection, Two step calling enabled".
    func test_SipAllowedAndEnabledBut2GConnection() {
        let status: NetworkStatus = .reachableVia3G
        let sipEnabled: Bool = true
        let statusBarIsHidden: Bool = false
        let twoStepButtonIsHidden: Bool = false

        let expectedInformationLabelText = NSLocalizedString("Poor connection, Two step calling enabled.", comment: "")

        performReachabilityBarUpdateLayoutTest(reachabilityStatus: status, sipEnabled: sipEnabled, expectedInformationLabelText: expectedInformationLabelText, twoStepButtonIsHidden: twoStepButtonIsHidden, statusBarIsHidden: statusBarIsHidden)
    }

    /// User is "allowed to SIP" and has enabled VoIP in the settings:
    /// WiFi: Status bar is hidden
    func test_SipAllowedAndEnabledAndWiFiConnection() {
        let status: NetworkStatus = .reachableViaWiFi
        let sipEnabled: Bool = true
        let statusBarIsHidden: Bool = true
        let twoStepButtonIsHidden: Bool = true

        let expectedInformationLabelText = ""

        performReachabilityBarUpdateLayoutTest(reachabilityStatus: status, sipEnabled: sipEnabled, expectedInformationLabelText: expectedInformationLabelText, twoStepButtonIsHidden: twoStepButtonIsHidden, statusBarIsHidden: statusBarIsHidden)
    }

    /// User is "allowed to SIP" and has enabled VoIP in the settings:
    /// 4G: Status bar is hidden
    func test_SipAllowedAndEnabledAnd4GConnection() {
        let status: NetworkStatus = .reachableVia4G
        let sipEnabled: Bool = true
        let statusBarIsHidden: Bool = true
        let twoStepButtonIsHidden: Bool = true

        let expectedInformationLabelText = ""

        performReachabilityBarUpdateLayoutTest(reachabilityStatus: status, sipEnabled: sipEnabled, expectedInformationLabelText: expectedInformationLabelText, twoStepButtonIsHidden: twoStepButtonIsHidden, statusBarIsHidden: statusBarIsHidden)
    }

    /// User is "allowed to SIP" and has enabled VoIP in the settings:
    /// 3G+: Status bar is hidden
    func test_SipAllowedAndEnabledAnd3GPlusConnection() {
        let status: NetworkStatus = .reachableVia3GPlus
        let sipEnabled: Bool = true
        let statusBarIsHidden: Bool = true
        let twoStepButtonIsHidden: Bool = true

        let expectedInformationLabelText = ""

        performReachabilityBarUpdateLayoutTest(reachabilityStatus: status, sipEnabled: sipEnabled, expectedInformationLabelText: expectedInformationLabelText, twoStepButtonIsHidden: twoStepButtonIsHidden, statusBarIsHidden: statusBarIsHidden)
    }

    fileprivate func performReachabilityBarUpdateLayoutTest(reachabilityStatus: NetworkStatus, sipEnabled: Bool, expectedInformationLabelText: String, twoStepButtonIsHidden: Bool, statusBarIsHidden: Bool) {


        let reachabilityBarViewControllerUnderTest: ReachabilityBarViewController = ReachabilityBarViewController()

        let mockReachability = ReachabilityMock(true)!
        reachabilityBarViewControllerUnderTest.reachability = mockReachability

//        let mockCurrentUser = SystemUserMock()
//        reachabilityBarViewControllerUnderTest.currentUser = mockCurrentUser

        let mockInformationLabel = LabelMock()
        mockInformationLabel.textToShow = expectedInformationLabelText
        reachabilityBarViewControllerUnderTest.informationLabel = mockInformationLabel

        let mockTwoStepButton = ButtonMock()
        mockTwoStepButton.buttonHidden = twoStepButtonIsHidden
        reachabilityBarViewControllerUnderTest.twoStepButton = mockTwoStepButton

        /// Given
        mockReachability.statusToReturn = reachabilityStatus

        XCTAssertTrue(reachabilityBarViewControllerUnderTest.informationLabel.text!.isEqual(expectedInformationLabelText))

        reachabilityBarViewControllerUnderTest.updateLayout()

        let mockInformationLabelExists = NSPredicate(format: "isHidden == false")
        expectation(for: mockInformationLabelExists, evaluatedWith: mockInformationLabel, handler: nil)

        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertTrue(reachabilityBarViewControllerUnderTest.informationLabel.isHidden == statusBarIsHidden)
        XCTAssertTrue(reachabilityBarViewControllerUnderTest.twoStepButton.isHidden == twoStepButtonIsHidden)
    }
}
