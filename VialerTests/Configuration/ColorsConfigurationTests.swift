//
//  ColorsConfigurationTests.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import XCTest
@testable import Vialer

class ColorsConfgirationTests: XCTestCase {

    func testGradientColorsFromDict() {
        let sR: Double = 255 / 255
        let sG: Double = 141 / 255
        let sB: Double  = 7 / 255

        let expectedStartColor = UIColor(red: CGFloat(sR), green: CGFloat(sG), blue: CGFloat(sB), alpha: 1)
        let startColor = ColorsConfiguration.shared.gradientColors(.start)

        XCTAssertTrue(expectedStartColor.isEqualTo(startColor))

        let eR: Double = 255 / 255
        let eG: Double = 116 / 255
        let eB: Double = 47 / 255

        let expectedEndColor = UIColor(red: CGFloat(eR), green: CGFloat(eG), blue: CGFloat(eB), alpha: 1)
        let endColor = ColorsConfiguration.shared.gradientColors(.end)

        XCTAssertTrue(expectedEndColor.isEqualTo(endColor))
    }
}
