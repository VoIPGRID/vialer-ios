//
// VialerLogger.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation


/// Log a message to VialerLogger.
///
/// Simple wrapper around Objective C Logger.
///
/// - Parameters:
///   - flag: LogLevel
///   - file: File that dispatched the message
///   - function: Function that dispatched the message
///   - line: Line that dispatched the message
///   - message: Message that will be logged
func VialerLog(flag: DDLogFlag, file: String, function: String, line: UInt, _ message: String) {
    VialerLogger.log(flag: flag, file: file, function: function, line: line, format: message, arguments: nil)
}

/// Verbose logging
///
/// - Parameters:
///   - file: (optional)File that dispatched the message
///   - function: (optional)Function that dispatched the message
///   - line: (optional)Line that dispatched the message
///   - message: Message that will be logged
func VialerLogVerbose(file: String = #file, function: String = #function, line: UInt = #line, _ message: String) {
    VialerLog(flag: .verbose, file: file, function: function, line: line, message)
}

/// Debug logging
///
/// - Parameters:
///   - file: (optional)File that dispatched the message
///   - function: (optional)Function that dispatched the message
///   - line: (optional)Line that dispatched the message
///   - message: Message that will be logged
func VialerLogDebug(file: String = #file, function: String = #function, line: UInt = #line, _ message: String) {
    VialerLog(flag: .debug, file: file, function: function, line: line, message)
}

/// Info logging
///
/// - Parameters:
///   - file: (optional)File that dispatched the message
///   - function: (optional)Function that dispatched the message
///   - line: (optional)Line that dispatched the message
///   - message: Message that will be logged
func VialerLogInfo(file: String = #file, function: String = #function, line: UInt = #line, _ message: String) {
    VialerLog(flag: .info, file: file, function: function, line: line, message)
}

/// Waring logging
///
/// - Parameters:
///   - file: (optional)File that dispatched the message
///   - function: (optional)Function that dispatched the message
///   - line: (optional)Line that dispatched the message
///   - message: Message that will be logged
func VialerLogWarning(file: String = #file, function: String = #function, line: UInt = #line, _ message: String) {
    VialerLog(flag: .warning, file: file, function: function, line: line, message)
}

/// Error logging
///
/// - Parameters:
///   - file: (optional)File that dispatched the message
///   - function: (optional)Function that dispatched the message
///   - line: (optional)Line that dispatched the message
///   - message: Message that will be logged
func VialerLogError(file: String = #file, function: String = #function, line: UInt = #line, _ message: String) {
    VialerLog(flag: .error, file: file, function: function, line: line, message)
}
