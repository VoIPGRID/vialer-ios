//
//  TokenFromPasteBoard.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation

@objc class TokenFromPasteBoard: NSObject {

    @objc static func getToken() -> String? {
        guard let token = UIPasteboard.general.string else {
            return ""
        }
        // Is the token only digits.
        guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: token)) else {
            return ""
        }

        return token
    }
}
