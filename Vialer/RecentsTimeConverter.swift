//
//  RecentsTimeConverter.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import Foundation
/// This class deals with all the timezone conversions for the recents dates
/// Perhaps someday we could convert it to a category on NSDate
@objc class RecentsTimeConverter: NSObject {

    /// A ISO-8601 24h CET date formatter
    private static var dateFormatter24hCET: NSDateFormatter {
        let formatter = NSDateFormatter()

        // The ISO-8601 format
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // If the device is setup to use AM/PM, the line below will convert
        // this to 24h. In a 24h setup it does nothing.
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        formatter.timeZone = NSTimeZone(name: "CET")
        return formatter
    }

    private static var usersLocalShortStyleDateFormatter: NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone.localTimeZone()
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        return formatter
    }

    private static var usersLocalShortStyleTimeFormatter: NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone.localTimeZone()
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
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
    func dateFrom24hCET(timeString timeString:String) -> NSDate? {
        return RecentsTimeConverter.dateFormatter24hCET.dateFromString(timeString)
    }

    /**
     Retruns a string representing the given date formatted so the API can use in
     24h CET time ISO-8601.

     - parameter date: The NSDate to be formatted

     - returns: A API consumable string representing the given date in 24h CET
     */
    func apiFormatted24hCETstringFrom(date date:NSDate) -> String {
        return RecentsTimeConverter.dateFormatter24hCET.stringFromDate(date)
    }

    /**
     When the given date is past midnight a time is returned, hour, minutes
     When the given date is before midnight but not more than 1 day in the past
     a localized "yesterday" is returned.
     When the given date is further in the past, a date is returned, month, day, year

     - parameter date: The date of which you want a relative date string

     - returns: A time, "yesterday" or a date
     */
    func relativeDayTimeStringFrom(date date:NSDate) -> String {
        let now = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let startOfToday = calendar.startOfDayForDate(now)

        let deltaSeconds = startOfToday.timeIntervalSinceDate(date)
        let deltaDays:Int = Int(deltaSeconds / (60 * 60 * 24))

        if (deltaDays > 0 ) {
            // Return a short styled date
            return RecentsTimeConverter.usersLocalShortStyleDateFormatter.stringFromDate(date)
        } else if (deltaSeconds > 0) {
            return NSLocalizedString("yesterday", comment: "")
        } else {
            // Return a time
            return RecentsTimeConverter.usersLocalShortStyleTimeFormatter.stringFromDate(date)
        }
    }
}