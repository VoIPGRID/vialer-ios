//
//  LogEntriesConfiguration.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation

class LogEntriesConfiguration: NSObject {

    fileprivate struct LogEntries: Decodable {
        var mainKey: String
        var pushNotifications: String
        var partnerKey: String?

        private enum CodingKeys: String, CodingKey {
            case mainKey = "Main"
            case pushNotifications = "Push Notifications"
            case partnerKey = "Partner"
        }
    }

    fileprivate struct Keys: Decodable {
        var LogEntries: LogEntries

        private enum CodingKeys: String, CodingKey {
            case LogEntries = "Log Entries"
        }
    }

    @objc static let shared = LogEntriesConfiguration()

    fileprivate let plistUrl: URL = Bundle.main.url(forResource: "Config", withExtension: "plist")!
    fileprivate var logEntriesConfig: Keys?

    private override init() {
        do {
            let data = try Data(contentsOf: plistUrl)
            let decoder = PropertyListDecoder()
            logEntriesConfig = try decoder.decode(Keys.self, from: data)
        } catch {
            print(error)
        }
    }

    @objc func mainKey() -> String {
        if logEntriesConfig != nil {
            return logEntriesConfig!.LogEntries.mainKey
        }
        return ""
    }

    @objc func pushNotificationsKey() -> String {
        if logEntriesConfig != nil {
            return logEntriesConfig!.LogEntries.pushNotifications
        }
        return ""
    }

    @objc func partnerKey() -> String {
        if logEntriesConfig != nil {
            if logEntriesConfig!.LogEntries.partnerKey != nil {
                return logEntriesConfig!.LogEntries.partnerKey!
            }
            return ""
        }
        return ""
    }
}
