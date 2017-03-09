//
//  UIImage.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation

extension UIImage {
    enum Asset: String {
        case logo = "logo"

        // Calling
        case tabKeypad = "tab-keypad"
        case tabKeypadActive = "tab-keypad-active"
        case successfullTransfer = "successfullTransfer"
        case rejectedTransfer = "rejectedTransfer"

        // Recents
        case tabRecent = "tab-recent"
        case tabRecentActive = "tab-recent-active"
    }

    convenience init(asset: Asset) {
        self.init(named: asset.rawValue)!
    }
}
