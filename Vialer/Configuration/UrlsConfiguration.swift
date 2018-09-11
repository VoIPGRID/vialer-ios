//
//  UrlsConfiguration.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation

@objc class UrlsConfiguration: NSObject {

    fileprivate struct URLS: Decodable {
        var encryptedSipDomain: String
        var sipDomain: String
        var middlewareBaseUrl: String
        var api: String
        var partner: String
        var onboardingNL: String
        var onboardingEN: String
        var stunServers: [String]

        private enum CodingKeys: String, CodingKey {
            case stunServers = "Stun Servers"
            case encryptedSipDomain = "Encrypted SIP Domain"
            case middlewareBaseUrl = "Middleware BaseLink"
            case sipDomain = "SIP domain"
            case api = "API"
            case partner = "Partner"
            case onboardingNL = "onboarding-nl"
            case onboardingEN = "onboarding-en"
        }
    }

    fileprivate struct Keys: Decodable {
        var URLS: URLS
    }

    @objc enum OnboardingLanguage: Int {
        case en, nl
    }

    @objc static let shared = UrlsConfiguration()

    fileprivate var plistUrl: URL = Bundle.main.url(forResource: "Config", withExtension: "plist")!
    fileprivate var urlsConfig: Keys?

    private override init() {
        do {
            let data = try Data(contentsOf: plistUrl)
            let decoder = PropertyListDecoder()
            urlsConfig = try decoder.decode(Keys.self, from: data)
        } catch {
            print(error)
            assertionFailure("Config.plist file not found!")
        }
    }

    @objc func apiUrl() -> String {
        if urlsConfig != nil {
            return urlsConfig!.URLS.api
        }
        return ""
    }

    @objc func encryptedSipDomain() -> String {
        if urlsConfig != nil {
            return urlsConfig!.URLS.encryptedSipDomain
        }
        return ""
    }

    @objc func sipDomain() -> String {
        if urlsConfig != nil {
            return urlsConfig!.URLS.sipDomain
        }
        return ""
    }

    @objc func onboardingUrl(language: OnboardingLanguage = .nl) -> String {
        if urlsConfig != nil {
            if language == .nl {
                return urlsConfig!.URLS.onboardingNL
            }
            return urlsConfig!.URLS.onboardingEN
        }
        return ""
    }

    @objc func middlewareBaseUrl() -> String {
        if urlsConfig != nil {
            return urlsConfig!.URLS.middlewareBaseUrl
        }
        return ""
    }

    @objc func partnerUrl() -> String {
        guard urlsConfig != nil else {
            VialerLogError("Can't get partner url because the config is missing")
            return ""
        }
        return urlsConfig!.URLS.partner
    }

    @objc func stunServers() -> [String] {
        if urlsConfig != nil {
            return urlsConfig!.URLS.stunServers
        }
        return []
    }
}
