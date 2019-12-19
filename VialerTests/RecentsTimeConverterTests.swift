//
//  RecentsTimeConverterTests.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import XCTest

class RecentsTimeConverterTests: XCTestCase {

    var recentsTimeConverter = RecentsTimeConverter()
    var calendar = Calendar.current

    var usersLocalShortStyleDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateStyle = DateFormatter.Style.short
        return formatter
    }

    var usersLocalShortStyleTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.timeStyle = DateFormatter.Style.short
        return formatter
    }

    /**
     Passing a time one second AFTER midnight e.g. this day, the test verifies
     that the relative Day/Time string returned is a time (hh:mm)
     */
    func testRelativeDayTimeStringGivesTime() {
        // Given
        var components = dayMonthYearComponentsFromNow()

        components.second = 1
        let oneSecondAfterMidnightToday = calendar.date(from: components)

        // When
        let receivedRelativeDateString = recentsTimeConverter.relativeDayTimeStringFrom(date: oneSecondAfterMidnightToday!)

        // Then
        let expectedShortTimeString = usersLocalShortStyleTimeFormatter.string(from: oneSecondAfterMidnightToday!)
        XCTAssert(receivedRelativeDateString == expectedShortTimeString)
    }

    /**
     Passing a time one second BEFORE midnight e.g. yesterday, the test verifies
     that the relative Day/Time string returned is "yesterday"
     */
    func testRelativeDayTimeStringGivesYesterday() {
        // Given
        var components = dayMonthYearComponentsFromNow()

        components.second = -1
        let oneSecondBeforeMidnightYesterday = calendar.date(from: components)

        // When
        let expectedRelativeDateString = NSLocalizedString("yesterday", comment: "")

        // Then
        XCTAssert(recentsTimeConverter.relativeDayTimeStringFrom(date: oneSecondBeforeMidnightYesterday!) == expectedRelativeDateString)
    }

    /**
     Passing a time one second BEFORE midnight yesterday, so a time before yesterday
     the test verifies that the relative Day/Time string returned is a date (dd:MM)
     */
    func testRelativeDayTimeStringGivesDateInPast() {
        // Given
        var components = dayMonthYearComponentsFromNow()

        components.second = -1
        components.day = components.day!-1

        // When
        let oneSecondBeforeMidnightOnTheDayBeforeYesterday = calendar.date(from: components)

        // Then
        let expectedShortDateString = usersLocalShortStyleDateFormatter.string(from: oneSecondBeforeMidnightOnTheDayBeforeYesterday!)
         XCTAssert(recentsTimeConverter.relativeDayTimeStringFrom(date: oneSecondBeforeMidnightOnTheDayBeforeYesterday!) == expectedShortDateString)
    }

    // MARK: Helper functions
    func dayMonthYearComponentsFromNow() -> DateComponents {
        let date = Date()
        let unitFlags: NSCalendar.Unit = [.day, .month, .year]
        return (calendar as NSCalendar).components(unitFlags, from: date)
    }
}
