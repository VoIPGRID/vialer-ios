//
//  AppInfo.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import Foundation

/// Wrapper class that can retrieve information of the app.
@objc class AppInfo: NSObject {

    struct Constants {
        static let cfBundleShortVersionString: String = "CFBundleShortVersionString"
        static let cfBundleVersion: String = "CFBundleVersion"
        static let additionalVersionString: String = "Additional_Version_String"
        static let commitShortHash: String = "Commit_Short_Hash"
    }

    /**
     Get the current version number of the app.

     When in DEBUG mode, this function will return the latest commit hash.

     - returns: A string that tells the current version of the app.
     */
    @objc static func currentAppVersion() -> String? {
        guard let infoDict = Bundle.main.infoDictionary else {
            return nil
        }

        var version = "\(infoDict[AppInfo.Constants.cfBundleShortVersionString]!)"

        /// We sometimes use a tag the likes of 2.0.beta.03. Since Apple only wants numbers and dots as CFBundleShortVersionString
        /// the additional part of the tag is stored in de plist by the update_version_number script. If set, display it.
        if let additionalVersion = infoDict[AppInfo.Constants.additionalVersionString] as? String, !additionalVersion.isEmpty, additionalVersion != "Updated on build" {
            version = "\(version). \(additionalVersion)"
        }
        #if DEBUG
            if let commitNumber = infoDict[AppInfo.Constants.commitShortHash] {
                version = "Dev: \(version) (\(commitNumber))"
            }
        #else
            if let bundleVersion = infoDict[AppInfo.Constants.cfBundleVersion] {
                version = "\(version)"
            }
        #endif
        return version
    }

    static func currentAppStatus() -> String? {
        guard let infoDict = Bundle.main.infoDictionary else {
            return nil
        }

//        if let additionalVersion = infoDict[AppInfo.Constants.additionalVersionString] as? String, !additionalVersion.isEmpty {
//            return VialerStats.Status.beta
//        }

//        #if DEBUG
//        if let commitNumber = infoDict[AppInfo.Constants.commitShortHash] as? String, !commitNumber.isEmpty {
//            return VialerStats.Status.custom
//        }
//        #endif
//        return VialerStats.Status.production

        return "New"
    }
}
