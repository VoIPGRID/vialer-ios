//
//  RecentsTimeConverter.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import Foundation
/// This class deals with all the timezone conversions for the recents dates
/// Perhaps someday we could convert it to a category on NSDate
@objc class RecentsTimeConverter: NSObject {

    /// A ISO-8601 24h CET date formatter
    fileprivate static var dateFormatter24hCET: DateFormatter {
        let formatter = DateFormatter()

        // The ISO-8601 format
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // If the device is setup to use AM/PM, the line below will convert
        // this to 24h. In a 24h setup it does nothing.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "CET")
        return formatter
    }

    fileprivate static var usersLocalShortStyleDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateStyle = DateFormatter.Style.short
        return formatter
    }

    fileprivate static var usersLocalShortStyleTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.timeStyle = DateFormatter.Style.short
        return formatter
    }

    /**
     The date stated in the JSON received from the recents API
     contains dates in 24h format using the CET timezone.

     This function takes such a date String and converts it into a NSDate.

     - parameter timeString: The date string as returned by the recents API
     in 24h CET with format: yyyy-MM-dd'T'HH:mm:ss

     - Returns: A NSDate or nil if the date could not be parsed
     */
    func dateFrom24hCET(timeString:String) -> Date? {
        return RecentsTimeConverter.dateFormatter24hCET.date(from: timeString)
    }

    /**
     Retruns a string representing the given date formatted so the API can use in
     24h CET time ISO-8601.

     - parameter date: The NSDate to be formatted

     - returns: A API consumable string representing the given date in 24h CET
     */
    func apiFormatted24hCETstringFrom(date:Date) -> String {
        return RecentsTimeConverter.dateFormatter24hCET.string(from: date)
    }

    /**
     When the given date is past midnight a time is returned, hour, minutes
     When the given date is before midnight but not more than 1 day in the past
     a localized "yesterday" is returned.
     When the given date is further in the past, a date is returned, month, day, year

     - parameter date: The date of which you want a relative date string

     - returns: A time, "yesterday" or a date
     */
    func relativeDayTimeStringFrom(date:Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)

        let deltaSeconds = startOfToday.timeIntervalSince(date)
        let deltaDays:Int = Int(deltaSeconds / (60 * 60 * 24))

        if (deltaDays > 0 ) {
            // Return a short styled date
            return RecentsTimeConverter.usersLocalShortStyleDateFormatter.string(from: date)
        } else if (deltaSeconds > 0) {
            return NSLocalizedString("yesterday", comment: "")
        } else {
            // Return a time
            return RecentsTimeConverter.usersLocalShortStyleTimeFormatter.string(from: date)
        }
    }
}
