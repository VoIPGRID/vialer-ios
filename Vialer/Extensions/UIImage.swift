//
//  UIImage.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation

extension UIImage {
    enum Asset: String {
        case logo = "logo"
        case tabKeypad = "tab-keypad"
        case tabKeypadActive = "tab-keypad-active"

        // Recents
        case tabRecent = "tab-recent"
        case tabRecentActive = "tab-recent-active"
    }

    convenience init(asset: Asset) {
        self.init(named: asset.rawValue)!
    }
}
