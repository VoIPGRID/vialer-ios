//
//  GAConfiguration.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation

class GAConfiguration: NSObject {

    fileprivate struct GA: Decodable {
        var buildIndex: UInt
        var clientIdIndex: UInt

        private enum CodingKeys: String, CodingKey {
            case buildIndex = "Build index"
            case clientIdIndex = "Client ID index"
        }
    }

    fileprivate struct Keys: Decodable {
        var GA: GA

        private enum CodingKeys: String, CodingKey {
            case GA = "GA Custom Dimensions"
        }
    }

    fileprivate struct GSKeys: Decodable {
        var trackingId: String

        private enum CodingKeys: String, CodingKey {
            case trackingId = "TRACKING_ID"
        }
    }

    static let shared = GAConfiguration()

    fileprivate let plistUrl: URL = Bundle.main.url(forResource: "Config", withExtension: "plist")!
    fileprivate var gaConfig: Keys?

    fileprivate let gsPlistUrl: URL = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist")!
    fileprivate var gsConfig: GSKeys?

    private override init() {
        do {
            let data = try Data(contentsOf: plistUrl)
            let decoder = PropertyListDecoder()
            gaConfig = try decoder.decode(Keys.self, from: data)
        } catch {
            print(error)
        }

        do {
            let data = try Data(contentsOf: gsPlistUrl)
            let decoder = PropertyListDecoder()
            gsConfig = try decoder.decode(GSKeys.self, from: data)
        } catch {
            print(error)
        }
    }

    func buildIndex() -> UInt {
        if gaConfig != nil {
            return gaConfig!.GA.buildIndex
        }
        return 0
    }

    func clientIndex() -> UInt {
        if gaConfig != nil {
            return gaConfig!.GA.clientIdIndex
        }
        return 0
    }

    func trackingId() -> String {
        if gsConfig != nil {
            return gsConfig!.trackingId
        }
        return ""
    }
}
