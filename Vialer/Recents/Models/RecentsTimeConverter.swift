//
//  RecentsTimeConverter.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import Foundation

func configureDateForamtter(with format:String) -> DateFormatter {
    let formatter = DateFormatter()

    // If the device is setup to use AM/PM, the line below will convert
    // this to 24h. In a 24h setup it does nothing.
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "CET")
    formatter.dateFormat = format

    return formatter
}

// This class deals with all the timezone conversions for the recents dates.
@objc class RecentsTimeConverter: NSObject {

    private static var usersLocalShortStyleDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateStyle = DateFormatter.Style.short
        return formatter
    }

    private static var usersLocalShortStyleTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.timeStyle = DateFormatter.Style.short
        return formatter
    }

    /**
     When the given date is past midnight a time is returned, hour, minutes
     When the given date is before midnight but not more than 1 day in the past
     a localized "yesterday" is returned.
     When the given date is further in the past, a date is returned, month, day, year

     - parameter date: The date of which you want a relative date string
     - returns: A time, "yesterday" or a date
     */
    @objc func relativeDayTimeStringFrom(date:Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)

        let deltaSeconds = startOfToday.timeIntervalSince(date)
        let deltaDays:Int = Int(deltaSeconds / (60 * 60 * 24))

        if (deltaDays > 0 ) {
            // Return a short styled date.
            return RecentsTimeConverter.usersLocalShortStyleDateFormatter.string(from: date)
        } else if (deltaSeconds > 0) {
            return NSLocalizedString("yesterday", comment: "")
        } else {
            // Return a time.
            return RecentsTimeConverter.usersLocalShortStyleTimeFormatter.string(from: date)
        }
    }
}

extension DateFormatter {
    // Date formatter that can translate API dates with or without fractional seconds returned by VG back and forth.
    // VG returns dates in ISO-8601 UTC extended format. The provided format is without the time zone designator Z.
    static var VGDateFormat: DateFormatter {
        return configureDateForamtter(with: "yyyy-MM-dd'T'HH:mm:ss")
    }

    static let VGDateFormatWithFractionalSeconds: DateFormatter = {
        return configureDateForamtter(with: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS")
    }()
}

extension String {
    // Create a Date object from a string returned by the VG API, it could includes fractional seconds.
    var date: Date? {
        return DateFormatter.VGDateFormat.date(from: self) ?? DateFormatter.VGDateFormatWithFractionalSeconds.date(from: self)
    }
}

extension Date {
    // Create a string from a date, formatted for the API.
    var VGDateFormat: String {
        return DateFormatter.VGDateFormat.string(from: self)
    }
}
