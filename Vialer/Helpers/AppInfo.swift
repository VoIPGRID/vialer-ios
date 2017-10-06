//
//  AppInfo.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import Foundation

/// Wrapper class that can retrieve information of the app.
@objc class AppInfo: NSObject {

    /**
     Get the current version number of the app.

     When in DEBUG mode, this function will return the latest commit hash.

     - returns: A string that tells the current version of the app.
     */
    @objc static func currentAppVersion() -> String? {
        guard let infoDict = Bundle.main.infoDictionary else {
            return nil
        }

        var version = "\(infoDict["CFBundleShortVersionString"]!)"

        /// We sometimes use a tag the likes of 2.0.beta.03. Since Apple only wants numbers and dots as CFBundleShortVersionString
        /// the additional part of the tag is stored in de plist by the update_version_number script. If set, display it.
        if let additionalVersion = infoDict["Additional_Version_String"] as? String, !additionalVersion.isEmpty {
            version = "\(version).\(additionalVersion)"
        }
        #if DEBUG
            if let commitNumber = infoDict["Commit_Short_Hash"] {
                version = "Commit: \(commitNumber)"
            }
        #else
            if let bundleVersion = infoDict["CFBundleVersion"] {
                version = "\(version) (\(bundleVersion))"
            }
        #endif
        return version
    }
}
